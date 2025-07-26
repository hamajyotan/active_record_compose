# frozen_string_literal: true

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:",
)

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :accounts, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.timestamps
  end

  create_table :profiles, force: true do |t|
    t.references :account, null: false, index: { unique: true }, foreign_key: true
    t.string :firstname, null: false
    t.string :lastname, null: false
    t.integer :age, null: false
    t.timestamps
  end

  create_table :operation_logs, force: true do |t|
    t.string :action, null: false
  end
end
