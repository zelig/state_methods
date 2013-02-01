require 'spec_helper'
require 'state_methods'

class Object
  @_consts_to_remove = []
  class << self
    alias :orig_const_set :const_set
  end
  def self.const_set(const, new_class, remove = false)
    @_consts_to_remove << const if remove
    orig_const_set(const, new_class)
  end
  def self.remove_consts_to_remove!
    @_consts_to_remove.each { |c| remove_const(c) }
    @_consts_to_remove = []
  end
end

describe "state methods" do

  after(:each) do
    Object.remove_consts_to_remove!
  end

  def state_partition!(*spec)
    ::StateMethods::Partition.new(*spec)
  end

  def state_method_options!(*spec)
    { :partition => state_partition!(*spec) }
  end

  def state_partition
    @state_partition
  end

  class TestModel
    include ::StateMethods
    def state
      @state
    end
    def state=(a)
      @state = a
    end
    def state!(a)
      self.state = a
      self
    end
    def other_state
      @other_state
    end
    def other_state=(a)
      @other_state = a
    end
    def other_state!(a)
      self.other_state = a
      self
    end
  end

  def model_class
    @model_class
  end

  def model_class!
    @model_class = Class.new(TestModel)
    const = 'TestModel1'
    Object.send(:remove_const, const) if Object.const_defined?(const)
    Object.const_set(const, @model_class)
    @model_class
  end

  def model_subclass
    @model_subclass
  end

  def model_subclass!
    @model_subclass = Class.new(model_class)
    const = 'TestModel2'
    Object.send(:remove_const, const) if Object.const_defined?(const)
    Object.const_set(const, @model_subclass)
    @model_subclass
  end

  def model!
    @model = (model_subclass || model_class).new
  end

  def model
    @model
  end

  before(:each) do
    model_class!
  end

  describe "partitions" do
    it "default partition" do
      partition = state_partition!(:default)
      state_partition!(:all => []).should == partition
      state_partition!({}).should == partition
      state_partition!().should == partition
      state_partition!([]).should == partition
    end

    it "partition can mix string/symbol" do
      partition = state_partition!(:a => :b)
      state_partition!(:a => 'b').should == partition
      state_partition!('a' => 'b').should == partition
      state_partition!('a' => :b).should == partition
    end

    it "partition does not allow duplicate states" do
      lambda { state_partition!(:a => 'a') }.should raise_error(::StateMethods::DuplicateStateError, "a")
    end

    it "partition does not invalid state specification" do
      lambda { state_partition!(:a => nil) }.should raise_error(ArgumentError, "invalid partition specification for 'a' => 'nil'")
    end
  end

  describe "state option declarations are allowed" do

    it "with state and no option they retrieve correct partition" do
      model_class.state_method_options_for(:state).should be_nil
      model_class.state_method_options_for(:state, :partition => { :a => :b })
      model_class.state_method_options_for(:state).should == state_method_options!(:a => :b)
    end

    it "with state, partition option and retrieve correct partition" do
      model_class.state_method_options_for(:state, :partition => { :a => :b }).should == state_method_options!(:a => :b)
    end

    it "with partition option only once for a state accessor" do
      model_class.state_method_options_for :state, :partition => { :a => :b }
      lambda { model_class.state_method_options_for :state, :partition => { :a => :b } }.should raise_error(ArgumentError, "partition for 'state' already defined")
    end

    it "with extend option only if they extend earlier declarations" do
      model_class.state_method_options_for :state, :partition => { :a => :b }
      lambda { model_class.state_method_options_for :state, :extend => { :c => :a } }.should raise_error(::StateMethods::CannotOverrideError, "a")
    end

    it "with extend option only if partition is already defined for the state accessor" do
      lambda { model_class.state_method_options_for :state, :extend => { :a => :b } }.should raise_error(ArgumentError, "partition for 'state' not defined")
    end

    it "with extend option after state accessor is defined" do
      model_class.state_method_options_for :state, :partition => { :a => :b }
      model_class.state_method_options_for(:state, :extend => { :a => :c }).should == state_method_options!(:a => [:b, :c])
    end

    it "and are inherited" do
      model_class.state_method_options_for :state, :partition => { :a => :b }
      model_subclass!.state_method_options_for(:state).should == state_method_options!(:a => :b)
    end

    it "and are extensible in subclass, not overwritten in superclass" do
      model_class.state_method_options_for :state, :partition => { :a => :b }
      model_subclass!.state_method_options_for :state, :extend => { :a => :c }
      model_subclass.state_method_options_for(:state).should == state_method_options!(:a => [:b, :c])
      model_class.state_method_options_for(:state).should == state_method_options!(:a => :b)
    end

    it "and define state_is_a? instance method" do
      model_class.state_method_options_for :state, :partition => { :a => [:b, :c] }
      model!.state!(:b)
      model.state_is_a?(:b).should be_true
      model.state_is_a?(:a).should be_true
      model.state_is_a?(:all).should be_true
      model.state_is_a?(:c).should be_false
      model.state_is_a?(:none).should be_false
    end

  end

  shared_examples_for 'implementation' do

    describe "state method declarations" do

      # before(:each) do
      #   model_class.state_method_options_for :state, :partition => :default
      # end

      it "take state method, partition option as arguments" do
        model_class.state_method :test, :state, :partition => :default
      end

      it "raise PartitionNotFound error if partition is not set up" do
        lambda { model_class.state_method :test, :state }.should raise_error(::StateMethods::PartitionNotFound)
      end

      it "raise PartitionNotFound error if partition is not set up" do
        model_class.state_method :test, :state, :partition => :default
        lambda { model_class.state_method :test, :state }.should raise_error(ArgumentError, "'test' already defined")
      end

      it "should define class and instance method" do
        model_class.state_method :test, :state, :partition => :default
        model_class.should respond_to(:test)
        model!.should respond_to(:test)
      end

    end

    describe "state method behaviour" do

      context "single method and state" do

        before(:each) do
          model_class.state_method :test, :state, :partition => [:a, :b]
          model!.state!(:none)
        end

        shared_examples_for 'singular specification' do
          it "#test -> nil if none set if state=nil" do
            model.state!(nil).state.should be_nil
            model.test.should be_nil
          end

          it "#test -> 1 if all set to 1 if state=nil" do
            model_class.test(:all) { 1 }
            model.state!(nil).state.should be_nil
            model.test.should == 1
          end

          it "#test -> 1 if all set to 1 if state=a" do
            model_class.test(:all) { 1 }
            model.state!(:a).state.should == :a
            model.test.should == 1
          end
        end

        shared_examples_for 'same-class specification' do

          before(:each) do
            model!.state!(:none)
          end

          include_examples 'singular specification'

          it "#test -> 1 if all set to 0 and a set to 1 if state=a" do
            model_class.test(:all) { 0 }
            model_class.test(:a) { 1 }
            model.state!(:a).state.should == :a
            model.test.should == 1
          end

          it "#test -> 0 if all set to 0 and a set to 1 if state=b" do
            model_class.test(:all) { 0 }
            model_class.test(:a) { 1 }
            model.state!(:b).state.should == :b
            model.test.should == 0
          end

          it "#test -> 1 if a set to 1 and THEN all set to 0  if state=a" do
            model_class.test(:a) { 1 }
            model_class.test(:all) { 0 }
            model.state!(:a).state.should == :a
            model.test.should == 1
          end
        end

        context "with same-class specification" do

          include_examples 'same-class specification'

        end

        context "with multiple state_methods with multiple specification" do

          before(:each) do
            model_class.state_method :other_test, :other_state, :partition => :default
            model_class.other_test(:all) { 2 }
            model!.other_state!(:a)
            model!.state!(:none)
          end

          include_examples 'same-class specification'

        end


        context "with specification across superclass and subclass" do

          before(:each) do
            model_subclass!
            model!.state!(:none)
          end

          include_examples 'singular specification'

          it "#test -> 1 if all set to 0 and a set to 1 (in subclass) if state=a" do
            model_class.test(:all) { 0 }
            model_subclass.test(:a) { 1 }
            model.state!(:a).state.should == :a
            model.test.should == 1
          end

          it "#test -> 0 if all set to 0 and a set to 1 (in subclass) if state=b" do
            model_class.test(:all) { 0 }
            model_subclass.test(:a) { 1 }
            model.state!(:b).state.should == :b
            model.test.should == 0
          end

          it "#test -> 1 if a set to 1 and THEN all set to 0 (in subclass) if state=a" do
            model_class.test(:a) { 1 }
            model_subclass.test(:all) { 0 }
            model.state!(:a).state.should == :a
            model.test.should == 1
          end

          it "#test -> 1 if all set to 0 (in subclass) and a set to 1 if state=a" do
            model_subclass.test(:all) { 0 }
            model_class.test(:a) { 1 }
            model.state!(:a).state.should == :a
            model.test.should == 1
          end

          it "#test -> 0 if all set to 0 (in subclass) and a set to 1 if state=b" do
            model_subclass.test(:all) { 0 }
            model_class.test(:a) { 1 }
            model.state!(:b).state.should == :b
            model.test.should == 0
          end

          it "#test -> 1 if a set to 1 (in subclass) and THEN all set to 0  if state=a" do
            model_subclass.test(:a) { 1 }
            model_class.test(:all) { 0 }
            model.state!(:a).state.should == :a
            model.test.should == 1
          end

          it "#test -> 0 if a set to 1 (in subclass) and all set to 0  if state=a in superclass" do
            model_subclass.test(:a) { 1 }
            model_class.test(:all) { 0 }
            m = model_class.new.state!(:a)
            m.state.should == :a
            m.test.should == 0
          end

        end
      end

      context "multiple states and state sets" do

        before(:each) do
          model_class.state_method :test, :state, :partition => { :ab => [:a, :b] }
          model_subclass!.state_method_options_for :state, :extend => { :cd => [:c, :d], :ab => { :b => [:b0, :b1] } }
          model!.state!(:none)
        end

        it "inherit suprestate spec from superclass even if state is only explicit in subclass partition" do
          model_class.test(:b) { 1 }
          model_subclass.test(:ab) { 0 }
          model.state!(:b0).state.should == :b0
          model.test.should == 1
        end

        it "specification block is executed in model instance scope" do
          model_class.test(:all) { state }
          model.state!(:a).test.should == :a
          model.state!(:c).state.should == :c
          model.test.should == :c
        end

        it "setting a method on an undeclared state raises StateMethods::UndeclaredState" do
          lambda { model_class.test(:c) { :c } }.should raise_error(StateMethods::UndeclaredState)
        end

        it "specification block arguments are passed correctly" do
          model_class.test(:a) { |first, second, *rest| "state: #{state}, first: #{first}, second: #{second}, rest: #{rest.join(', ')}" }
          model.state!(:a).state.should == :a
          model.test(1, 2, 3, 4).should == "state: a, first: 1, second: 2, rest: 3, 4"
        end

        include_examples 'singular specification'

      end

      context "with option :lock_state => true" do

        before(:each) do
          model_class.state_method :test, :state, :lock_state => true, :partition => [:a, :b]
          model!.state!(:none)
        end

        it "state method call locks the instance to the current state (state-specific method is memoized)" do
          model_class.test(:a) { :a }
          model_class.test(:b) { :b }
          model.state!(:b)
          model.state!(:a).test.should == :a
          model.state!(:b).state.should == :b
          model.test.should == :a
        end

      end
      context "with option :lock_state => true" do

        before(:each) do
          model_class.state_method :test, :state, :lock_state => false, :partition => [:a, :b]
          model!.state!(:none)
        end

        it "state method call does not lock the instance to the current state (state-specific method is not memoized)" do
          model_class.test(:a) { :a }
          model_class.test(:b) { :b }
          model.state!(:b)
          model.state!(:a).test.should == :a
          model.state!(:b).state.should == :b
          model.test.should == :b
        end

      end

    end
  end

  context "functional implementation" do
    include_examples 'implementation'
  end

  context "classy implementation" do
    before(:all) do
      ::StateMethods.implementation = 'Classy'
    end
    include_examples 'implementation'
  end

end
