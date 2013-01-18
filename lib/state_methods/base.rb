require "state_methods/partition"
require "active_support/core_ext/class/attribute_accessors"

module StateMethods

  class CannotOverrideError < StandardError; end

  module Base


    def self.included(base)
      base.extend StateMethodsClassMethods
      base.class_eval do
        include StateMethodsInstanceMethods
      end
    end

    module StateMethodsClassMethods

      def new_state_partition(*spec)
        ::StateMethods::Partition.new(*spec)
      end

      def set_state_partition(state, partition, spec)
        orig = get_state_partition(state, partition)
        begin
          new_partition = new_state_partition(spec, orig)
          ::StateMethods.set(self, [:partition, state, partition], new_partition)
        rescue
          raise CannotOverrideError
        end
      end

      def get_state_partition(*args)
        ::StateMethods.get(self, [:partition, *args])
      end

    end

    module StateMethodsInstanceMethods
    end

  end
end
