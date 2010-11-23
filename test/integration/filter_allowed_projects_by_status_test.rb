require 'test_helper'

class FilterAllowedProjectsByStatusTest < ActionController::IntegrationTest
  def setup
    @active_project1 = Project.generate!
    @active_project2 = Project.generate!
    @archived_project1 = Project.generate!(:status => Project::STATUS_ARCHIVED)
    @archived_private_project1 = Project.generate!(:status => Project::STATUS_ARCHIVED, :is_public => false)
    assert !@archived_project1.active?
    assert !@archived_private_project1.active?

    @admin_user = User.generate_with_protected!(:login => 'theadmin', :admin => true, :password => 'testing', :password_confirmation => 'testing')
    @user = User.generate_with_protected!(:login => 'theuser', :admin => false, :password => 'testing', :password_confirmation => 'testing')
    @role = Role.generate!(:permissions => [:view_time_entries])
    @project = Project.generate!
    Member.generate!(:principal => @user, :project => @project, :roles => [@role])

    Member.generate!(:principal => @user, :project => @archived_private_project1, :roles => [@role])
  end

  context "with project_status configured to all" do
    setup do
      Setting.plugin_timesheet_plugin = {'project_status' => 'all'}
    end
    
    context "as an admin" do
      setup do
        log_user(@admin_user.login, 'testing')
        follow_redirect!
        click_link "Timesheet"
      end

      should "see archived projects in the list" do
        assert_select "#timesheet_projects_" do
          assert_select 'option[value=?]', @active_project1.id
          assert_select 'option[value=?]', @active_project2.id
          assert_select 'option[value=?]', @archived_project1.id
          assert_select 'option[value=?]', @archived_private_project1.id
        end
      end
    end
    
    context "as a regular user" do
      setup do
        log_user(@user.login, 'testing')
        follow_redirect!
        click_link "Timesheet"
      end

      should "see archived projects in the list" do
        assert_select "#timesheet_projects_" do
          assert_select 'option[value=?]', @active_project1.id
          assert_select 'option[value=?]', @active_project2.id
          assert_select 'option[value=?]', @archived_project1.id
          assert_select 'option[value=?]', @archived_private_project1.id
        end
      end
      
    end
  end

  context "with project_status configured to active" do
    setup do
      Setting.plugin_timesheet_plugin = {'project_status' => 'active'}
    end
    
    context "as an admin" do
      setup do
        log_user(@admin_user.login, 'testing')
        follow_redirect!
        click_link "Timesheet"
      end

      should "see archived projects in the list" do
        assert_select "#timesheet_projects_" do
          assert_select 'option[value=?]', @active_project1.id
          assert_select 'option[value=?]', @active_project2.id
          assert_select 'option[value=?]', @archived_project1.id
        end
      end
    end
    
    context "as a regular user" do
      setup do
        log_user(@user.login, 'testing')
        follow_redirect!
        click_link "Timesheet"
      end

      should "not see archived projects in the list" do
        assert_select "#timesheet_projects_" do
          assert_select 'option[value=?]', @active_project1.id
          assert_select 'option[value=?]', @active_project2.id
          assert_select 'option[value=?]', @archived_project1.id, :count => 0
        end
      end
      
    end
  end

end

