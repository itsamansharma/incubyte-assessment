class Employee < ApplicationRecord
  belongs_to :department
  has_many :compensations, dependent: :destroy
  has_one :active_compensation, -> { where(is_active: true) },
          class_name: "Compensation", inverse_of: :employee

  validates :employee_code, :first_name, :last_name, :email,
            :country_code, :job_title, :job_level, :date_of_joining,
            presence: true
  validates :employee_code, :email, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country_code, format: { with: /\A[A-Z]{2}\z/ }
end
