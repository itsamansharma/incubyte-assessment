class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :employee_code, null: false, limit: 20
      t.string :first_name, null: false, limit: 100
      t.string :last_name, null: false, limit: 100
      t.string :email, null: false, limit: 255
      t.string :country_code, null: false, limit: 2
      t.references :department, null: false, foreign_key: { on_delete: :restrict }
      t.string :job_title, null: false, limit: 100
      t.string :job_level, null: false, limit: 20
      t.date :date_of_joining, null: false

      t.timestamps
    end

    add_index :employees, :employee_code, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, %i[country_code department_id], name: "index_employees_on_country_and_department"
    add_index :employees, %i[last_name first_name], name: "index_employees_on_last_and_first_name"
    add_check_constraint :employees, "country_code ~ '^[A-Z]{2}$'",
                         name: "employees_country_code_format"
  end
end
