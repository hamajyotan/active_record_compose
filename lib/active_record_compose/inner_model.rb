# frozen_string_literal: true

require 'active_support/core_ext/object'

module ActiveRecordCompose
  class InnerModel
    # @param model [Object] the model instance.
    # @param context [Symbol] :save or :destroy
    # @param context [Proc] proc returning either :save or :destroy
    def initialize(model, context: :save)
      @model = model
      @context = context
    end

    delegate :errors, to: :model

    # @return [Symbol] :save or :destroy
    def context #: ActiveRecordCompose::context
      c = @context
      ret =
        if c.is_a?(Proc)
          if c.arity == 0
            # @type var c: ^() -> context
            c.call
          else
            # @type var c: ^(_ARLike) -> context
            c.call(model)
          end
        else
          c
        end
      ret.presence_in(%i[save destroy]) || :save
    end

    # Execute save or destroy. Returns true on success, false on failure.
    # Whether save or destroy is executed depends on the value of context.
    #
    # @return [Boolean] returns true on success, false on failure.
    def save
      case context
      when :destroy
        model.destroy
      else
        model.save
      end
    end

    # Execute save or destroy. Unlike #save, an exception is raises on failure.
    # Whether save or destroy is executed depends on the value of context.
    #
    def save!
      case context
      when :destroy
        model.destroy!
      else
        model.save!
      end
    end

    # @return [Boolean]
    def invalid?
      case context
      when :destroy
        false
      else
        model.invalid?
      end
    end

    # @return [Boolean]
    def valid? = !invalid?

    # Returns true if equivalent.
    #
    # @param [Object] other
    # @return [Boolean]
    def ==(other)
      return false unless self.class == other.class
      return false unless __raw_model == other.__raw_model # steep:ignore
      return false unless context == other.context

      true
    end

    # Returns a model instance of raw, but it should
    # be noted that application developers are not expected to use this interface.
    #
    # @return [Object] raw model instance
    def __raw_model = model

    private

    attr_reader :model
  end
end
