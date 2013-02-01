module StateMethods
  class DuplicateStateError < ArgumentError; end

  class Partition
    def ==(p)
      index == p.index
    end

    def initialize(partition = {}, ancestor = nil)
      partition = {} if partition == [] || partition == :default
      partition = { :all => partition } unless partition.is_a?(Hash) && (ancestor || partition[:all] || partition['all'])
      @index, @leaves = process(partition, ancestor ? ancestor.index.dup : {}, ancestor ? nil : [], [])
    end

    def declared?(s)
      index[s.to_sym]
    end

    def ancestors(s)
      s = s.to_sym
      # unsafe to prepend s but it catches undeclared state
      index[s] || (index[:*] && [s, *(index[:*])]) || [s, :all]
    end

    def index
      @index
    end

    def leaves
      @leaves
    end

    protected

    def process(partition, index, prefix, leaves)
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
        when {} then leaves << k
        when Hash then process(v, index, new_prefix, leaves)
        when Symbol, String then process({ v => {} }, index, new_prefix, leaves)
        when Array then v.each { |e| process({ e => {} }, index, new_prefix, leaves) }
        else
          raise ArgumentError, "invalid partition specification for '#{k}' => '#{v.inspect}'"
        end
      end
      # puts index
      [index, leaves]
    end

  end
end
