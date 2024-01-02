# frozen_string_literal: true

module ActiveRecordCompose
  module DelegateAttribute
    extend ActiveSupport::Concern

    included do
      class_attribute :delegated_attributes, instance_writer: false
    end

    class_methods do
      def delegate_attribute(*attributes, to:, **options)
        delegates = attributes.flat_map do |attribute|
          reader = attribute
          writer = "#{attribute}="

          [reader, writer]
        end

        delegate(*delegates, to:, **options)
        delegated_attributes = (self.delegated_attributes ||= [])
        attributes.each { delegated_attributes.push(_1.to_s) }
      end
    end

    def attributes
      super.merge(delegated_attributes.to_h { [_1, public_send(_1)] })
    end
  end
end
