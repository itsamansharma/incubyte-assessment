require "test_helper"

module Api
  module V1
    class DashboardTest < ActionDispatch::IntegrationTest
      setup do
        @engineering = Department.create!(name: "Engineering", code: "ENG")
        @usd_rate = ExchangeRate.create!(currency_code: "USD", rate_to_usd: 1)
        @first_employee = create_employee("ACM-00001", department: @engineering)
        @second_employee = create_employee("ACM-00002", department: @engineering)
        create_compensation(@first_employee, amount_cents: 100_000)
        create_compensation(@second_employee, amount_cents: 300_000)
      end

      test "overview returns headcount and USD salary metrics" do
        get "/api/v1/dashboard/overview"

        assert_response :success
        assert_equal 2, response.parsed_body.fetch("headcount")
        assert_equal 400_000, response.parsed_body.fetch("annual_payroll_usd_cents")
        assert_equal 200_000, response.parsed_body.fetch("average_annual_salary_usd_cents")
        assert_equal 200_000, response.parsed_body.fetch("median_annual_salary_usd_cents")
      end

      test "breakdown groups salary metrics by department and country" do
        get "/api/v1/dashboard/breakdown"

        assert_response :success
        body = response.parsed_body
        assert_equal 2, body.fetch("departments").sole.fetch("headcount")
        assert_equal "Engineering", body.fetch("departments").sole.fetch("department")
        assert_equal 2, body.fetch("countries").sole.fetch("headcount")
        assert_equal "US", body.fetch("countries").sole.fetch("country_code")
      end

      test "pay bands report percentiles by department and job level" do
        get "/api/v1/dashboard/pay_bands"

        assert_response :success
        group = response.parsed_body.fetch("groups").sole
        assert_equal "Engineering", group.fetch("department")
        assert_equal "Mid", group.fetch("job_level")
        assert_equal 150_000, group.fetch("p25_annual_salary_usd_cents")
        assert_equal 200_000, group.fetch("median_annual_salary_usd_cents")
        assert_equal 250_000, group.fetch("p75_annual_salary_usd_cents")
      end

      private

      def create_employee(code, department:)
        Employee.create!(
          employee_code: code,
          first_name: "Test",
          last_name: code,
          email: "#{code.downcase}@example.test",
          country_code: "US",
          department: department,
          job_title: "Mid Engineer",
          job_level: "Mid",
          date_of_joining: Date.new(2020, 1, 1)
        )
      end

      def create_compensation(employee, amount_cents:)
        Compensation.create!(
          employee: employee,
          amount_cents: amount_cents,
          currency: "USD",
          amount_usd_cents: amount_cents,
          effective_date: Date.new(2020, 1, 1),
          change_reason: "Initial Hire",
          is_active: true
        )
      end
    end
  end
end
