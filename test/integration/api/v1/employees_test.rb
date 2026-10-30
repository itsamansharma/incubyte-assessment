require "test_helper"

module Api
  module V1
    class EmployeesTest < ActionDispatch::IntegrationTest
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
      end

      test "show returns not found for an unknown employee" do
        get "/api/v1/employees/999999"

        assert_response :not_found
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

      test "invalid salary change leaves compensation history unchanged" do
        assert_no_difference -> { @employee.compensations.count } do
          post "/api/v1/employees/#{@employee.id}/compensations",
            params: {
              compensation: {
                amount_cents: 100,
                currency: "XYZ",
                effective_date: "2025-06-01",
                change_reason: "Unsupported currency"
              }
            },
            as: :json
        end

        assert_response :unprocessable_entity
        assert @active_compensation.reload.is_active?
      end

      test "index rejects invalid pagination" do
        get "/api/v1/employees", params: { page: 0 }

        assert_response :bad_request
      end

      private

      def create_employee(code, department:, country_code:)
        Employee.create!(
          employee_code: code,
          first_name: "Test",
          last_name: code,
          email: "#{code.downcase}@example.test",
          country_code: country_code,
          department: department,
          job_title: "Senior Engineer",
          job_level: "Senior",
          date_of_joining: Date.new(2020, 1, 1)
        )
      end

      def create_compensation(employee, amount_cents:, currency:, amount_usd_cents:, effective_date: Date.new(2020, 1, 1), is_active: true, change_reason: "Initial Hire")
        Compensation.create!(
          employee: employee,
          amount_cents: amount_cents,
          currency: currency,
          amount_usd_cents: amount_usd_cents,
          effective_date: effective_date,
          is_active: is_active,
          change_reason: change_reason
        )
      end
    end
  end
end
