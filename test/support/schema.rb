# frozen_string_literal: true

require "test/support/configuration"

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  connects_to database: { writing: :primary }
end

ApplicationRecord.connection_pool.with_connection do |conn|
  conn.create_table :accounts, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.datetime :resigned_at
    t.timestamps
  end

  conn.create_table :credentials, force: true do |t|
    t.references :account, null: false, index: { unique: true }, foreign_key: true
    t.string :password_digest, null: false
  end

  conn.create_table :profiles, force: true do |t|
    t.references :account, null: false, index: { unique: true }, foreign_key: true
    t.string :firstname, null: false
    t.string :lastname, null: false
    t.integer :age, null: false
    t.timestamps
  end

  conn.create_table :operation_logs, force: true do |t|
    t.string :action, null: false
  end
end
