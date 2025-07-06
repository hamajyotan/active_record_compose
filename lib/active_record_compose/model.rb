# frozen_string_literal: true

require_relative "attributes"
require_relative "callbacks"
require_relative "composed_collection"
require_relative "persistence"

module ActiveRecordCompose
  class Model
    include ActiveModel::Model

    include ActiveRecordCompose::Attributes
    include ActiveRecordCompose::Persistence
    include ActiveRecordCompose::Callbacks

    def initialize(attributes = {})
      super
    end

    # Returns true if model is persisted.
    #
    # By overriding this definition, you can control the callbacks that are triggered when a save is made.
    # For example, returning false will trigger before_create, around_create and after_create,
    # and returning true will trigger before_update, around_update and after_update.
    #
    # @return [Boolean] returns true if model is persisted.
    def persisted? = super

    private

    def models = @__models ||= ActiveRecordCompose::ComposedCollection.new(self)
  end
end
