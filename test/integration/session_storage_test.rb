require 'test_helper'

class SessionStorageTest < ActionController::IntegrationTest
  def setup
    @project1 = Project.generate!
    @project2 = Project.generate!

    @admin_user = User.generate!(:login => 'theadmin', :admin => true, :password => 'testing', :password_confirmation => 'testing')
    @role = Role.generate!(:permissions => [:view_time_entries])
    @project = Project.generate!
    Member.generate!(:principal => @admin_user, :project => @project, :roles => [@role])
  end

  context "when running a report" do
    setup do
      login_as(@admin_user.login, "testing")
    end
    
    should "save the timesheet params to the session"
    should "reuse the session params when loading a fresh timesheet"
    should "not save the timesheet params if it would overflow the cookie store" do
      # Since sessions are 4K, make a ton of Activities to load into the session (they are faster than Projects/Users)
      1000.times {|i| self.instance_variable_set("@activity_#{i}", TimeEntryActivity.generate!.reload) }
      click_link "Timesheet"
      choose "timesheet_period_type_1" # Pre-defined
      select "all time", :from => 'timesheet_period'
      select "Project", :from => 'timesheet_sort'
      select @project1.name, :from => 'Project:'
      select @project2.name, :from => 'Project:'
      1000.times {|i|
        select(self.instance_variable_get("@activity_#{i}").name, :from => "timesheet_activities_")
      }

      assert_nothing_raised do
        click_button 'Apply'

        click_link "Timesheet"
        assert_response :success # loads the cookie
      end
    end
    
  end
  
end
