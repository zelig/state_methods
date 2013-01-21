require "state_methods/partition"
require "active_support/core_ext/class/attribute_accessors"

module StateMethods

  class CannotOverrideError < StandardError; end
  class PartitionNotFound < StandardError; end

  module Base


    def self.included(base)
      base.extend StateMethodsClassMethods
      base.class_eval do
        include StateMethodsInstanceMethods
      end
    end

    module StateMethodsInstanceMethods
    end

    module StateMethodsClassMethods

      def new_state_partition(*spec)
        ::StateMethods::Partition.new(*spec)
      end

      def set_state_partition(state_accessor, partition_name, spec)
        orig = get_state_partition(state_accessor, partition_name)
        begin
          new_partition = new_state_partition(spec, orig)
          ::StateMethods::MethodUtils.define_class_method(self, [:partition, state_accessor, partition_name], new_partition)
          ::StateMethods::MethodUtils.define_instance_method(self, :"#{state_accessor}_is_a?") do |s|
            current_state = send(state_accessor)
            current_state == s or
            self.class.get_state_partition(state_accessor, partition_name).ancestors(current_state||:*).include?(s)
          end
        rescue ArgumentError
          raise CannotOverrideError
        end
      end

      def get_state_partition(*args)
        ::StateMethods::MethodUtils.call(self, [:partition, *args])
      end

      def state_method(method_name, state_accessor, partition_name)
        get_state_partition(state_accessor, partition_name) or raise PartitionNotFound

        ::StateMethods::MethodUtils.define_class_method(self, method_name) do |*states, &block|
          states.each do |s|
            ::StateMethods::MethodUtils.define_instance_method(self, [method_name, s], &block)
          end
        end

        ::StateMethods::MethodUtils.define_instance_method(self, method_name) do |*args|
          keys = self.class.get_state_partition(state_accessor, partition_name).ancestors(send(state_accessor)||:*)
          if m = ::StateMethods::MethodUtils.find_defined(self, method_name, *keys)
            send(m, *args)
          end
        end

      end


    end

  end
end
