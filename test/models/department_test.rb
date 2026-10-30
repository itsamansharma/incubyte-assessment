require "test_helper"

class DepartmentTest < ActiveSupport::TestCase
  include PayrollTestData

  test "requires a name and code" do
    department = Department.new(name: "", code: "")

    assert_not department.valid?
    assert_includes department.errors.attribute_names, :name
    assert_includes department.errors.attribute_names, :code
  end

  test "requires unique names and codes" do
    create_department
    duplicate_name = Department.new(name: "Engineering", code: "OPS")
    duplicate_code = Department.new(name: "Operations", code: "ENG")

    assert_not duplicate_name.valid?
    assert_includes duplicate_name.errors.attribute_names, :name
    assert_not duplicate_code.valid?
    assert_includes duplicate_code.errors.attribute_names, :code
  end

  test "cannot be destroyed while employees belong to it" do
    department = create_department
    create_employee("ACM-00001", department: department)

    assert_raises(ActiveRecord::DeleteRestrictionError) { department.destroy }
  end
end
