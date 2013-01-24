module StateMethods
  class DuplicateStateError < ArgumentError; end

  class Partition
    def ==(p)
      index == p.index
    end

    def initialize(partition = {}, ancestor = nil)
      partition = {} if partition == [] || partition == :default
      partition = { :all => partition } unless partition.is_a?(Hash) && (ancestor || partition[:all] || partition['all'])
      @index = process(partition, ancestor ? ancestor.index.dup : {}, ancestor ? nil : [])
    end

    def ancestors(s)
      s = s.to_sym
      # unsafe to prepend s but it catches undeclared state
      index[s] || (index[:*] && [s, *(index[:*])]) || [s, :all]
    end

    def index
      @index
    end

    protected

    def process(partition, index, prefix)
      partition.each do |k, v|
        k = k.to_sym
        orig_prefix = index[k]
        new_prefix = nil
        if prefix
          new_prefix = [k, *prefix]
          if orig_prefix
            raise DuplicateStateError, k unless new_prefix == orig_prefix
          end
        else
          new_prefix = orig_prefix || [k, :all]
        end
        index[k] = new_prefix
        case v
        when Hash then process(v, index, new_prefix) unless v.empty?
        when Symbol, String then process({ v => {} }, index, new_prefix)
        when Array then v.each { |e| process({ e => {} }, index, new_prefix) }
        else
          raise ArgumentError, "invalid partition specification for '#{k}' => '#{v.inspect}'"
        end
      end
      # puts index
      index
    end

  end
end
