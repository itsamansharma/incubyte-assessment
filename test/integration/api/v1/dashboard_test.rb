require "test_helper"

module Api
  module V1
    class DashboardTest < ActionDispatch::IntegrationTest
      include PayrollTestData

      setup do
        @engineering = Department.create!(name: "Engineering", code: "ENG")
        @usd_rate = ExchangeRate.create!(currency_code: "USD", rate_to_usd: 1)
        @first_employee = create_employee("ACM-00001", department: @engineering)
        @second_employee = create_employee("ACM-00002", department: @engineering)
        create_compensation(@first_employee, amount_cents: 100_000)
        create_compensation(@second_employee, amount_cents: 300_000)
      end

      test "overview returns headcount and USD salary metrics" do
        create_employee("ACM-00003", department: @engineering)

        get "/api/v1/dashboard/overview"

        assert_response :success
        assert_equal 3, response.parsed_body.fetch("headcount")
        assert_equal 400_000, response.parsed_body.fetch("annual_payroll_usd_cents")
        assert_equal 200_000, response.parsed_body.fetch("average_annual_salary_usd_cents")
        assert_equal 200_000, response.parsed_body.fetch("median_annual_salary_usd_cents")
      end

      test "overview handles an empty workforce and no salary records" do
        Employee.delete_all

        get "/api/v1/dashboard/overview"

        assert_response :success
        assert_equal({
          "headcount" => 0,
          "annual_payroll_usd_cents" => 0,
          "average_annual_salary_usd_cents" => nil,
          "median_annual_salary_usd_cents" => nil
        }, response.parsed_body)
      end

      test "overview excludes employees without active compensation from salary metrics" do
        employee_without_salary = create_employee("ACM-00003", department: @engineering)
        create_compensation(employee_without_salary, amount_cents: 900_000, is_active: false)

        get "/api/v1/dashboard/overview"

        assert_response :success
        body = response.parsed_body
        assert_equal 3, body.fetch("headcount")
        assert_equal 400_000, body.fetch("annual_payroll_usd_cents")
        assert_equal 200_000, body.fetch("average_annual_salary_usd_cents")
        assert_equal 200_000, body.fetch("median_annual_salary_usd_cents")
      end

      test "breakdown groups salary metrics by department and country" do
        product = Department.create!(name: "Product", code: "PRD")
        product_employee = create_employee("ACM-00003", department: product, country_code: "GB")
        create_compensation(product_employee, amount_cents: 250_000)

        get "/api/v1/dashboard/breakdown"

        assert_response :success
        body = response.parsed_body
        departments = body.fetch("departments").index_by { |group| group.fetch("department") }
        countries = body.fetch("countries").index_by { |group| group.fetch("country_code") }
        assert_equal 2, departments.fetch("Engineering").fetch("headcount")
        assert_equal 1, departments.fetch("Product").fetch("headcount")
        assert_equal 2, countries.fetch("US").fetch("headcount")
        assert_equal 1, countries.fetch("GB").fetch("headcount")
        assert_equal 250_000, departments.fetch("Product").fetch("annual_payroll_usd_cents")
      end

      test "breakdown includes employees without compensation and reports null salary averages" do
        Employee.delete_all
        create_employee("ACM-00003", department: @engineering)

        get "/api/v1/dashboard/breakdown"

        assert_response :success
        department = response.parsed_body.fetch("departments").sole
        assert_equal 1, department.fetch("headcount")
        assert_equal 0, department.fetch("annual_payroll_usd_cents")
        assert_nil department.fetch("average_annual_salary_usd_cents")
        assert_nil department.fetch("median_annual_salary_usd_cents")
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

      test "pay bands group by department and job level and ignore inactive compensation" do
        create_compensation(@first_employee, amount_cents: 900_000, is_active: false)
        product = Department.create!(name: "Product", code: "PRD")
        director = create_employee("ACM-00003", department: product, job_level: "Director")
        create_compensation(director, amount_cents: 800_000)

        get "/api/v1/dashboard/pay_bands"

        assert_response :success
        groups = response.parsed_body.fetch("groups")
        assert_equal [ [ "Engineering", "Mid" ], [ "Product", "Director" ] ],
                     groups.map { |group| [ group.fetch("department"), group.fetch("job_level") ] }
        assert_equal 2, groups.first.fetch("headcount")
        assert_equal 800_000, groups.last.fetch("median_annual_salary_usd_cents")
      end

      test "pay bands returns no groups when employees have no active compensation" do
        Compensation.delete_all

        get "/api/v1/dashboard/pay_bands"

        assert_response :success
        assert_empty response.parsed_body.fetch("groups")
      end
    end
  end
end
