require 'test_helper'

class TimesheetMenuTest < ActionController::IntegrationTest
  context "as an admin" do
    setup do
      @admin_user = User.generate_with_protected!(:admin => true, :password => 'testing', :password_confirmation => 'testing')
      log_user(@admin_user.login, 'testing')
    end
    
    should_see_the_timesheet_menu
  end

  context "as a user with See Project Timesheets on a project" do
    setup do
      @manager_user = User.generate_with_protected!(:admin => false, :password => 'testing', :password_confirmation => 'testing')

      @manager_role = Role.generate!(:permissions => [:view_time_entries, :see_project_timesheets])
      @project = Project.generate!
      Member.generate!(:principal => @manager_user, :project => @project, :roles => [@manager_role])

      log_user(@manager_user.login, 'testing')
    end

    should_see_the_timesheet_menu
  end

  context "as a user with View Time Entries on a project" do
    setup do
      @user = User.generate_with_protected!(:admin => false, :password => 'testing', :password_confirmation => 'testing')

      @role = Role.generate!(:permissions => [:view_time_entries])
      @project = Project.generate!
      Member.generate!(:principal => @user, :project => @project, :roles => [@role])

      log_user(@user.login, 'testing')
    end

    should_see_the_timesheet_menu
  end

  context "as a user with without See Project Timesheets or View Time Entries on a project" do
    setup do
      @user = User.generate_with_protected!(:admin => false, :password => 'testing', :password_confirmation => 'testing')
      log_user(@user.login, 'testing')
    end

    should_not_see_the_timesheet_menu
  end

  context "as the anonymous user" do
    should_not_see_the_timesheet_menu
  end
end
