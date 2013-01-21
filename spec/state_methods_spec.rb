require 'spec_helper'
require 'state_methods'

describe "state methods" do

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
  end

  def model_subclass
    @model_subclass
  end

  def model_subclass!
    @model_subclass = Class.new(model_class)
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

  describe ::StateMethods::Partition do
    it "default partition" do
      partition = model_class.new_state_partition(:default)
      model_class.new_state_partition(:all => []).should == partition
      model_class.new_state_partition({}).should == partition
      model_class.new_state_partition().should == partition
      model_class.new_state_partition([]).should == partition
    end

    it "partition can mix string/symbol" do
      partition = model_class.new_state_partition(:a => :b)
      model_class.new_state_partition(:a => 'b').should == partition
      model_class.new_state_partition('a' => 'b').should == partition
      model_class.new_state_partition('a' => :b).should == partition
    end

    it "partition does not allow duplicate states" do
      lambda { model_class.new_state_partition(:a => 'a') }.should raise_error(ArgumentError, "duplicate state or partition 'a'")
    end

    it "partition does not invalid state specification" do
      lambda { model_class.new_state_partition(:a => nil) }.should raise_error(ArgumentError, "invalid partition specification for 'a' => 'nil'")
    end
  end

  describe "state partition declarations are allowed" do

    it "with state, partition name and partition" do
      model_class.set_state_partition :state, :partition, :a => :b
      model_class.get_state_partition(:state, :partition).should == model_class.new_state_partition(:a => :b)
    end

    it "if they extend earlier declarations" do
      model_class.set_state_partition :state, :partition, :a => :b
      model_class.set_state_partition :state, :partition, :a => :c
      model_class.get_state_partition(:state, :partition).should == model_class.new_state_partition(:a => [:b, :c])
    end

    it "unless they contradict earlier declarations" do
      model_class.set_state_partition :state, :partition, :a => :b
      lambda { model_class.set_state_partition :state, :partition, :c => :a }.should raise_error(::StateMethods::CannotOverrideError)
    end

    it "and are inherited" do
      model_class.set_state_partition :state, :partition, :a => :b
      model_subclass = Class.new(model_class)
      model_subclass.get_state_partition(:state, :partition).should == model_class.new_state_partition(:a => :b)
    end

    it "and are extensible in subclass, not overwritten in superclass" do
      model_class.set_state_partition :state, :partition, :a => :b
      model_subclass = Class.new(model_class)
      model_subclass.set_state_partition :state, :partition, :a => :c
      model_subclass.get_state_partition(:state, :partition).should == model_class.new_state_partition(:a => [:b, :c])
      model_class.get_state_partition(:state, :partition).should == model_class.new_state_partition(:a => :b)
    end

    it "and define state_is_a? instance method" do
      model_class.set_state_partition :state, :partition, :a => :b
      model!.state!(:b)
      model.state_is_a?(:b).should be_true
      model.state_is_a?(:a).should be_true
      model.state_is_a?(:all).should be_true
      model.state_is_a?(:c).should be_false
    end

  end

  describe "state method declarations" do

    before(:each) do
      model_class.set_state_partition :state, :partition, :default
    end

    it "take state method, partition as arguments" do
      model_class.state_method :test, :state, :partition
    end

    it "raise PartitionNotFound error if partition is not set up" do
      lambda { model_class.state_method :test, :state, :nopartition }.should raise_error(::StateMethods::PartitionNotFound)
    end

    it "should define class and instance method" do
      model_class.state_method :test, :state, :partition
      model_class.should respond_to(:test)
      model!.should respond_to(:test)
    end

  end

  describe "state method behaviour" do

    before(:each) do
      model_class.set_state_partition :state, :partition, :default
      model_class.state_method :test, :state, :partition
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
        model_class.set_state_partition :other_state, :partition, :default
        model_class.state_method :other_test, :other_state, :partition
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
        model_class.new.state!(:a).test.should == 0
      end

    end

    context "multiple states and state sets" do

      before(:each) do
        model_class.set_state_partition :state, :partition, { :ab => [:a, :b] }
        model_class.state_method :test, :state, :partition
        model_subclass!.set_state_partition :state, :partition, { :cd => [:c, :d], :ab => { :b => [:b0, :b1] } }
        model!.state!(:none)
      end

      it "inherit spec from superclass even if state is only explicit in subclass partition" do
        model_class.test(:c) { 1 }
        model.state!(:c).state.should == :c
        model.test.should == 1
      end

      it "specification block is executed in model instance scope" do
        model_class.test(:all) { state }
        model.state!(:a).test.should == :a
        model.state!(:c).state.should == :c
        model.test.should == :c
      end

      it "specification block arguments are passed correctly" do
        model_class.test(:a) { |first, second, *rest| "state: #{state}, first: #{first}, second: #{second}, rest: #{rest.join(', ')}" }
        model.state!(:a).state.should == :a
        model.test(1, 2, 3, 4).should == "state: a, first: 1, second: 2, rest: 3, 4"
      end

      include_examples 'singular specification'

    end

  end

end
