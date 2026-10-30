class ExchangeRate < ApplicationRecord
  validates :currency_code,
            presence: true,
            uniqueness: true,
            format: { with: /\A[A-Z]{3}\z/ }
  validates :rate_to_usd, numericality: { greater_than: 0 }
end
