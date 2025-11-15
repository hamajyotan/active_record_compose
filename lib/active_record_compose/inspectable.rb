# frozen_string_literal: true

require "active_support/parameter_filter"
require_relative "attributes"

module ActiveRecordCompose
  # @private
  #
  # It provides #inspect behavior.
  # It tries to replicate the inspect format provided by ActiveRecord as closely as possible.
  #
  # @example
  #   class Model < ActiveRecordCompose::Model
  #     def initialize(ar_model)
  #       @ar_model = ar_model
  #       super
  #     end
  #
  #     attribute :foo, :date, default: -> { Date.today }
  #     delegate_attribute :bar, to: :ar_model
  #
  #     private attr_reader :ar_model
  #   end
  #
  #   m = Model.new(ar_model)
  #   m.inspect  #=> #<Model:0x00007ff0fe75fe58 foo: "2025-11-14", bar: "bar">
  #
  # @example
  #   class Model < ActiveRecordCompose::Model
  #     self.filter_attributes += %i[foo]
  #
  #     # ...
  #   end
  #
  #   m = Model.new(ar_model)
  #   m.inspect  #=> #<Model:0x00007ff0fe75fe58 foo: [FILTERED], bar: "bar">
  #
  module Inspectable
    extend ActiveSupport::Concern
    include ActiveRecordCompose::Attributes

    included do
      self.filter_attributes = []
    end

    module ClassMethods
      def filter_attributes
        if @filter_attributes.nil?
          superclass.filter_attributes # steep:ignore
        else
          @filter_attributes
        end
      end

      def filter_attributes=(value)
        @inspection_filter = nil
        @filter_attributes = value
      end

      # steep:ignore:start

      def inspection_filter
        if @filter_attributes.nil?
          superclass.inspection_filter
        else
          @inspection_filter ||= ActiveSupport::ParameterFilter.new(filter_attributes, mask: FILTERED_MASK)
        end
      end

      private

      def inherited(subclass)
        super

        subclass.class_eval do
          @inspection_filter = nil
          @filter_attributes ||= nil
        end
      end

      FILTERED_MASK =
        Class.new(DelegateClass(::String)) do
          def pretty_print(pp)
            pp.text __getobj__
          end
        end.new(ActiveSupport::ParameterFilter::FILTERED).freeze
      private_constant :FILTERED_MASK

      # steep:ignore:end
    end

    # Returns a formatted string representation of the record's attributes.
    #
    def inspect
      inspection =
        if @attributes
          attributes.map { |k, v| "#{k}: #{format_for_inspect(k, v)}" }.join(", ")
        else
          "not initialized"
        end

      "#<#{self.class} #{inspection}>"
    end

    # It takes a PP and pretty prints that record.
    #
    def pretty_print(pp)
      pp.object_address_group(self) do
        if @attributes
          attrs = attributes
          pp.seplist(attrs.keys, proc { pp.text "," }) do |attr|
            pp.breakable " "
            pp.group(1) do
              pp.text attr
              pp.text ":"
              pp.breakable
              pp.text format_for_inspect(attr, attrs[attr])
            end
          end
        else
          pp.breakable " "
          pp.text "not initialized"
        end
      end
    end

    private

    def format_for_inspect(name, value)
      return value.inspect if value.nil?

      inspected_value =
        if value.is_a?(String) && value.length > 50
          "#{value[0, 50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value.to_fs(:inspect)}")
        else
          value.inspect
        end

      self.class.inspection_filter.filter_param(name, inspected_value)
    end
  end
end
