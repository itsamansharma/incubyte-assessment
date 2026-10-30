class Department < ApplicationRecord
  has_many :employees, dependent: :restrict_with_exception

  validates :name, :code, presence: true, uniqueness: true
end
