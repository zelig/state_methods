require 'spec_helper'
require 'state_methods'

describe "state methods" do

  class TestModel
    include ::StateMethods
  end

  def model_class
    @model_class
  end

  def model_class!
    @model_class = Class.new(TestModel)
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

  end


  describe "state partition declarations" do

    # before(:each) do
    #   model_class.set_state_partition :state, :partition
    # end

    # it "take state method, partition as arguments" do
    #   model_class.state_method :test, :state, :partition
    # end

  end

end
