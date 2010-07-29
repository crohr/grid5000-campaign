class Numeric

  def K;    self*10**3;     end
  def M;    self*10**6;     end
  def G;    self*10**9;     end
  def T;    self*10**12;    end
  
  { 
    :KiB => 1024,
    :MiB => 1024**2, 
    :GiB => 1024**3, 
    :TiB => 1024**4,
    :KB  => 1.K/1.024, 
    :MB  => 1.M/1.024**2, 
    :GB  => 1.G/1.024**3, 
    :TB  => 1.T/1.024**4
  }.each do |method, multiplier|
    define_method(method) do
      self*multiplier
    end
  end
  
  def seconds
    self
  end
  
  def minutes
    seconds*60
  end
  
  def hours
    minutes*60
  end
  
  def days
    hours*24
  end
end

class Fixnum  
  def instances
    self
  end
end

class Hash
  def symbolize_keys
    Hash[map{ |key,value| 
      [(key.to_sym rescue key) || key, value] 
    }]
  end
end

class Symbol
  
  def eq(value)
    procify(value, :==)
  end
  
  def gt(value)
    procify(value, :>=)
  end
  
  def lt(value)
    procify(value, :<=)
  end
  
  def in(range_or_array)
    case range_or_array
    when Range
      procify(range_or_array, :include?)
    when Array
      range_or_array = [range_or_array].flatten
      procify(range_or_array, :include?)
    else
      raise ArgumentError, "#{range_or_array.inspect} is a #{range_or_array.class}. Expected Range or Array."
    end
  end
  
  def like(*regexps)
    regexps = [regexps].flatten
    non_regexp = regexps.find{|r| !r.kind_of?(Regexp)}
    if non_regexp.nil?
      Proc.new { |hash| 
        hash.has_key?(key) && regexps.find{|regexp|
          regexp.match(hash[key])
        }
      }
    else
      raise ArgumentError, "#{non_regexp.inspect} is not a regular expression."
    end
  end
  
  def conditions
    @conditions ||= []
  end
  
  def with(expression)
    @conditions = []
    @conditions << add_condition(expression)
    self
  end
  
  def and(expression)
    if conditions.empty?
      raise ArgumentError, "You must call :with at least once before :and."
    else
      @conditions << add_condition(expression)
      self
    end
  end
  
  def key
    @key ||= self.to_s
  end
  
  private
  def procify(value, method)
    Proc.new { |hash| 
      if hash.has_key?(key)
        property = hash[key]
        case value
        when Range, Array
          value.send(method, property)
        else
          property.send(method, value)
        end
      else
        false
      end
    }
  end
  
  def add_condition(expression)
    Proc.new { |node| 
      node.has_key?(key) && [node[key]].flatten.find{ |value|
        expression.call(value)
      }
    }
  end
end
