class CreateCompensations < ActiveRecord::Migration[8.1]
  def change
    create_table :compensations do |t|
      t.references :employee, null: false, index: false,
                              foreign_key: { on_delete: :cascade }
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, limit: 3
      t.bigint :amount_usd_cents, null: false
      t.date :effective_date, null: false
      t.string :change_reason, null: false, limit: 100, default: "Initial Hire"
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :compensations, :employee_id, unique: true,
              where: "is_active = TRUE",
              name: "index_compensations_on_active_employee"
    add_index :compensations, %i[employee_id effective_date],
              name: "index_compensations_on_employee_and_effective_date"
    add_index :compensations, :amount_usd_cents,
              where: "is_active = TRUE",
              name: "index_compensations_on_active_usd_amount"
    add_index :compensations, :effective_date

    add_check_constraint :compensations, "currency ~ '^[A-Z]{3}$'",
                         name: "compensations_currency_format"
    add_check_constraint :compensations, "amount_cents >= 0",
                         name: "compensations_amount_cents_nonnegative"
    add_check_constraint :compensations, "amount_usd_cents >= 0",
                         name: "compensations_amount_usd_cents_nonnegative"
  end
end
