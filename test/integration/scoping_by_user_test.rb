require 'test_helper'

class ScopingByUserTest < ActionController::IntegrationTest
  def setup
    @project1 = Project.generate!
    @project2 = Project.generate!

    @admin_user = User.generate!(:login => 'theadmin', :admin => true, :password => 'testing', :password_confirmation => 'testing')
    @user = User.generate!(:login => 'user', :admin => true, :password => 'testing', :password_confirmation => 'testing')
    @role = Role.generate!(:permissions => [:view_time_entries])
    Member.generate!(:principal => @user, :project => @project1, :roles => [@role])
    
    @activity1 = TimeEntryActivity.generate!.reload
    @activity2 = TimeEntryActivity.generate!.reload

    @admin_timesheet = Timesheet.create!(:name => 'admin timesheet') do |t|
      t.user = @admin_user
    end
    
    @user_timesheet = Timesheet.create!(:name => 'user timesheet') do |t|
      t.user = @user
    end
  end

  context "users should only be able to use their own timesheets" do
    setup do
      login_as(@user.login, 'testing')
      click_link "Timesheet"
      assert_response :success
    end
    
      
    should "be able to use their own timesheets" do
      click_link 'user timesheet'
      assert_response :success
      assert_equal "/timesheets/#{@user_timesheet.id}", current_path
    end
    
    should "not be able to use other user's timesheets" do
      assert_select "a", :text => /admin timesheet/, :count => 0
      
      visit "/timesheets/#{@admin_timesheet.id}" # direct url
      assert_response :not_found
    end

    should "be able to edit their own timesheets" do
      click_link 'user timesheet'
      assert_response :success

      fill_in "Name", :with => 'user changed'
      click_button 'Save'

      assert_equal 'user changed', @user_timesheet.reload.name
    end
    
    should "not be able to edit other user's timesheets" do
      post "/timesheets/#{@admin_timesheet.id}", :timesheet => {:name => 'user changed'} # direct url
      assert_response :not_found

      assert_equal 'admin timesheet', @admin_timesheet.reload.name
    end
  end
end
