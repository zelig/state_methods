# StateMethods


Suppose you wish to define  method which executes code dependent on a state of an instance:

```ruby
def state_method(*args)
  case state
  when :a then ...
  when :b then ...
  ...
end
```

Now suppose you would like this generic behaviour (say coming from an included module or subclass) but would like to override it in some states. You need to rewrite the whole function and fall back to super. 

This implementation of state dependence makes it unavoidable that an instance invocation matches the state against all cases especially if there is many of them and falling back to super makes it worse. Apart from this, while explicit, the case statements may be too verbose.

The [state machine gem](https://github.com/pluginaweek/state_machine) offers such state-driven instance behaviour:

```ruby
class Vehicle
  # ...
  state_machine :state, :initial => :parked do
    
    #... describe transitions

    state :parked do
      def speed
        0
      end
    end

    state :idling, :first_gear do
      def speed
        10
      end
    end

    state all - [:parked, :stalled, :idling] do
      def moving?
        true
      end
    end

    state :parked, :stalled, :idling do
      def moving?
        false
      end
    end
  end
end
```

- Call state-driven behavior that's undefined for the state raises a NoMethodError
- does not allow for open ended state values
- order-dependent unsafe specification, but 'all' does not override any specific state, behaves as default

- allow partitions and declarative order-independent specification
- open ended values 
- extension via inheritance

class Model


source("sm.rb")
vehicle = Vehicle.new           # => #<Vehicle:0xb7cf4eac @state="parked", @seatbelt_on=false>
vehicle.state                   # => "parked"
vehicle.speed                   # => 0
vehicle.moving?                 # => false

vehicle.ignite                  # => true
vehicle.state                   # => "idling"
vehicle.speed                   # => 0
vehicle.moving?                 # => false

vehicle.shift_up                # => true
vehicle.state                   # => "first_gear"
vehicle.speed                   # => 10
vehicle.moving?                 # => true

## Installation

Add this line to your application's Gemfile:

    gem 'state_methods'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install state_methods

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
