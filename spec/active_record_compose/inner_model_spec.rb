# frozen_string_literal: true

require 'spec_helper'
require 'active_record_compose/inner_model_collection'

RSpec.describe ActiveRecordCompose::InnerModel do
  describe '#==' do
    subject(:inner_model) { ActiveRecordCompose::InnerModel.new(account, context: :save) }

    let(:account) { Account.new }
    let(:profile) { Profile.new }

    specify 'returns true if and only if model and context are equivalent' do
      expect(inner_model).not_to eq nil
      expect(inner_model).not_to eq ActiveRecordCompose::InnerModel.new(profile)
      expect(inner_model).not_to eq ActiveRecordCompose::InnerModel.new(account, context: :destroy)
      expect(inner_model).to eq ActiveRecordCompose::InnerModel.new(account, context: :save)
    end
  end
end
