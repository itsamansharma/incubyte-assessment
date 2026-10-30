module PayrollTestData
  def create_department(name: "Engineering", code: "ENG")
    Department.create!(name: name, code: code)
  end

  def create_employee(code, department:, country_code: "US", first_name: "Test", last_name: code,
                      email: "#{code.downcase}@example.test", job_title: "Mid Engineer", job_level: "Mid",
                      date_of_joining: Date.new(2020, 1, 1))
    build_employee(
      employee_code: code,
      department: department,
      country_code: country_code,
      first_name: first_name,
      last_name: last_name,
      email: email,
      job_title: job_title,
      job_level: job_level,
      date_of_joining: date_of_joining
    ).tap(&:save!)
  end

  def build_employee(employee_code:, department:, country_code: "US", first_name: "Test", last_name: employee_code,
                     email: "#{employee_code.downcase}@example.test", job_title: "Mid Engineer", job_level: "Mid",
                     date_of_joining: Date.new(2020, 1, 1))
    Employee.new(
      employee_code: employee_code,
      first_name: first_name,
      last_name: last_name,
      email: email,
      country_code: country_code,
      department: department,
      job_title: job_title,
      job_level: job_level,
      date_of_joining: date_of_joining
    )
  end

  def create_compensation(employee, amount_cents:, currency: "USD", amount_usd_cents: amount_cents,
                         effective_date: Date.new(2020, 1, 1), change_reason: "Initial Hire", is_active: true)
    Compensation.create!(
      employee: employee,
      amount_cents: amount_cents,
      currency: currency,
      amount_usd_cents: amount_usd_cents,
      effective_date: effective_date,
      change_reason: change_reason,
      is_active: is_active
    )
  end
end
