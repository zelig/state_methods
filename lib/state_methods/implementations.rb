require "active_support/core_ext/class/attribute_accessors"
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/string/inflections.rb'
require "state_methods/factory"
require "state_methods/implementations/functional"
require "state_methods/implementations/classy"

module StateMethods

  class CannotOverrideError < ArgumentError; end
  class UndeclaredState < ArgumentError; end
  class PartitionNotFound < StandardError; end
  class Undefined < StandardError; end
  IMPLEMENTATION = 'Functional'
  # IMPLEMENTATION = 'Classy'
  mattr_accessor :implementation
  @@implementation = IMPLEMENTATION

  module Implementations

    def self.included(base)
      base.class_eval do
        class_attribute :_state_partitions
        self._state_partitions = {}
        include InstanceMethods
      end
      base.extend ClassMethods
    end

    module InstanceMethods
    end

    module ClassMethods

      def state_method(method_name, state_accessor, options = {})
        raise ArgumentError, "'#{method_name}' already defined" if respond_to?(method_name)
        factory = _state_method_factory_for(state_accessor, options)
        factory.declare(method_name)
      end

      def _state_method_factory_for(state_accessor, options = {})
        @_state_method_factories ||= {}
        factory = @_state_method_factories[state_accessor]
        unless factory
          partition = _state_partition_for(state_accessor, options) or raise(PartitionNotFound)
          factory_class = begin
            implementation = options[:implementation] || ::StateMethods.implementation
            "::StateMethods::Implementations::#{implementation}".constantize
          rescue NameError
            raise ArgumentError, "implementation '#{implementation}' not found"
          end
          factory = @_state_method_factories[state_accessor] ||= factory_class.new(self, state_accessor, partition)
        end
        factory
      end

      def _state_partition_for(state_accessor, options = {})
        orig = _state_partitions[state_accessor]
        extension = options[:extend]
        spec = options[:partition]
        if orig
          raise ArgumentError, "partition for '#{state_accessor}' already defined" if spec
        else
          raise ArgumentError, "partition for '#{state_accessor}' not defined" if extension
        end
        spec ||= extension
        return orig unless spec
        raise ArgumentError, "partition for '#{state_accessor}' should be set before state_method calls within a class" if
        @_state_method_factories && @_state_method_factories[state_accessor]
        begin
          new_partition = ::StateMethods::Partition.new(spec, orig)
          ::StateMethods::MethodUtils.define_instance_method(self, :"#{state_accessor}_is_a?") do |s|
            current_state = send(state_accessor)
            current_state == s or
            new_partition.ancestors(current_state||:*).include?(s)
          end
          self._state_partitions = _state_partitions.merge(state_accessor => new_partition)
          new_partition
        rescue ::StateMethods::DuplicateStateError => exc
          if orig
            raise CannotOverrideError, exc.to_s
          else
            raise exc
          end
        end
      end
    end

  end
end
