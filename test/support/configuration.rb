# frozen_string_literal: true

ActiveRecord::Base.configurations = {
  primary: { adapter: "sqlite3", database: ":memory:" }
}
