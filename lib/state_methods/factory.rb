require "state_methods/partition"

module StateMethods

  class Factory

    def initialize(klass, state_accessor, state_method_options)
      @klass = klass
      @state_accessor = state_accessor
      @partition = state_method_options[:partition]
      @lock_state = state_method_options[:lock_state]
      @keys = [state_accessor]
      init
    end

    def declared?(state)
      @partition.declared?(state)
    end

    def init
    end

    def check(method_name, force = false)
    end

    def factory_for(klass)
      if klass == @klass
        self
      else
        klass._state_method_factory_for(*@keys)
      end
    end

    def declare(method_name)
      this = self
      ::StateMethods::MethodUtils.define_metaclass_method(@klass, method_name) do |*states, &block|
        factory = this.factory_for(self)
        states.each do |state|
          raise UndeclaredState unless factory.declared?(state)
          factory.set(self, method_name, state, &block)
        end
      end
      check(method_name, force=true)

      state_accessor = @state_accessor
      lock_state = @lock_state
      ::StateMethods::MethodUtils.define_method(@klass, method_name) do |*args|
        state = send(state_accessor) || :*
        factory = this.factory_for(self.class)
        begin
          base, func = factory.get(self, method_name, state)
          if lock_state
            ::StateMethods::MethodUtils.define_metaclass_method(self, method_name) do |*args|
              base.send(func, *args)
            end
          end
          base.send(func, *args) if base.respond_to?(func)
        rescue Undefined
          return nil
        end
      end

    end

  end

end
