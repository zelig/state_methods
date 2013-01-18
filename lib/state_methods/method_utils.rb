module StateMethods

  module MethodUtils

    def method_name(*keys)
      :"__#{keys.map(&:to_s).join('__')}"
    end

    def get(klass, keys)
      klass.send(method_name(*keys))
    rescue NoMethodError
      nil
    end

    def set(klass, keys, val)
      m = method_name(*keys)
      (class << klass; self end).class_eval do
        define_method m do |*args|
          val
        end
      end
    end

  end

end
