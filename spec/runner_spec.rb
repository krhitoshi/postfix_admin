require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/runner'

describe PostfixAdmin::Runner do
  describe "#show" do
    it "#show shows information of example.com" do
      capture(:stdout){ PostfixAdmin::Runner.start(["show"]) }.should =~ /example.com.+100.+100.+100/
    end

    it "#show shows information of admin@example.com" do
      capture(:stdout){ PostfixAdmin::Runner.start(["show"]) }.should =~ /admin@example.com.+password/
    end
  end
end
