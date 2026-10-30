class Compensation < ApplicationRecord
  belongs_to :employee, inverse_of: :compensations

  scope :active, -> { where(is_active: true) }
  scope :history, -> { order(effective_date: :desc, created_at: :desc) }

  validates :amount_cents, :amount_usd_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency,
            presence: true,
            format: { with: /\A[A-Z]{3}\z/ }
  validates :effective_date, :change_reason, presence: true
end
