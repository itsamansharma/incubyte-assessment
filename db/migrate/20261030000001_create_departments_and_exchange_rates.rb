class CreateDepartmentsAndExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :departments do |t|
      t.string :name, null: false, limit: 100
      t.string :code, null: false, limit: 20

      t.timestamps
    end

    add_index :departments, :name, unique: true
    add_index :departments, :code, unique: true

    create_table :exchange_rates do |t|
      t.string :currency_code, null: false, limit: 3
      t.decimal :rate_to_usd, null: false, precision: 12, scale: 6

      t.timestamps
    end

    add_index :exchange_rates, :currency_code, unique: true
    add_check_constraint :exchange_rates, "currency_code ~ '^[A-Z]{3}$'",
                         name: "exchange_rates_currency_code_format"
    add_check_constraint :exchange_rates, "rate_to_usd > 0",
                         name: "exchange_rates_rate_to_usd_positive"
  end
end
