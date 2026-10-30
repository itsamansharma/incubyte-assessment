require "test_helper"

module Api
  module V1
    class EmployeesTest < ActionDispatch::IntegrationTest
      include PayrollTestData

      setup do
        @engineering = Department.create!(name: "Engineering", code: "ENG")
        @product = Department.create!(name: "Product", code: "PRD")
        ExchangeRate.create!(currency_code: "USD", rate_to_usd: 1)
        ExchangeRate.create!(currency_code: "INR", rate_to_usd: 0.012)
        @employee = create_employee("ACM-00001", department: @engineering, country_code: "IN")
        @active_compensation = create_compensation(
          @employee,
          amount_cents: 100_000_000,
          currency: "INR",
          amount_usd_cents: 1_200_000
        )
      end

      test "index paginates and filters employees" do
        another_employee = create_employee("ACM-00002", department: @engineering, country_code: "IN")
        create_compensation(
          another_employee,
          amount_cents: 90_000_000,
          currency: "INR",
          amount_usd_cents: 1_080_000
        )
        product_employee = create_employee("ACM-00003", department: @product, country_code: "US")
        create_compensation(product_employee, amount_cents: 300_000, currency: "USD", amount_usd_cents: 300_000)

        get "/api/v1/employees", params: {
          q: "ACM-00001",
          country_code: "in",
          department: "ENG",
          currency: "inr",
          min_salary_usd_cents: 1_000_000,
          max_salary_usd_cents: 1_300_000,
          sort: "salary",
          direction: "desc",
          per_page: 1
        }

        assert_response :success
        body = response.parsed_body
        assert_equal 1, body.fetch("pagination").fetch("total_count")
        assert_equal "ACM-00001", body.fetch("employees").sole.fetch("employee_code")
        assert_equal "INR", body.fetch("employees").sole.dig("compensation", "currency")
      end

      test "index uses the default pagination settings" do
        get "/api/v1/employees"

        assert_response :success
        body = response.parsed_body
        assert_equal 25, body.fetch("pagination").fetch("per_page")
        assert_equal 1, body.fetch("pagination").fetch("page")
        assert_equal 1, body.fetch("pagination").fetch("total_count")
        assert_equal 1, body.fetch("pagination").fetch("total_pages")
      end

      test "index returns the requested page" do
        second_employee = create_employee("ACM-00002", department: @engineering)
        create_compensation(second_employee, amount_cents: 200_000)

        get "/api/v1/employees", params: { page: 2, per_page: 1 }

        assert_response :success
        body = response.parsed_body
        assert_equal 2, body.dig("pagination", "page")
        assert_equal 2, body.dig("pagination", "total_pages")
        assert_equal "ACM-00002", body.fetch("employees").sole.fetch("employee_code")
      end

      test "index caps page size at the maximum" do
        get "/api/v1/employees", params: { per_page: 101 }

        assert_response :success
        assert_equal 100, response.parsed_body.dig("pagination", "per_page")
      end

      test "index searches employee code, name, and email without treating wildcards as patterns" do
        Employee.update!(@employee.id, first_name: "Priya", last_name: "Sharma", email: "priya.sharma@example.test")

        { "ACM-00001" => "ACM-00001", "PRIYA" => "ACM-00001", "sharma@example" => "ACM-00001" }.each do |query, expected_code|
          get "/api/v1/employees", params: { q: query }

          assert_response :success
          assert_equal [ expected_code ], response.parsed_body.fetch("employees").map { |row| row.fetch("employee_code") }
        end

        get "/api/v1/employees", params: { q: "%" }

        assert_response :success
        assert_empty response.parsed_body.fetch("employees")
      end

      test "index accepts department names and codes" do
        product_employee = create_employee("ACM-00002", department: @product)
        create_compensation(product_employee, amount_cents: 200_000, amount_usd_cents: 200_000)

        [ "Product", "PRD" ].each do |department|
          get "/api/v1/employees", params: { department: department }

          assert_response :success
          assert_equal [ "ACM-00002" ], response.parsed_body.fetch("employees").map { |row| row.fetch("employee_code") }
        end
      end

      test "index supports every documented sort column and direction" do
        alpha = create_employee(
          "ACM-00002", department: @product, country_code: "US", first_name: "Amy", last_name: "Adams",
          date_of_joining: Date.new(2019, 1, 1)
        )
        create_compensation(alpha, amount_cents: 200_000, amount_usd_cents: 200_000)
        zeta = create_employee(
          "ACM-00003", department: @engineering, country_code: "GB", first_name: "Zoe", last_name: "Zephyr",
          date_of_joining: Date.new(2022, 1, 1)
        )

        sort_cases = {
          [ "name", "asc" ] => %w[ACM-00001 ACM-00002 ACM-00003],
          [ "employee_code", "desc" ] => %w[ACM-00003 ACM-00002 ACM-00001],
          [ "country_code", "desc" ] => %w[ACM-00002 ACM-00001 ACM-00003],
          [ "department", "asc" ] => %w[ACM-00001 ACM-00003 ACM-00002],
          [ "salary", "desc" ] => %w[ACM-00001 ACM-00002 ACM-00003],
          [ "date_of_joining", "asc" ] => %w[ACM-00002 ACM-00001 ACM-00003]
        }

        sort_cases.each do |(sort, direction), expected_codes|
          get "/api/v1/employees", params: { sort: sort, direction: direction }

          assert_response :success
          assert_equal expected_codes, response.parsed_body.fetch("employees").map { |row| row.fetch("employee_code") },
                       "unexpected ordering for #{sort} #{direction}"
        end
        assert_nil zeta.active_compensation
      end

      test "index returns empty results and zero pages when filters match no employees" do
        get "/api/v1/employees", params: { country_code: "DE" }

        assert_response :success
        assert_empty response.parsed_body.fetch("employees")
        assert_equal 0, response.parsed_body.dig("pagination", "total_count")
        assert_equal 0, response.parsed_body.dig("pagination", "total_pages")
      end

      test "index rejects malformed filters and pagination values" do
        invalid_params = [
          [ { page: "abc" }, "page must be an integer" ],
          [ { page: -1 }, "page must be greater than zero" ],
          [ { per_page: 0 }, "per_page must be greater than zero" ],
          [ { per_page: -1 }, "per_page must be greater than zero" ],
          [ { per_page: "1.5" }, "per_page must be an integer" ],
          [ { country_code: "USA" }, "country_code must be a two-letter code" ],
          [ { currency: "US" }, "currency must be a three-letter code" ],
          [ { q: "x" * 101 }, "q must be 100 characters or fewer" ],
          [ { sort: "unknown" }, "sort must be one of" ],
          [ { direction: "sideways" }, "direction must be asc or desc" ],
          [ { min_salary_usd_cents: "-1" }, "min_salary_usd_cents cannot be negative" ],
          [ { max_salary_usd_cents: -1 }, "max_salary_usd_cents cannot be negative" ],
          [ { min_salary_usd_cents: 300, max_salary_usd_cents: 200 }, "minimum salary cannot exceed maximum salary" ]
        ]

        invalid_params.each do |params, message|
          get "/api/v1/employees", params: params

          assert_response :bad_request
          assert_includes response.parsed_body.fetch("error"), message
        end
      end

      test "show returns current compensation and ordered salary history" do
        previous = create_compensation(
          @employee,
          amount_cents: 80_000_000,
          currency: "INR",
          amount_usd_cents: 960_000,
          effective_date: Date.new(2019, 1, 1),
          is_active: false,
          change_reason: "Initial Hire"
        )

        get "/api/v1/employees/#{@employee.id}"

        assert_response :success
        body = response.parsed_body
        assert_equal @active_compensation.id, body.dig("current_compensation", "id")
        assert_equal [ @active_compensation.id, previous.id ], body.fetch("compensation_history").map { |row| row.fetch("id") }
        assert_equal "Initial Hire", body.fetch("compensation_history").first.fetch("change_reason")
        assert_equal true, body.fetch("current_compensation").fetch("is_active")
      end

      test "show returns not found for an unknown employee" do
        get "/api/v1/employees/999999"

        assert_response :not_found
      end

      test "show returns not found for a malformed employee id" do
        get "/api/v1/employees/not-a-number"

        assert_response :not_found
      end

      test "show returns an empty history and no current compensation when salary is missing" do
        @active_compensation.destroy!

        get "/api/v1/employees/#{@employee.id}"

        assert_response :success
        assert_nil response.parsed_body.fetch("current_compensation")
        assert_empty response.parsed_body.fetch("compensation_history")
      end

      test "salary change converts currency and preserves prior compensation" do
        post "/api/v1/employees/#{@employee.id}/compensations",
          params: {
            compensation: {
              amount_cents: 120_000_000,
              currency: "INR",
              effective_date: "2025-06-01",
              change_reason: "Promotion"
            }
          },
          as: :json

        assert_response :created
        new_compensation = response.parsed_body.fetch("compensation")
        assert_equal 1_440_000, new_compensation.fetch("amount_usd_cents")
        assert_equal "Promotion", new_compensation.fetch("change_reason")
        assert_not @active_compensation.reload.is_active?
        assert_equal 1, @employee.compensations.where(is_active: true).count
      end

      test "salary change normalizes currency codes and rounds half cents up" do
        ExchangeRate.create!(currency_code: "GBP", rate_to_usd: "0.5")

        post_compensation(
          amount_cents: 1,
          currency: "gbp",
          effective_date: "2025-06-01",
          change_reason: "Currency conversion"
        )

        assert_response :created
        body = response.parsed_body.fetch("compensation")
        assert_equal "GBP", body.fetch("currency")
        assert_equal 1, body.fetch("amount_usd_cents")
      end

      test "salary change rejects a missing compensation object" do
        assert_no_difference -> { @employee.compensations.count } do
          post "/api/v1/employees/#{@employee.id}/compensations", params: {}, as: :json
        end

        assert_response :unprocessable_entity
        assert_includes response.parsed_body.fetch("error"), "param is missing or the value is empty"
        assert @active_compensation.reload.is_active?
      end

      test "salary change rejects unknown and malformed employee ids" do
        [ "999999", "not-a-number" ].each do |employee_id|
          post "/api/v1/employees/#{employee_id}/compensations",
               params: { compensation: valid_compensation_attributes }, as: :json

          assert_response :not_found
          assert_equal "Employee not found", response.parsed_body.fetch("error")
        end
      end

      test "invalid salary changes return validation errors without changing history" do
        ExchangeRate.create!(currency_code: "GBP", rate_to_usd: "1.27")
        invalid_inputs = [
          [ "missing amount", { amount_cents: nil }, "amount_cents must be a non-negative integer" ],
          [ "fractional amount", { amount_cents: "1.5" }, "amount_cents must be a non-negative integer" ],
          [ "negative amount", { amount_cents: -1 }, "amount_cents must be a non-negative integer" ],
          [ "amount above bigint range", { amount_cents: "9223372036854775808" }, "salary exceeds the supported amount" ],
          [ "converted amount above bigint range", { amount_cents: "9223372036854775807", currency: "GBP" }, "salary exceeds the supported amount" ],
          [ "missing currency", { currency: "" }, "currency must be a three-letter code" ],
          [ "malformed currency", { currency: "US" }, "currency must be a three-letter code" ],
          [ "unsupported currency", { currency: "XYZ" }, "unsupported currency" ],
          [ "invalid calendar date", { effective_date: "2025-02-30" }, "effective_date must use YYYY-MM-DD format" ],
          [ "missing date", { effective_date: "" }, "effective_date must use YYYY-MM-DD format" ],
          [ "blank reason", { change_reason: "  " }, "change_reason must be between 1 and 100 characters" ],
          [ "reason above length limit", { change_reason: "x" * 101 }, "change_reason must be between 1 and 100 characters" ]
        ]

        invalid_inputs.each do |label, overrides, expected_error|
          attributes = valid_compensation_attributes.merge(overrides)
          assert_no_difference -> { @employee.compensations.count }, label do
            post_compensation(attributes)
          end

          assert_response :unprocessable_entity, label
          assert_includes response.parsed_body.fetch("error"), expected_error, label
          assert @active_compensation.reload.is_active?, label
        end
      end

      private

      def valid_compensation_attributes
        {
          amount_cents: 120_000_000,
          currency: "INR",
          effective_date: "2025-06-01",
          change_reason: "Promotion"
        }
      end

      def post_compensation(attributes)
        post "/api/v1/employees/#{@employee.id}/compensations",
             params: { compensation: attributes }, as: :json
      end
    end
  end
end
