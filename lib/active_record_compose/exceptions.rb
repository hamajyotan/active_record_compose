# frozen_string_literal: true

module ActiveRecordCompose
  # Occurs when a circular reference is detected in the containing model.
  #
  # @example
  #     class Model < ActiveRecordCompose::Model
  #       def initialize
  #         super()
  #         models << self  # Adding itself to models creates a circular reference.
  #       end
  #     end
  #     model = Model.new
  #     model.save  #=> raises ActiveRecordCompose::CircularReferenceDetected
  #
  # @example
  #     class Model < ActiveRecordCompose::Model
  #       attribute :model
  #       before_validation { models << model }
  #     end
  #     inner = Model.new
  #     middle = Model.new(model: inner)
  #     outer = Model.new(model: middle)
  #
  #     inner.model = outer  # There is a circular reference in the form outer > middle > inner > outer.
  #     outer.save  #=> raises ActiveRecordCompose::CircularReferenceDetected
  #
  class CircularReferenceDetected < StandardError; end
end
