module StateMethods
  module Implementations
    class Functional < StateMethods::Factory

      def set(klass, method_name, state, &block)
        ::StateMethods::MethodUtils.define_method(klass, [method_name, state], &block)
      end

      def get(instance, method_name, state)
        partition = instance.class.state_method_options_for(@state_accessor)[:partition]
        keys = partition.ancestors(state)
        if m = ::StateMethods::MethodUtils.find_defined(instance, method_name, *keys)
          [instance, m]
        else
          raise Undefined
        end
      end

    end
  end
end
