# frozen_string_literal: true

require 'spec_helper'
require 'active_record_compose/model'

RSpec.describe ActiveRecordCompose::Model do
  describe 'composed model' do
    subject(:model) { ComposedModel.new(account) }

    let(:account) { Account.new }

    context 'when invalid assign' do
      before do
        model.assign_attributes(
          name: nil,
          email: nil,
          firstname: '*' * 33,
          lastname: '*' * 33,
          age: -1,
        )
      end

      specify 'invalid. and map to errors' do
        expect(model).to be_invalid
        expect(model.errors).to be_of_kind(:name, :blank)
        expect(model.errors).to be_of_kind(:email, :blank)
        expect(model.errors).to be_of_kind(:firstname, :too_long)
        expect(model.errors).to be_of_kind(:lastname, :too_long)
        expect(model.errors).to be_of_kind(:age, :greater_than_or_equal_to)
        expect(model.errors.to_a).to match_array([
                                                   "Name can't be blank",
                                                   "Email can't be blank",
                                                   'Firstname is too long (maximum is 32 characters)',
                                                   'Lastname is too long (maximum is 32 characters)',
                                                   'Age must be greater than or equal to 0',
                                                 ])
      end

      specify 'not saved' do
        expect(model.save).to be_blank
        expect { model.save! }.to raise_error(ActiveRecord::RecordInvalid)
        begin
          model.save!
        rescue ActiveRecord::RecordInvalid => e
          expect(e.record).to eq model
        end
      end
    end

    context 'when valid assign' do
      before do
        model.assign_attributes(
          name: 'foo',
          email: 'foo@example.com',
          firstname: 'bar',
          lastname: 'baz',
          age: 45,
        )
      end

      it { is_expected.to be_valid }
      it { expect(model.save).to be_truthy }

      specify '#save is performed for each model entered in models by save.' do
        expect { model.save! }.to change(Account, :count).by(1).and change(Profile, :count).by(1)
      end

      context 'when raises on after_save' do
        let(:account) { AccountWithBang.new }

        specify 'exceptions must arrive as they are.' do
          expect { model.save }.to raise_error(RuntimeError, 'bang!!')
          expect { model.save! }.to raise_error(RuntimeError, 'bang!!')
        end
      end

      context 'when nil is mixed in with models' do
        before { model.push_falsy_object_to_models }

        it { is_expected.to be_valid }
        it { expect(model.save).to be_truthy }
      end
    end
  end

  describe 'composed model with destroy context' do
    subject(:model) do
      ComposedModelWithDestroyContext.new(
        account,
        name: 'bar',
        email: 'bar@example.com',
        firstname: 'qux',
        lastname: 'quux',
        age: 36,
      )
    end

    let(:account) do
      Account.create!(name: 'foo', email: 'foo@example.com').tap do |a|
        a.create_profile!(firstname: 'bar', lastname: 'baz', age: 45)
      end
    end

    context 'assign account attributes' do
      before do
        model.name = 'bar'
        model.email = 'bar@example.com'
      end

      it { is_expected.to be_valid }

      specify 'model in the destroy context must be destroyed' do
        expect { model.save! }.to change(Profile, :count).by(-1)
        account.reload
        expect(account.name).to eq 'bar'
        expect(account.email).to eq 'bar@example.com'
      end
    end
  end

  describe 'composed model with conditional destroy context' do
    subject(:model) do
      form.new(account, name: 'bar', email: 'bar@example.com')
    end

    let(:form) { ComposedModelWithConditionalDestroyContext }

    let(:account) do
      Account.create!(name: 'foo', email: 'foo@example.com').tap do |a|
        a.create_profile!(firstname: 'bar', lastname: 'baz', age: 45)
      end
    end

    context 'settings evaluated as not destroy (=save)' do
      before do
        model.firstname = 'qux'
        model.lastname = 'quux'
        model.age = 36
      end

      it { is_expected.to be_valid }

      specify 'model in the save context must be updated' do
        expect { model.save! }.not_to change(Profile, :count)
        account.profile.reload
        expect(account.profile.firstname).to eq 'qux'
        expect(account.profile.lastname).to eq 'quux'
        expect(account.profile.age).to eq 36
      end

      context 'when context block argument' do
        let(:form) { ComposedModelWithConditionalDestroyContextWithNoBlockArgument }

        specify 'same way' do
          expect { model.save! }.not_to change(Profile, :count)
          account.profile.reload
          expect(account.profile.firstname).to eq 'qux'
          expect(account.profile.lastname).to eq 'quux'
          expect(account.profile.age).to eq 36
        end
      end

      context 'when context with method name' do
        let(:form) { ComposedModelWithConditionalDestroyContextWithMethodName }

        specify 'same way' do
          expect { model.save! }.not_to change(Profile, :count)
          account.profile.reload
          expect(account.profile.firstname).to eq 'qux'
          expect(account.profile.lastname).to eq 'quux'
          expect(account.profile.age).to eq 36
        end
      end
    end

    context 'settings evaluated as destroy' do
      before do
        model.firstname = nil
        model.lastname = nil
        model.age = nil
      end

      it { is_expected.to be_valid }

      specify 'model in the destroy context must be destroyed' do
        expect { model.save! }.to change(Profile, :count).by(-1)
      end
    end
  end

  describe 'composed model with if option' do
    subject(:model) do
      ComposedModelWithOperationLog.new(name: 'foobar', email: 'foobar@example.com', output_log:)
    end

    context 'given true to output_log' do
      let(:output_log) { true }

      it 'Both Account and OperationLog are updated.' do
        expect { model.save! }.to change(Account, :count).by(1).and change(OperationLog, :count).by(1)
      end
    end

    context 'given false to output_log' do
      let(:output_log) { false }

      it 'OperationLog is not updated because the condition of the `if` option is not satisfied.' do
        expect { model.save! }.to change(Account, :count).by(1).and change(OperationLog, :count).by(0)
      end
    end
  end

  describe '.delegate_attributes' do
    subject(:model) do
      ComposedModel.new(
        account,
        foo: 'foobar',
        name: 'bar',
        email: 'bar@example.com',
        firstname: 'qux',
        lastname: 'quux',
        age: 36,
      )
    end

    let(:account) { Account.new }

    it 'attributes defined by .delegate_attributes should be included' do
      expected =
        {
          'foo' => 'foobar',
          'name' => 'bar',
          'email' => 'bar@example.com',
          'firstname' => 'qux',
          'lastname' => 'quux',
          'age' => 36,
        }
      expect(model.attributes).to eq expected
    end
  end

  describe 'callback order' do
    subject(:model) { CallbackOrder.new(tracer) }

    let(:tracer) { [] }

    context 'when #save' do
      specify 'only #before_save, #after_save should work' do
        model.save
        expect(tracer).to eq [
          'before_save called',
          'after_save called',
          'before_commit called',
          'after_commit called',
        ]
      end
    end

    context 'when #create' do
      specify 'in addition to #before_save and #after_save, #before_create and #after_create must also work' do
        model.create
        expect(tracer).to eq [
          'before_save called',
          'before_create called',
          'after_create called',
          'after_save called',
          'before_commit called',
          'after_commit called',
        ]
      end
    end

    context 'when #update' do
      specify 'in addition to #before_save and #after_save, #before_update and #after_update must also work' do
        model.update
        expect(tracer).to eq [
          'before_save called',
          'before_update called',
          'after_update called',
          'after_save called',
          'before_commit called',
          'after_commit called',
        ]
      end
    end

    specify 'execution of (before|after)_commit hook is delayed until after the database commit.' do
      ActiveRecord::Base.transaction do
        tracer << 'outer transsaction starts'
        ActiveRecord::Base.transaction do
          tracer << 'inner transsaction starts'
          model.save
          tracer << 'inner transsaction ends'
        end
        tracer << 'outer transsaction ends'
      end
      expect(tracer).to eq [
        'outer transsaction starts',
        'inner transsaction starts',
        'before_save called',
        'after_save called',
        'inner transsaction ends',
        'outer transsaction ends',
        'before_commit called',
        'after_commit called',
      ]
    end

    specify 'execution of after_rollback hook is delayed until after the database rollback.' do
      ActiveRecord::Base.transaction do
        tracer << 'outer transsaction starts'
        ActiveRecord::Base.transaction do
          tracer << 'inner transsaction starts'
          model.save
          tracer << 'inner transsaction ends'
        end
        tracer << 'outer transsaction ends'
        raise ActiveRecord::Rollback
      end
      expect(tracer).to eq [
        'outer transsaction starts',
        'inner transsaction starts',
        'before_save called',
        'after_save called',
        'inner transsaction ends',
        'outer transsaction ends',
        'after_rollback called',
      ]
    end
  end

  describe 'when ActiveRecord::RecordInvalid error raises in the #after_save hook' do
    subject(:model) { klass.new }
    let(:klass) do
      Class.new(ActiveRecordCompose::Model) do
        after_save :raise_record_invalid

        private

        def raise_record_invalid = Account.create!(name: nil, email: nil)
      end
    end

    specify '#ave without bang returns false, save with bang raises an exception.' do
      expect(model.save).to be_blank
      expect { model.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
