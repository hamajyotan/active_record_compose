# frozen_string_literal: true

class Account < ActiveRecord::Base
  has_one :profile
  validates :name, presence: true
  validates :email, presence: true
  validates :email, format: { with: /\.edu\z/ }, on: :education
end

class Profile < ActiveRecord::Base
  belongs_to :account
  validates :firstname, presence: true, length: { maximum: 32 }
  validates :lastname, presence: true, length: { maximum: 32 }
  validates :age, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :age, numericality: { less_than_or_equal_to: 18 }, on: :education
end

class OperationLog < ActiveRecord::Base
  validates :action, presence: true
end
