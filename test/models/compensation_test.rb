require "test_helper"

class CompensationTest < ActiveSupport::TestCase
  include PayrollTestData

  setup do
    @employee = create_employee("ACM-00001", department: create_department)
  end

  test "accepts non-negative integer local and USD amounts" do
    compensation = Compensation.new(
      employee: @employee, amount_cents: 0, currency: "USD", amount_usd_cents: 0,
      effective_date: Date.new(2025, 1, 1), change_reason: "Initial Hire"
    )

    assert_predicate compensation, :valid?
  end

  test "rejects negative salary amounts" do
    compensation = Compensation.new(
      employee: @employee, amount_cents: -1, currency: "USD", amount_usd_cents: -1,
      effective_date: Date.new(2025, 1, 1), change_reason: "Initial Hire"
    )

    assert_not compensation.valid?
    assert_includes compensation.errors.attribute_names, :amount_cents
    assert_includes compensation.errors.attribute_names, :amount_usd_cents
  end

  test "requires an uppercase three-letter currency and effective date and reason" do
    compensation = Compensation.new(
      employee: @employee, amount_cents: 100_000, currency: "usd", amount_usd_cents: 100_000,
      effective_date: nil, change_reason: ""
    )

    assert_not compensation.valid?
    %i[currency effective_date change_reason].each do |field|
      assert_includes compensation.errors.attribute_names, field
    end
  end
end
