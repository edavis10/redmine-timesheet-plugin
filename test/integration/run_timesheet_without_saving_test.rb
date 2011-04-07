require 'test_helper'

class RunTimesheetWithoutSaving < ActionController::IntegrationTest
  def setup
    @project1 = Project.generate!
    @project2 = Project.generate!

    @admin_user = User.generate_with_protected!(:login => 'theadmin', :admin => true, :password => 'testing', :password_confirmation => 'testing')
    @activity1 = TimeEntryActivity.generate!.reload
    @activity2 = TimeEntryActivity.generate!.reload
    @time_entry = TimeEntry.generate!(:user => @admin_user,
                                      :activity => @activity1,
                                      :hours => 10,
                                      :comments => 'test',
                                      :project => @project1)
  end

  context "running the timesheet" do
    setup do
      login_as(@admin_user.login, 'testing')
      click_link "Timesheet"
      assert_response :success

      choose "timesheet_period_type_1" # Pre-defined
      select "today", :from => 'timesheet_period'
      select "User", :from => 'timesheet_sort'
      select @project1.name, :from => 'Project:'
      fill_in "Name", :with => 'Save test'
    end

    should "not be saved" do
      assert_no_difference('Timesheet.count') do
        click_button 'Run without saving'
        assert_response :success
      end

      assert_equal "/timesheets", current_url
    end
    
    should "show the matching records" do
      click_button 'Run without saving'
      assert_response :success

      assert_select "tr.time_entry", :count => 1
    end
    
  end
end
  
