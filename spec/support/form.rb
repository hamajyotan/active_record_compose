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
    models.push(profile, destroy: true)
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

    destroy = ->(p) { p.firstname.blank? && p.lastname.blank? && p.age.blank? }
    models.push(profile, destroy:)
  end

  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile
end

class ComposedModelWithConditionalDestroyContextWithNoBlockArgument < ActiveRecordCompose::Model
  def initialize(account, attributes = {})
    @account = account
    @profile = account.profile || account.build_profile
    super(attributes)
    models.push(account)
    models.push(profile, destroy: -> { blank_profile? })
  end

  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile

  def blank_profile? = firstname.blank? && lastname.blank? && age.blank?
end

class ComposedModelWithConditionalDestroyContextWithMethodName < ActiveRecordCompose::Model
  def initialize(account, attributes = {})
    @account = account
    @profile = account.profile || account.build_profile
    super(attributes)
    models.push(account)
    models.push(profile, destroy: :blank_profile?)
  end

  delegate_attribute :name, :email, to: :account
  delegate_attribute :firstname, :lastname, :age, to: :profile

  private

  attr_reader :account, :profile

  def blank_profile? = firstname.blank? && lastname.blank? && age.blank?
end

class ComposedModelWithOperationLog < ActiveRecordCompose::Model
  def initialize(attributes = {})
    @account = Account.new
    @operation_log = OperationLog.new(action: 'account_registration')
    super(attributes)
    models.push(account)
    models.push(operation_log, if: :output_log)
  end

  attribute :output_log, :boolean, default: true
  delegate_attribute :name, :email, to: :account

  private

  attr_reader :account, :operation_log
end

class CallbackOrder < ActiveRecordCompose::Model
  def initialize(tracer)
    @tracer = tracer
    super()
  end

  before_save { tracer << 'before_save called' }
  before_create { tracer << 'before_create called' }
  before_update { tracer << 'before_update called' }
  before_commit { tracer << 'before_commit called' }
  after_save { tracer << 'after_save called' }
  after_create { tracer << 'after_create called' }
  after_update { tracer << 'after_update called' }
  after_rollback { tracer << 'after_rollback called' }
  after_commit { tracer << 'after_commit called' }

  private

  attr_reader :tracer
end
