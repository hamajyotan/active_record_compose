# frozen_string_literal: true

# steep:ignore:start
# @private
module ActiveRecordCompose
  module Validations
    module CircularReferenceDetection
      refine self do
        def detect_circular_reference(targets = [])
          raise CircularReferenceDetected if targets.include?(object_id)

          targets += [ object_id ]
          models.select { _1.is_a?(CircularReferenceDetection) }.each do |m|
            m.detect_circular_reference(targets)
          end
        end
      end
    end
  end
end
# steep:ignore:end
