require "test_helper"

class ExchangeRateTest < ActiveSupport::TestCase
  test "accepts a positive rate with an uppercase three-letter currency code" do
    rate = ExchangeRate.new(currency_code: "USD", rate_to_usd: "1.0")

    assert_predicate rate, :valid?
  end

  test "requires a unique uppercase three-letter currency code" do
    ExchangeRate.create!(currency_code: "USD", rate_to_usd: "1.0")
    duplicate = ExchangeRate.new(currency_code: "USD", rate_to_usd: "1.1")
    malformed = ExchangeRate.new(currency_code: "usd", rate_to_usd: "1.0")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :currency_code
    assert_not malformed.valid?
    assert_includes malformed.errors.attribute_names, :currency_code
  end

  test "requires a positive conversion rate" do
    [ 0, -1 ].each do |rate_to_usd|
      rate = ExchangeRate.new(currency_code: "USD", rate_to_usd: rate_to_usd)

      assert_not rate.valid?, "expected #{rate_to_usd} to be invalid"
      assert_includes rate.errors.attribute_names, :rate_to_usd
    end
  end
end
