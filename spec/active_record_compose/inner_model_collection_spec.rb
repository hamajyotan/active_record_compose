# frozen_string_literal: true

require 'spec_helper'
require 'active_record_compose/inner_model_collection'

RSpec.describe ActiveRecordCompose::InnerModelCollection do
  subject(:collection) { ActiveRecordCompose::InnerModelCollection.new(owner) }

  let(:owner) { nil }

  describe '#empty?' do
    context 'when models is blank' do
      specify 'returns true' do
        expect(collection).to be_empty
      end
    end

    context 'when models is present' do
      before { collection << Account.new }

      specify 'returns false' do
        expect(collection).not_to be_empty
      end
    end
  end

  describe '#clear' do
    before { collection << Account.new }

    specify 'can be made empty by #clear' do
      collection.clear
      expect(collection).to be_empty
    end
  end

  describe '#delete' do
    let(:account) { Account.new }
    let(:profile) { Profile.new }

    specify 'can be made empty by #clear' do
      collection << account << profile
      expect(collection.first).to eq account
      collection.delete(account)
      expect(collection.first).to eq profile
    end

    specify 'context must also be the same to get a hit' do
      expect(collection).to be_blank
      collection.push(account, context: :save)
      expect(collection).to be_present
      collection.delete(account, context: :destroy)
      expect(collection).to be_present
    end
  end
end
