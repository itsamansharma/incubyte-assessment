require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  include PayrollTestData

  setup do
    @department = create_department
  end

  test "requires all employee profile fields" do
    employee = Employee.new(department: @department)

    assert_not employee.valid?
    %i[employee_code first_name last_name email country_code job_title job_level date_of_joining].each do |field|
      assert_includes employee.errors.attribute_names, field
    end
  end

  test "validates email format and uniqueness" do
    existing = create_employee("ACM-00001", department: @department)
    invalid_email = Employee.new(
      employee_code: "ACM-00002", first_name: "Test", last_name: "User", email: "not-an-email",
      country_code: "US", department: @department, job_title: "Engineer", job_level: "Mid",
      date_of_joining: Date.new(2020, 1, 1)
    )
    duplicate_email = Employee.new(
      employee_code: "ACM-00003", first_name: "Test", last_name: "User", email: existing.email,
      country_code: "US", department: @department, job_title: "Engineer", job_level: "Mid",
      date_of_joining: Date.new(2020, 1, 1)
    )

    assert_not invalid_email.valid?
    assert_includes invalid_email.errors.attribute_names, :email
    assert_not duplicate_email.valid?
    assert_includes duplicate_email.errors.attribute_names, :email
  end

  test "validates employee code uniqueness and two-letter uppercase country codes" do
    existing = create_employee("ACM-00001", department: @department)
    duplicate_code = Employee.new(
      employee_code: existing.employee_code, first_name: "Other", last_name: "User", email: "other@example.test",
      country_code: "US", department: @department, job_title: "Engineer", job_level: "Mid",
      date_of_joining: Date.new(2020, 1, 1)
    )
    malformed_country = build_employee(employee_code: "ACM-00002", department: @department, country_code: "USA")

    assert_not duplicate_code.valid?
    assert_includes duplicate_code.errors.attribute_names, :employee_code
    assert_not malformed_country.valid?
    assert_includes malformed_country.errors.attribute_names, :country_code
  end

  test "destroys compensation history with the employee" do
    employee = create_employee("ACM-00001", department: @department)
    create_compensation(employee, amount_cents: 100_000)

    assert_difference "Compensation.count", -1 do
      employee.destroy!
    end
  end
end
