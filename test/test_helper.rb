# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

# shoulda
class Test::Unit::TestCase
  def self.should_see_the_timesheet_menu
    should "see the timesheet menu" do
      get '/'

      assert_select '#top-menu a.timesheet'
    end
  end

  def self.should_not_see_the_timesheet_menu
    should "not see the timesheet menu" do
      get '/'

      assert_select '#top-menu a.timesheet', :count => 0
    end
  end
end
