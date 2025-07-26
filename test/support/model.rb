# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end

class Account < ApplicationRecord
  has_one :profile
  has_one :credential
  validates :name, presence: true
  validates :email, presence: true
  validates :email, format: { with: /\.edu\z/ }, on: :education
end

class Profile < ApplicationRecord
  belongs_to :account
  validates :firstname, presence: true, length: { maximum: 32 }
  validates :lastname, presence: true, length: { maximum: 32 }
  validates :age, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :age, numericality: { less_than_or_equal_to: 18 }, on: :education
end

class OperationLog < ApplicationRecord
  validates :action, presence: true
end
