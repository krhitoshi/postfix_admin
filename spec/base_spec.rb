require 'postfix_admin/base'

describe PostfixAdmin::Base do
  it "new" do
    lambda { PostfixAdmin::Base.new }.should raise_error(ArgumentError)
  end
end
