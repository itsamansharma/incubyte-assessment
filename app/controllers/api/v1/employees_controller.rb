module Api
  module V1
    class EmployeesController < ApplicationController
      DEFAULT_PAGE_SIZE = 25
      MAX_PAGE_SIZE = 100
      SORT_COLUMNS = {
        "name" => %w[employees.last_name employees.first_name],
        "employee_code" => [ "employees.employee_code" ],
        "country_code" => [ "employees.country_code" ],
        "department" => [ "departments.name" ],
        "salary" => [ "compensations.amount_usd_cents" ],
        "date_of_joining" => [ "employees.date_of_joining" ]
      }.freeze

      def index
        page = positive_integer_param(:page, default: 1)
        page_size = positive_integer_param(:per_page, default: DEFAULT_PAGE_SIZE, maximum: MAX_PAGE_SIZE)
        filters = employee_filters
        relation = apply_filters(base_relation, filters)
        total_count = relation.count(:id)
        employees = relation
          .order(order_clause(filters.fetch(:sort), filters.fetch(:direction)))
          .offset((page - 1) * page_size)
          .limit(page_size)
          .pluck(
            Arel.sql("employees.id"),
            Arel.sql("employees.employee_code"),
            Arel.sql("employees.first_name"),
            Arel.sql("employees.last_name"),
            Arel.sql("employees.email"),
            Arel.sql("employees.country_code"),
            Arel.sql("departments.name"),
            Arel.sql("employees.job_title"),
            Arel.sql("employees.job_level"),
            Arel.sql("employees.date_of_joining"),
            Arel.sql("compensations.amount_cents"),
            Arel.sql("compensations.currency"),
            Arel.sql("compensations.amount_usd_cents"),
            Arel.sql("compensations.effective_date")
          )

        render json: {
          employees: employees.map { |employee| serialize_employee(employee) },
          pagination: {
            page: page,
            per_page: page_size,
            total_count: total_count,
            total_pages: (total_count.to_f / page_size).ceil
          }
        }
      rescue ActionController::BadRequest => error
        render json: { error: error.message }, status: :bad_request
      end

      def show
        employee = if params[:id].to_s.match?(/\A\d+\z/)
          Employee.includes(:department, :active_compensation, :compensations).find_by(id: params[:id])
        end

        return render json: { error: "Employee not found" }, status: :not_found unless employee

        render json: {
          id: employee.id,
          employee_code: employee.employee_code,
          first_name: employee.first_name,
          last_name: employee.last_name,
          email: employee.email,
          country_code: employee.country_code,
          department: {
            name: employee.department.name,
            code: employee.department.code
          },
          job_title: employee.job_title,
          job_level: employee.job_level,
          date_of_joining: employee.date_of_joining,
          current_compensation: CompensationSerializer.as_json(employee.active_compensation),
          compensation_history: employee.compensations
            .sort_by { |compensation| [ compensation.effective_date, compensation.created_at, compensation.id ] }
            .reverse
            .map { |compensation| CompensationSerializer.as_json(compensation) }
        }
      end

      private

      def base_relation
        Employee.joins(:department).left_joins(:active_compensation)
      end

      def employee_filters
        country_code = params[:country_code].to_s.upcase.presence
        if country_code && !country_code.match?(/\A[A-Z]{2}\z/)
          raise ActionController::BadRequest, "country_code must be a two-letter code"
        end

        currency = params[:currency].to_s.upcase.presence
        if currency && !currency.match?(/\A[A-Z]{3}\z/)
          raise ActionController::BadRequest, "currency must be a three-letter code"
        end

        search = params[:q].to_s.strip.presence
        if search && search.length > 100
          raise ActionController::BadRequest, "q must be 100 characters or fewer"
        end

        sort = params.fetch(:sort, "name").to_s
        unless SORT_COLUMNS.key?(sort)
          raise ActionController::BadRequest, "sort must be one of: #{SORT_COLUMNS.keys.join(', ')}"
        end

        direction = params.fetch(:direction, "asc").to_s.downcase
        unless %w[asc desc].include?(direction)
          raise ActionController::BadRequest, "direction must be asc or desc"
        end

        minimum_salary = nonnegative_integer_param(:min_salary_usd_cents)
        maximum_salary = nonnegative_integer_param(:max_salary_usd_cents)
        if minimum_salary && maximum_salary && minimum_salary > maximum_salary
          raise ActionController::BadRequest, "minimum salary cannot exceed maximum salary"
        end

        {
          country_code: country_code,
          department: params[:department].to_s.strip.presence,
          currency: currency,
          search: search,
          sort: sort,
          direction: direction,
          minimum_salary: minimum_salary,
          maximum_salary: maximum_salary
        }
      end

      def apply_filters(relation, filters)
        relation = relation.where(country_code: filters[:country_code]) if filters[:country_code]

        if filters[:department]
          relation = relation.where(
            "LOWER(departments.name) = LOWER(:department) OR LOWER(departments.code) = LOWER(:department)",
            department: filters[:department]
          )
        end

        if filters[:currency]
          relation = relation.where(compensations: { currency: filters[:currency] })
        end

        if filters[:minimum_salary]
          relation = relation.where("compensations.amount_usd_cents >= ?", filters[:minimum_salary])
        end
        if filters[:maximum_salary]
          relation = relation.where("compensations.amount_usd_cents <= ?", filters[:maximum_salary])
        end

        if filters[:search]
          query = "%#{Employee.sanitize_sql_like(filters[:search])}%"
          relation = relation.where(
            "employees.employee_code ILIKE :query OR employees.first_name ILIKE :query OR employees.last_name ILIKE :query OR concat_ws(' ', employees.first_name, employees.last_name) ILIKE :query OR employees.email ILIKE :query",
            query: query
          )
        end

        relation
      end

      def order_clause(sort, direction)
        columns = SORT_COLUMNS.fetch(sort)
        direction_sql = direction.upcase
        order_sql = columns.map { |column| "#{column} #{direction_sql}" }
        order_sql = [ "compensations.amount_usd_cents #{direction_sql} NULLS LAST" ] if sort == "salary"
        order_sql << "employees.employee_code ASC"
        Arel.sql(order_sql.join(", "))
      end

      def positive_integer_param(name, default:, maximum: nil)
        raw_value = params[name].presence
        return default unless raw_value

        value = parse_integer(raw_value, name)
        raise ActionController::BadRequest, "#{name} must be greater than zero" unless value.positive?

        maximum ? [ value, maximum ].min : value
      end

      def nonnegative_integer_param(name)
        raw_value = params[name].presence
        return unless raw_value

        value = parse_integer(raw_value, name)
        raise ActionController::BadRequest, "#{name} cannot be negative" if value.negative?

        value
      end

      def parse_integer(value, name)
        string_value = value.to_s
        unless string_value.match?(/\A-?\d+\z/)
          raise ActionController::BadRequest, "#{name} must be an integer"
        end

        string_value.to_i
      end

      def serialize_employee(employee)
        id, employee_code, first_name, last_name, email, country_code, department,
          job_title, job_level, date_of_joining, amount_cents, currency, amount_usd_cents,
          effective_date = employee

        {
          id: id,
          employee_code: employee_code,
          first_name: first_name,
          last_name: last_name,
          email: email,
          country_code: country_code,
          department: department,
          job_title: job_title,
          job_level: job_level,
          date_of_joining: date_of_joining,
          compensation: if currency
            {
              amount_cents: amount_cents,
              currency: currency,
              amount_usd_cents: amount_usd_cents,
              effective_date: effective_date
            }
                        end
        }
      end
    end
  end
end
