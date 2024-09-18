# frozen_string_literal: true

require 'spec_helper'
require 'active_record_compose/inner_model'

RSpec.describe ActiveRecordCompose::InnerModel do
  let(:owner) { nil }

  describe '#==' do
    subject(:inner_model) { ActiveRecordCompose::InnerModel.new(nil, account, context: :save) }

    let(:account) { Account.new }
    let(:profile) { Profile.new }

    specify 'returns true if and only if model and context are equivalent' do
      expect(inner_model).not_to eq nil
      expect(inner_model).not_to eq ActiveRecordCompose::InnerModel.new(owner, profile)
      expect(inner_model).not_to eq ActiveRecordCompose::InnerModel.new(owner, account, context: :destroy)
      expect(inner_model).to eq ActiveRecordCompose::InnerModel.new(owner, account, context: :save)
    end
  end

  describe '#save' do
    subject(:inner_model) { ActiveRecordCompose::InnerModel.new(nil, already_persisted_account, context:) }

    let(:already_persisted_account) { Account.create(name: 'foo', email: 'foo@example.com') }

    context 'given save to context' do
      let(:context) { :save }

      specify do
        expect(inner_model.save).to be_truthy
        expect(already_persisted_account).to be_persisted
      end
    end

    context 'given save to context' do
      let(:context) { :destroy }

      specify do
        expect(inner_model.save).to be_truthy
        expect(already_persisted_account).to be_destroyed
      end
    end
  end
end
