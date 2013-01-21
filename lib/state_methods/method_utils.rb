module StateMethods

  module MethodUtilsClassMethods

    def find_defined(object, name, *keys)
      if key = keys.shift
        m = method_name(name, key)
        if object.respond_to?(m)
          m
        else
          find_defined(object, name, *keys)
        end
      end
    end

    def define_class_method(klass, name, val=nil, &block)
      name = method_name(*name) if name.is_a?(Array)
      (class << klass; self end).send(:define_method, name, &block || -> { val } )
    end

    def define_instance_method(klass, name, val=nil, &block)
      name = method_name(*name) if name.is_a?(Array)
      klass.send(:define_method, name, &block)
    end

    def method_name(*keys)
      :"__#{keys.map(&:to_s).join('__')}"
    end

    def call(object, keys)
      object.send(method_name(*keys))
    rescue NoMethodError
      nil
    end

    # def set(klass, keys, val=nil, &block)
    # m = method_name(*keys)
    # (class << klass; self end).class_eval do
    # klass.instance_eval do
    # (class << klass; self end).instance_eval do
    #   define_method m do |*args|
    #     val
    #   end
    # end
    # define_class_method(klass, method_name(*keys)) { val }
    # end

  end

  module MethodUtils
    extend MethodUtilsClassMethods
  end

end
