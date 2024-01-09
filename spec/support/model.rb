# frozen_string_literal: true

class Account < ActiveRecord::Base
  has_one :profile
  validates :name, presence: true
  validates :email, presence: true
end

class Profile < ActiveRecord::Base
  belongs_to :account
  validates :firstname, length: { maximum: 32 }
  validates :lastname, length: { maximum: 32 }
  validates :age, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

class AccountWithBang < ActiveRecord::Base
  self.table_name = :accounts

  after_save :bang!

  has_one :profile, foreign_key: :account_id
  validates :name, presence: true
  validates :email, presence: true

  private

  def bang!
    raise 'bang!!'
  end
end
