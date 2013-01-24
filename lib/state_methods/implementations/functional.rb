module StateMethods
  module Implementations
    class Functional < StateMethods::Factory

      def set(klass, method_name, state, &block)
        ::StateMethods::MethodUtils.define_instance_method(klass, [method_name, state], &block)
      end

      def get(instance, method_name, state, *args)
        partition = instance.class._state_partition_for(@state_accessor)
        keys = partition.ancestors(state)
        if m = ::StateMethods::MethodUtils.find_defined(instance, method_name, *keys)
          instance.send(m, *args)
        else
          raise Undefined
        end
      end

    end
  end
end
