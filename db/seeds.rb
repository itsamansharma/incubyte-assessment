# Stable reference data and a repeatable 10,000-person sample workforce.
# Run with `bin/rails db:seed`; existing employees and their salary histories are kept.

SEED_SIZE = 10_000
SEED_BATCH_SIZE = 1_000
SEED_RANDOM = Random.new(20_261_030)

DEPARTMENTS = [
  [ "Engineering", "ENG" ],
  [ "Product", "PRD" ],
  [ "Sales", "SAL" ],
  [ "Finance", "FIN" ],
  [ "Human Resources", "HR" ],
  [ "Operations", "OPS" ],
  [ "Marketing", "MKT" ],
  [ "Customer Support", "CS" ]
].freeze

# Rates are the USD value of one unit of the currency, represented in millionths
# to keep the generated salary conversions deterministic and free of floats.
SEED_RATES = {
  "USD" => 1_000_000,
  "EUR" => 1_080_000,
  "GBP" => 1_270_000,
  "INR" => 12_000,
  "SGD" => 740_000
}.freeze

SEED_COUNTRIES = [
  {
    code: "US", currency: "USD", pay_factor: 10_000, weight: 40,
    first_names: %w[Alex Avery Casey Jordan Morgan Riley Taylor Jamie Quinn Cameron],
    last_names: %w[Johnson Smith Davis Brown Wilson Miller Moore Taylor Anderson Thomas]
  },
  {
    code: "GB", currency: "GBP", pay_factor: 8_500, weight: 20,
    first_names: %w[Oliver Amelia George Isla Harry Olivia Jack Emily Arthur Grace],
    last_names: %w[Smith Jones Taylor Brown Wilson Davies Evans Thomas Roberts Walker]
  },
  {
    code: "IN", currency: "INR", pay_factor: 3_500, weight: 20,
    first_names: %w[Aarav Anaya Arjun Diya Ishaan Kavya Neel Priya Rohan Saanvi],
    last_names: %w[Sharma Patel Kumar Singh Gupta Mehta Reddy Nair Shah Iyer]
  },
  {
    code: "DE", currency: "EUR", pay_factor: 9_000, weight: 12,
    first_names: %w[Anna Ben Clara Elias Felix Hannah Jonas Lena Lukas Mia],
    last_names: %w[Mueller Schmidt Schneider Fischer Weber Meyer Wagner Becker Schulz Hoffmann]
  },
  {
    code: "SG", currency: "SGD", pay_factor: 9_500, weight: 8,
    first_names: %w[Amelia Chloe Ethan Hannah Isaac Jia Wei Kai Li Mei],
    last_names: %w[Lim Tan Lee Ng Wong Goh Chua Koh Teo Yeo]
  }
].freeze

SEED_LEVELS = [
  { name: "Junior", minimum_usd_cents: 4_500_000, maximum_usd_cents: 6_500_000, weight: 25 },
  { name: "Mid", minimum_usd_cents: 6_500_000, maximum_usd_cents: 9_500_000, weight: 35 },
  { name: "Senior", minimum_usd_cents: 9_500_000, maximum_usd_cents: 14_500_000, weight: 25 },
  { name: "Lead", minimum_usd_cents: 13_000_000, maximum_usd_cents: 18_000_000, weight: 8 },
  { name: "Manager", minimum_usd_cents: 11_500_000, maximum_usd_cents: 17_500_000, weight: 5 },
  { name: "Director", minimum_usd_cents: 16_000_000, maximum_usd_cents: 24_000_000, weight: 2 }
].freeze

def seed_weighted_choice(random, choices)
  total = choices.sum { |choice| choice.fetch(:weight) }
  pick = random.rand(total)

  choices.each do |choice|
    pick -= choice.fetch(:weight)
    return choice if pick.negative?
  end
end

now = Time.current
Department.upsert_all(
  DEPARTMENTS.map do |name, code|
    { name: name, code: code, created_at: now, updated_at: now }
  end,
  unique_by: :index_departments_on_code
)
department_ids = Department.pluck(:code, :id).to_h

ExchangeRate.upsert_all(
  SEED_RATES.map do |currency, rate_micros|
    {
      currency_code: currency,
      rate_to_usd: BigDecimal(rate_micros.to_s) / 1_000_000,
      created_at: now,
      updated_at: now
    }
  end,
  unique_by: :index_exchange_rates_on_currency_code
)

SEED_SIZE.times.each_slice(SEED_BATCH_SIZE) do |indexes|
  employees_by_code = {}
  employee_rows = indexes.map do |index|
    employee_code = format("ACM-%05d", index + 1)
    country = seed_weighted_choice(SEED_RANDOM, SEED_COUNTRIES)
    level = seed_weighted_choice(SEED_RANDOM, SEED_LEVELS)
    level_name = level.fetch(:name)
    minimum_usd_cents = level.fetch(:minimum_usd_cents)
    maximum_usd_cents = level.fetch(:maximum_usd_cents)
    department_code, department_id = department_ids.sort[SEED_RANDOM.rand(department_ids.size)]
    first_joining_date = Date.new(2011, 1, 1)
    last_joining_date = Date.new(2025, 12, 31)
    effective_date = first_joining_date + SEED_RANDOM.rand((last_joining_date - first_joining_date).to_i + 1)

    usd_salary_cents = SEED_RANDOM.rand(minimum_usd_cents..maximum_usd_cents)
    target_usd_salary_cents = (usd_salary_cents * country.fetch(:pay_factor) + 5_000) / 10_000
    rate_micros = SEED_RATES.fetch(country.fetch(:currency))
    local_salary_cents = (target_usd_salary_cents * 1_000_000 + rate_micros / 2) / rate_micros
    usd_salary_cents = (local_salary_cents * rate_micros + 500_000) / 1_000_000

    employees_by_code[employee_code] = {
      amount_cents: local_salary_cents,
      amount_usd_cents: usd_salary_cents,
      currency: country.fetch(:currency),
      effective_date: effective_date
    }

    {
      employee_code: employee_code,
      first_name: country.fetch(:first_names).sample(random: SEED_RANDOM),
      last_name: country.fetch(:last_names).sample(random: SEED_RANDOM),
      email: "#{employee_code.downcase}@example.com",
      country_code: country.fetch(:code),
      department_id: department_id,
      job_title: [ "Manager", "Director" ].include?(level_name) ? "#{level_name}, #{department_code}" : "#{level_name} #{department_code}",
      job_level: level_name,
      date_of_joining: effective_date,
      created_at: now,
      updated_at: now
    }
  end

  Employee.transaction do
    inserted_employees = Employee.insert_all(
      employee_rows,
      unique_by: :index_employees_on_employee_code,
      returning: %w[id employee_code]
    )

    compensation_rows = inserted_employees.map do |employee|
      salary = employees_by_code.fetch(employee.fetch("employee_code"))
      {
        employee_id: employee.fetch("id"),
        amount_cents: salary.fetch(:amount_cents),
        currency: salary.fetch(:currency),
        amount_usd_cents: salary.fetch(:amount_usd_cents),
        effective_date: salary.fetch(:effective_date),
        change_reason: "Initial Hire",
        is_active: true,
        created_at: now,
        updated_at: now
      }
    end
    Compensation.insert_all!(compensation_rows) if compensation_rows.any?
  end
end

puts "Seeded #{Department.count} departments, #{SEED_RATES.size} exchange rates, and up to #{SEED_SIZE} employees."
