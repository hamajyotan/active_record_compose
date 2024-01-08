# frozen_string_literal: true

require 'spec_helper'
require 'active_record_compose/inner_model_collection'

RSpec.describe ActiveRecordCompose::InnerModelCollection do
  describe '#empty?' do
    subject(:collection) { ActiveRecordCompose::InnerModelCollection.new }

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
    subject(:collection) { ActiveRecordCompose::InnerModelCollection.new }

    before { collection << Account.new }

    specify 'can be made empty by #clear' do
      collection.clear
      expect(collection).to be_empty
    end
  end
end
