require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/models'

describe PostfixAdmin::Admin do
  before do
    db_initialize
  end

  it "#super_admin?" do
    Admin.find('admin@example.com').super_admin?.should === false
    Admin.find('all@example.com').super_admin?.should === true
  end

  it "#super_admin=" do
    Admin.find('admin@example.com').super_admin = true
    Admin.find('admin@example.com').super_admin?.should === true

    Admin.find('all@example.com').super_admin = false
    Admin.find('all@example.com').super_admin?.should === false
  end
end
