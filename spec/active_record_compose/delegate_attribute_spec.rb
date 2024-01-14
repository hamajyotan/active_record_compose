# frozen_string_literal: true

require 'spec_helper'
require 'active_record_compose/delegate_attribute'

RSpec.describe ActiveRecordCompose::DelegateAttribute do
  before { stub_const('Dummy', klass) }

  subject { klass.new(data) }

  let(:data) { Struct.new(:x, :y, :z, keyword_init: true).new }

  let(:klass) do
    Class.new do
      include ActiveRecordCompose::DelegateAttribute

      def initialize(data)
        @data = data
      end

      delegate_attribute :x, :y, to: :data

      private

      attr_reader :data
    end
  end

  specify 'reader method must is defined' do
    data.x = 'foo'
    expect(data.x).to eq 'foo'
    expect(subject.x).to eq 'foo'
  end

  specify 'writer method must is defined' do
    subject.y = 'bar'
    expect(data.y).to eq 'bar'
    expect(subject.y).to eq 'bar'
  end

  specify 'definition declared in delegate must be included in attributes' do
    subject.x = 'foo'
    subject.y = 'bar'
    expect(subject.attributes).to eq({ 'x' => 'foo', 'y' => 'bar' })
  end
end
