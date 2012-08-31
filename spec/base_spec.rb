require 'postfix_admin/base'

describe PostfixAdmin::Base do
  before do
    @base = PostfixAdmin::Base.new({'database' => 'mysql://postfix:password@localhost/postfix'})
  end

  it "#new without config" do
    lambda { PostfixAdmin::Base.new }.should raise_error(ArgumentError)
  end

  it "#new without database config" do
    lambda { PostfixAdmin::Base.new({}) }.should raise_error(ArgumentError)
  end

  it "#new with database config" do
    lambda { PostfixAdmin::Base.new({'database' => 'mysql://postfix:password@localhost/postfix'}) }.should_not raise_error
  end

end
