require "state_methods/version"
require "state_methods/base"
require "state_methods/method_utils"

module StateMethods

  # extend ::StateMethods::MethodUtils

  def self.included(base)
    base.class_eval do
      include ::StateMethods::Base
    end
  end

end
