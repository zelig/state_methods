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
        class_attribute :state_method_options
        self.state_method_options = {}
        include InstanceMethods
      end
      base.extend ClassMethods
    end

    module InstanceMethods
    end

    module ClassMethods

      def state_method(method_name, state_accessor, options = {})
        raise ArgumentError, "'#{method_name}' already defined" if respond_to?(method_name)
        method_options = {}
        method_options[:arity] = options.delete(:arity)
        factory = _state_method_factory_for(state_accessor, options)
        factory.declare(method_name, method_options)
      end

      def _state_method_factory_for(state_accessor, options = {})
        @_state_method_factories ||= {}
        factory = @_state_method_factories[state_accessor]
        if factory
          raise ArgumentError, "state_methods for '#{state_accessor}' already set up" unless options.empty?
        else
          factory_options = state_method_options_for(state_accessor, options) or raise(PartitionNotFound)
          factory_class = begin
            implementation = factory_options[:implementation] || ::StateMethods.implementation
            "::StateMethods::Implementations::#{implementation}".constantize
          rescue NameError
            raise ArgumentError, "implementation '#{implementation}' not found"
          end
          factory = @_state_method_factories[state_accessor] ||= factory_class.new(self, state_accessor, factory_options)
        end
        factory
      end

      def state_method_options_for(state_accessor, options = {})
        orig_options = state_method_options[state_accessor]
        return orig_options if options.empty?
        extension = options.delete(:extend)
        spec = options[:partition]
        if orig_options
          raise ArgumentError, "partition for '#{state_accessor}' already defined" unless options.empty?
        else
          raise ArgumentError, "partition for '#{state_accessor}' not defined" if extension
        end
        spec ||= extension
        raise ArgumentError, "state method options for '#{state_accessor}' should be set before state_method calls within a class" if
        @_state_method_factories && @_state_method_factories[state_accessor]
        partition = (orig_options[:partition] if orig_options)
        if spec
          begin
            partition = ::StateMethods::Partition.new(spec, partition)
          rescue ::StateMethods::DuplicateStateError => exc
            if orig_options
              raise CannotOverrideError, exc.to_s
            else
              raise exc
            end
          end
        end
        unless orig_options
          define_method(:"#{state_accessor}_is_a?") do |s|
            current_state = send(state_accessor)
            current_state == s or
            partition.ancestors(current_state||:*).include?(s)
          end
        end
        new_options = options.merge(:partition => partition)
        self.state_method_options = state_method_options.merge(state_accessor => new_options)
        new_options
      end
    end

  end
end
