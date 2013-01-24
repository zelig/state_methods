require "state_methods/partition"

module StateMethods

  class Factory

    def initialize(klass, state_accessor, partition)
      @klass = klass
      @state_accessor = state_accessor
      @partition = partition
      @keys = [state_accessor]
      init
    end

    def init
    end

    def check(method_name, force = false)
    end

    def factory_for(klass)
      self
    end

    def declare(method_name)
      this = self
      ::StateMethods::MethodUtils.define_class_method(@klass, method_name) do |*states, &block|
        factory = this.factory_for(self)
        states.each do |state|
          factory.set(self, method_name, state, &block)
        end
      end
      check(method_name, force=true)

      state_accessor = @state_accessor
      ::StateMethods::MethodUtils.define_instance_method(@klass, method_name) do |*args|
        state = send(state_accessor) || :*
        factory = this.factory_for(self.class)
        begin
          factory.get(self, method_name, state, *args)
        rescue Undefined
          nil
        end
      end

    end

  end

end
