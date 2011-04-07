require 'test_helper'
require 'ap'

class SavingTimesheetTest < ActionController::IntegrationTest
  def setup
    @project1 = Project.generate!
    @project2 = Project.generate!

    @admin_user = User.generate_with_protected!(:login => 'theadmin', :admin => true, :password => 'testing', :password_confirmation => 'testing')
    @activity1 = TimeEntryActivity.generate!.reload
    @activity2 = TimeEntryActivity.generate!.reload
  end

  context "using the filter form" do
    setup do
      login_as(@admin_user.login, 'testing')
      click_link "Timesheet"
      assert_response :success
    end

    should "be saved" do
      choose "timesheet_period_type_1" # Pre-defined
      select "today", :from => 'timesheet_period'
      select "User", :from => 'timesheet_sort'
      select @project1.name, :from => 'Project:'
      fill_in "Name", :with => 'Save test'

      assert_difference('Timesheet.count') do
        click_button 'Save'
        assert_response :success
      end

      timesheet = Timesheet.last
      assert_equal "Save test", timesheet.name
    end
    
    should "save the filters with predefined dates" do
      choose "timesheet_period_type_1" # Pre-defined
      select "today", :from => 'timesheet_period'
      select "User", :from => 'timesheet_sort'
      select @project1.name, :from => 'Project:'
      select @admin_user.name, :from => 'Users:'
      fill_in "Name", :with => 'Save test'

      assert_difference('Timesheet.count') do
        click_button 'Save'
        assert_response :success
      end

      timesheet = Timesheet.last
      assert_equal "Save test", timesheet.name
      assert_equal @admin_user, timesheet.user
      # Using pre-defined dates
      assert_equal Timesheet::ValidPeriodType[:default], timesheet.period_type
      assert_equal "today", timesheet.period
      assert_equal nil, timesheet.date_to
      assert_equal nil, timesheet.date_from
      assert_equal :user, timesheet.sort
      assert_equal [@activity1.id,@activity2.id], timesheet.activities
      assert_equal [@admin_user.id], timesheet.users
      assert_equal [@project1,@project2].sort, timesheet.projects.sort
    end

    should "save the filters with free dates" do
      choose "timesheet_period_type_2" # Free date
      fill_in "From:", :with => "2011-04-07"
      fill_in "To:", :with => "2011-04-17"
      select "User", :from => 'timesheet_sort'
      select @project1.name, :from => 'Project:'
      select @admin_user.name, :from => 'Users:'
      fill_in "Name", :with => 'Save test'

      assert_difference('Timesheet.count') do
        click_button 'Save'
        assert_response :success
      end

      timesheet = Timesheet.last
      assert_equal "Save test", timesheet.name
      assert_equal @admin_user, timesheet.user
      # Using pre-defined dates
      assert_equal Timesheet::ValidPeriodType[:free_period], timesheet.period_type
      assert_equal '', timesheet.period
      assert_equal "2011-04-07", timesheet.date_from.to_s
      assert_equal "2011-04-17", timesheet.date_to.to_s
      assert_equal :user, timesheet.sort
      assert_equal [@activity1.id,@activity2.id], timesheet.activities
      assert_equal [@admin_user.id], timesheet.users
      assert_equal [@project1,@project2].sort, timesheet.projects.sort
    end
  end
end
