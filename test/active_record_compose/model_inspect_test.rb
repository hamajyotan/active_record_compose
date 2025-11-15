# frozen_string_literal: true

require "pp"
require "stringio"
require "test_helper"
require "active_record_compose/model"
require "active_support/core_ext/time"

class ActiveRecordCompose::ModelInspectTest < ActiveSupport::TestCase
  test "returns an ActiveRecord model-like #inspect" do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def self.to_s = "Klass"

        def initialize(account = Account.new)
          @account = account
          super()
          models << account
        end

        delegate_attribute :name, :email, :created_at, to: :account

        private attr_reader :account
      end

    account = Account.create!(name: "alice", email: "alice@example.com")
    model = klass.new(account)

    model.name = "1234567890" * 10
    model.created_at = Time.new(2025, 1, 2, 3, 4, 5, in: "-0800")

    expected =
      '#<Klass name: "12345678901234567890123456789012345678901234567890...", email: "alice@example.com", created_at: "2025-01-02 03:04:05.000000000 -0800">'
    assert { model.inspect == expected }

    assert_pretty_inspect(model, <<~PRETTY_INSPECT)
      #{Kernel.instance_method(:to_s).bind_call(model).chop}
       name: "12345678901234567890123456789012345678901234567890...",
       email: "alice@example.com",
       created_at: "2025-01-02 03:04:05.000000000 -0800">
    PRETTY_INSPECT
  end

  test "The attributes specified in `.filter_attributes` are masked." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def self.to_s = "Klass"

        attribute :email, :string
        attribute :password, :string

        self.filter_attributes += %i[password]
      end
    model = klass.new(email: "alice@example.com", password: "Secret")

    assert { model.inspect == '#<Klass email: "alice@example.com", password: [FILTERED]>' }

    assert_pretty_inspect(model, <<~PRETTY_INSPECT)
      #{Kernel.instance_method(:to_s).bind_call(model).chop}
       email: "alice@example.com",
       password: [FILTERED]>
    PRETTY_INSPECT
  end

  test "The settings of `.filter_attributes` are valid for sublcass as well." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def self.to_s = "Klass"

        attribute :email, :string
        attribute :password, :string

        self.filter_attributes += %i[password]
      end
    subclass =
      Class.new(klass) do
        def self.to_s = "Subclass"

        attribute :age, :integer
      end
    model = subclass.new(email: "alice@example.com", password: "Secret", age: 25)

    assert { model.inspect == '#<Subclass email: "alice@example.com", password: [FILTERED], age: 25>' }

    assert_pretty_inspect(model, <<~PRETTY_INSPECT)
      #{Kernel.instance_method(:to_s).bind_call(model).chop}
       email: "alice@example.com",
       password: [FILTERED],
       age: 25>
    PRETTY_INSPECT
  end

  test "The `.filter_attributes` settings can be overwritten by sublcass." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def self.to_s = "Klass"

        attribute :email, :string
        attribute :password, :string

        self.filter_attributes += %i[password]
      end
    subclass =
      Class.new(klass) do
        def self.to_s = "Subclass"

        attribute :age, :integer

        self.filter_attributes += %i[email]
      end
    model = subclass.new(email: "alice@example.com", password: "Secret", age: 25)

    assert { model.inspect == "#<Subclass email: [FILTERED], password: [FILTERED], age: 25>" }

    assert_pretty_inspect(model, <<~PRETTY_INSPECT)
      #{Kernel.instance_method(:to_s).bind_call(model).chop}
       email: [FILTERED],
       password: [FILTERED],
       age: 25>
    PRETTY_INSPECT
  end

  test "The `.filter_attributes` setting can be overwritten to blanks using sublcass." do
    klass =
      Class.new(ActiveRecordCompose::Model) do
        def self.to_s = "Klass"

        attribute :email, :string
        attribute :password, :string

        self.filter_attributes += %i[password]
      end
    subclass =
      Class.new(klass) do
        def self.to_s = "Subclass"

        attribute :age, :integer

        self.filter_attributes = []
      end
    model = subclass.new(email: "alice@example.com", password: "Secret", age: 25)

    assert { model.inspect == '#<Subclass email: "alice@example.com", password: "Secret", age: 25>' }

    assert_pretty_inspect(model, <<~PRETTY_INSPECT)
      #{Kernel.instance_method(:to_s).bind_call(model).chop}
       email: "alice@example.com",
       password: "Secret",
       age: 25>
    PRETTY_INSPECT

    subclass.filter_attributes = %i[age]

    assert { model.inspect == '#<Subclass email: "alice@example.com", password: "Secret", age: [FILTERED]>' }
  end

  private

  def assert_pretty_inspect(object, expected)
    out = StringIO.new
    PP.pp(object, out)
    actual = out.string

    assert_equal expected, actual
  end
end
