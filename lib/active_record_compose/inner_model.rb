# frozen_string_literal: true

require 'active_support/core_ext/object'

module ActiveRecordCompose
  class InnerModel
    # @param model [Object] the model instance.
    # @param destroy [Boolean] given true, destroy model.
    # @param destroy [Proc] when proc returning true, destroy model.
    def initialize(model, destroy: false, context: nil)
      @model = model
      @destroy_context_type =
        if context
          c = context

          if c.is_a?(Proc)
            # @type var c: ((^() -> (context)) | (^(_ARLike) -> (context)))
            if c.arity == 0
              deprecator.warn(
                '`:context` will be removed in 0.5.0. Use `:destroy` option instead. ' \
                'for example, `models.push(model, context: -> { foo? ? :destroy : :save })` ' \
                'is replaced by `models.push(model, destroy: -> { foo? })`.',
              )

              # @type var c: ^() -> (context)
              -> { c.call == :destroy }
            else
              deprecator.warn(
                '`:context` will be removed in 0.5.0. Use `:destroy` option instead. ' \
                'for example, `models.push(model, context: ->(m) { m.bar? ? :destroy : :save })` ' \
                'is replaced by `models.push(model, destroy: ->(m) { m.bar? })`.',
              )

              # @type var c: ^(_ARLike) -> (context)
              ->(model) { c.call(model) == :destroy }
            end
          elsif %i[save destroy].include?(c)
            deprecator.warn(
              '`:context` will be removed in 0.5.0. Use `:destroy` option instead. ' \
              "for example, `models.push(model, context: #{c.inspect})` " \
              "is replaced by `models.push(model, destroy: #{(c == :destroy).inspect})`.",
            )

            # @type var c: (:save | :destory)
            c == :destroy
          else
            c
          end
        else
          destroy
        end
    end

    delegate :errors, to: :model

    def destroy_context?
      d = destroy_context_type
      if d.is_a?(Proc)
        if d.arity == 0
          # @type var d: ^() -> (bool | context)
          !!d.call
        else
          # @type var d: ^(_ARLike) -> (bool | context)
          !!d.call(model)
        end
      else
        !!d
      end
    end

    # Execute save or destroy. Returns true on success, false on failure.
    # Whether save or destroy is executed depends on the value of `#destroy_context?`.
    #
    # @return [Boolean] returns true on success, false on failure.
    def save = destroy_context? ? model.destroy : model.save

    # Execute save or destroy. Unlike #save, an exception is raises on failure.
    # Whether save or destroy is executed depends on the value of `#destroy_context?`.
    #
    def save! = destroy_context? ? model.destroy! : model.save!

    # @return [Boolean]
    def invalid? = destroy_context? ? false : model.invalid?

    # @return [Boolean]
    def valid? = !invalid?

    # Returns true if equivalent.
    #
    # @param [Object] other
    # @return [Boolean]
    def ==(other)
      return false unless self.class == other.class
      return false unless __raw_model == other.__raw_model # steep:ignore

      true
    end

    # @private
    # Returns a model instance of raw, but it should
    # be noted that application developers are not expected to use this interface.
    #
    # @return [Object] raw model instance
    def __raw_model = model

    private

    attr_reader :model, :destroy_context_type

    def deprecator
      if ActiveRecord.respond_to?(:deprecator)
        ActiveRecord.deprecator
      else # for rails 7.0.x or lower
        ActiveSupport::Deprecation
      end
    end
  end
end
