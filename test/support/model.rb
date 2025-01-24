# frozen_string_literal: true

class Account < ActiveRecord::Base
  has_one :profile
  validates :name, presence: true
  validates :email, presence: true
end

class Profile < ActiveRecord::Base
  belongs_to :account
  validates :firstname, presence: true, length: { maximum: 32 }
  validates :lastname, presence: true, length: { maximum: 32 }
  validates :age, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

class OperationLog < ActiveRecord::Base
  validates :action, presence: true
end
