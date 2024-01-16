# frozen_string_literal: true

class ComposedModel < ActiveRecordCompose::Model
  def initialize(account, attributes = {})
    @account = account
    @profile = account.then { _1.profile || _1.build_profile }
    super(attributes)
    models << account << profile
  end

  attribute :foo
  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  def push_falsy_object_to_models = models << nil

  private

  attr_reader :account, :profile
end

class ComposedModelWithDestroyContext < ActiveRecordCompose::Model
  def initialize(account, attributes = {})
    @account = account
    @profile = account.profile || account.build_profile
    super(attributes)
    models.push(account)
    models.push(profile, context: :destroy)
  end

  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile
end

class ComposedModelWithConditionalDestroyContext < ActiveRecordCompose::Model
  def initialize(account, attributes = {})
    @account = account
    @profile = account.profile || account.build_profile
    super(attributes)
    models.push(account)

    context = ->(p) { p.firstname.blank? && p.lastname.blank? && age.blank? ? :destroy : :save }
    models.push(profile, context:)
  end

  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile
end

class CallbackOrder < ActiveRecordCompose::Model
  attribute :before_save_called, :integer, default: 0
  attribute :before_create_called, :integer, default: 0
  attribute :before_update_called, :integer, default: 0
  attribute :after_save_called, :integer, default: 0
  attribute :after_create_called, :integer, default: 0
  attribute :after_update_called, :integer, default: 0

  before_save { self.before_save_called = order }
  before_create { self.before_create_called = order }
  before_update { self.before_update_called = order }
  after_save { self.after_save_called = order }
  after_create { self.after_create_called = order }
  after_update { self.after_update_called = order }

  def order
    @order = @order.to_i.succ
  end
end
