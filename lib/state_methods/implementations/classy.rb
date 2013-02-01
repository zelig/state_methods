require 'active_support/core_ext/class/attribute.rb'

module StateMethods
  module Implementations
    class Proxy
      class_attribute :_keys

      def initialize(base)
        @base = base
      end

      def base_proxy_for(state)
        @base.class._state_method_factory_for(*_keys).class_for(state).new(@base)
      end

    end

    class Classy < StateMethods::Factory

      def init
        proxy_const = [:proxy, @state_accessor].join('_').camelize
        @proxy = if Object.const_defined?(proxy_const)
          proxy_const.constantize
        else
          keys = @keys
          make!(proxy_const, Proxy) do
            self._keys = keys
          end
        end

        @superclass = @klass.superclass
        if @superclass.respond_to?(:_state_method_factory_for)
          begin
            @super_proxy = @superclass._state_method_factory_for(*@keys)
          rescue PartitionNotFound
          end
        end
        @partition.index.each do |state, ancestors|
          superstate = ancestors[1]
          make(state, superstate)
        end
      end

      def check(method_name, force = false)
        ok = begin
          Proxy.new(nil).send(method_name)
          false
        rescue NoMethodError
          true
        rescue
          false
        end
        unless ok
          if force
            @proxy.send(:undef_method, method_name)
          else
            raise ArgumentError, "method '#{method_name}' won't work"
          end
        end
        # set(@klass, method_name, :all) { raise Undefined }
      end

      def set(klass, method_name, state, &block)
        # klass.should == @klass
        # klass = begin
        #   class_for(state)
        # rescue NameError
        #   raise UndeclaredState
        # end
        class_for(state).send(:define_method, method_name) do |*args|
          @base.instance_exec(*args, &block)
        end
      end

      def get(instance, method_name, state)
        # instance.class.should == @klass
        klass = nil
        [state, :*, :all].find do |s|
          begin klass = class_for(s)
          rescue NameError
          end
        end
        if klass
          base = klass.new(instance)
          [base, method_name]
          # if base.respond_to?(method_name)
          # base.method(method_name)
          #   # base.send(method_name, *args)
        else
          raise Undefined
        end
        # end
      end

      def state_superclass_for(state)
        begin
          @super_proxy && @super_proxy.class_for(state)
        rescue NameError
        end
      end

      def class_for(state)
        const_for(state).constantize
      end

      def const_for(state)
        [@klass, @state_accessor, state].join('_').sub('*','star').camelize
      end

      def make!(const, state_superclass, &block)
        new_class = Class.new(state_superclass,&block)
        Object.send(:remove_const, const) if Object.const_defined?(const)
        Object.const_set(const, new_class, true)
        new_class
      end

      def make(state, superstate)
        const = const_for(state)
        unless Object.const_defined?(const)
          if state_superclass = state_superclass_for(state)
            make!(const, state_superclass)
          elsif superstate
            make!(const, @proxy) do
              define_method :method_missing do |method_name, *args, &block|
                proxy = base_proxy_for(superstate)
                proxy.send(method_name, *args, &block)
              end
              define_method :respond_to? do |method_name, include_private = false|
                super(method_name) or
                base_proxy_for(superstate).respond_to?(method_name)
              end
            end
          else
            make!(const, @proxy)
          end
        end
        const.constantize
      end

    end

  end
end
