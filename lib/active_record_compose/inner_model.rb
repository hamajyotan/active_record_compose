# frozen_string_literal: true

require 'active_support/core_ext/object'

module ActiveRecordCompose
  class InnerModel
    # @param model [Object] the model instance.
    # @param destroy [Boolean] given true, destroy model.
    # @param destroy [Proc] when proc returning true, destroy model.
    def initialize(owner, model, destroy: false, context: nil)
      @owner = owner
      @model = model
      @destroy =
        if context
          c = context

          if c.is_a?(Proc)
            # @type var c: ((^() -> (context)) | (^(_ARLike) -> (context)))
            if c.arity == 0
              deprecator.warn(
                '`:context` will be removed in 0.5.0. Use `:destroy` option instead. ' \
                'for example, `context: -> { foo? ? :destroy : :save }` ' \
                'is replaced by `destroy: -> { foo? }`.',
              )

              # @type var c: ^() -> (context)
              -> { c.call == :destroy }
            else
              deprecator.warn(
                '`:context` will be removed in 0.5.0. Use `:destroy` option instead. ' \
                'for example, `context: ->(model) { model.bar? ? :destroy : :save }` ' \
                'is replaced by `destroy: ->(model) { foo? }`.',
              )

              # @type var c: ^(_ARLike) -> (context)
              ->(model) { c.call(model) == :destroy }
            end
          elsif %i[save destroy].include?(c)
            deprecator.warn(
              '`:context` will be removed in 0.5.0. Use `:destroy` option instead. ' \
              "for example, `context: #{c.inspect}` is replaced by `destroy: #{(c == :destroy).inspect}`.",
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
      d = destroy
      if d.is_a?(Proc)
        if d.arity == 0
          # @type var d: ^() -> (bool | context)
          d.call
        else
          # @type var d: ^(_ARLike) -> (bool | context)
          d.call(model)
        end
      elsif d.is_a?(Symbol)
        owner.send(d)
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
      return false unless __raw_model == other.__raw_model
      return false unless __destroy == other.__destroy

      true
    end

    # Returns a model instance of raw, but it should
    # be noted that application developers are not expected to use this interface.
    #
    # @return [Object] raw model instance
    def __raw_model = model

    # Returns a model instance of raw, but it should
    # be noted that application developers are not expected to use this interface.
    #
    # @return [Boolean] raw destroy instance
    # @return [Proc] raw destroy instance
    def __destroy = destroy

    private

    attr_reader :owner, :model, :destroy

    def deprecator
      if ActiveRecord.respond_to?(:deprecator)
        ActiveRecord.deprecator
      else # for rails 7.0.x or lower
        ActiveSupport::Deprecation
      end
    end
  end
end
