require File.dirname(__FILE__) + '/../test_helper'
class ActiveSupport::TestCase
  def self.use_timesheet_controller_shared(&block)
    should 'should set @timesheet.allowed_projects to the list of current projects the user is a member of' do
      Member.destroy_all # clear any setup memberships

      project1 = Project.generate!
      project2 = Project.generate!
      projects = [project1, project2]

      projects.each do |project|
        Member.generate!(:principal => @current_user, :project => project, :roles => [@normal_role])
      end
      
      instance_eval &block

      assert_equal projects, assigns['timesheet'].allowed_projects
    end

    should 'include public projects in @timesheet.allowed_projects' do
      project1 = Project.generate!(:is_public => true)
      project2 = Project.generate!(:is_public => true)
      projects = [project1, project2]

      instance_eval &block

      assert_contains assigns['timesheet'].allowed_projects, project1
      assert_contains assigns['timesheet'].allowed_projects, project2
    end

    should 'should set @timesheet.allowed_projects to all the projects if the user is an admin' do
      Member.destroy_all # clear any setup memberships

      @current_user.admin = true
      project1, _ = *generate_project_membership(@current_user)
      project2, _ = *generate_project_membership(@current_user)
      projects = [project1, project2]

      instance_eval &block

      assert_equal projects, assigns['timesheet'].allowed_projects
    end

    should 'should get the list size from the settings' do
      settings = { 'list_size' => 10, 'precision' => '2' }
      Setting.plugin_timesheet_plugin = settings
      
      instance_eval &block
      assert_equal 10, assigns['list_size']
    end

    should 'should get the precision from the settings' do
      settings = { 'list_size' => 10, 'precision' => '2' }
      Setting.plugin_timesheet_plugin = settings
      
      instance_eval &block
      assert_equal 2, assigns['precision']
    end

    should 'should create a new @timesheet' do
      instance_eval &block
      assert assigns['timesheet']
    end
  end
end


class TimesheetControllerTest < ActionController::TestCase
  def generate_and_login_user(options = {})
    @current_user = User.generate_with_protected!(:admin => false)
    @request.session[:user_id] = @current_user.id
  end

  def generate_project_membership(user)
    @project = Project.generate!(:is_public => false)
    @member = Member.generate!(:principal => user, :project => @project, :roles => [@normal_role])
    [@project, @member]
  end

  def setup
    @normal_role = Role.generate!(:name => 'Normal User', :permissions => [:view_time_entries])
  end

  context "#index with GET request" do
    setup do
      generate_and_login_user
      generate_project_membership(@current_user)
      get 'index'
    end

    use_timesheet_controller_shared do
      get 'index'
    end
    
    should_render_template :index
    
    should 'have no timelog entries' do
      assert assigns['timesheet'].time_entries.empty?
    end
  end

  context "#index with GET request and a session" do
  
    should 'should read the session data' do
      generate_and_login_user
      @current_user.admin = true
      @current_user.save!

      projects = []
      4.times do |i|
        projects << Project.generate!
      end
      
      session[TimesheetController::SessionKey] = HashWithIndifferentAccess.new(
                                                                               :projects => projects.collect(&:id).collect(&:to_s),
                                                                               :date_to => '2009-01-01',
                                                                               :date_from => '2009-01-01'
                                                                               )

      get :index
      assert_equal '2009-01-01', assigns['timesheet'].date_from
      assert_equal '2009-01-01', assigns['timesheet'].date_to
      assert_equal projects, assigns['timesheet'].projects
    end
  end

  context "#index with GET request from an Anonymous user" do
     setup do
      get 'index'
    end

    should_render_template :no_projects

  end

  context "#report with GET request from an Anonymous user" do
    setup do
      get :report
    end

    should_respond_with :redirect
    should_redirect_to('index') {{:action => 'index'}}
  end

  context "#report with POST request from an Anonymous user" do
    setup do
      post :report
    end

    should_respond_with :redirect
    should_redirect_to('index') {{:action => 'index'}}

  end

  context "#report with POST request" do
    setup do
      generate_and_login_user
    end

    use_timesheet_controller_shared do
      post :report, :timesheet => {}
    end
    
    should 'should only allow the allowed projects into @timesheet.projects' do
      project1 = Project.generate!(:is_public => false)
      project2 = Project.generate!(:is_public => false)
      projects = [project1, project2]

      Member.generate!(:principal => @current_user, :project => project1, :roles => [@normal_role])

      post :report, :timesheet => { :projects => [project1.id.to_s, project2.id.to_s] }

      assert_equal [project1], assigns['timesheet'].projects
    end

    should 'include public projects' do
      project1 = Project.generate!(:is_public => true)
      project2 = Project.generate!(:is_public => true)
      projects = [project1, project2]

      post :report, :timesheet => { :projects => [project1.id.to_s, project2.id.to_s] }

      assert_contains assigns['timesheet'].allowed_projects, project1
      assert_contains assigns['timesheet'].allowed_projects, project2
    end

    should 'should save the session data' do
      generate_project_membership(@current_user)
      post :report, :timesheet => { :projects => ['1'] }

      assert @request.session[TimesheetController::SessionKey]
      assert @request.session[TimesheetController::SessionKey].keys.include?('projects')
      assert_equal ['1'], @request.session[TimesheetController::SessionKey]['projects']
    end

    context ":csv format" do
      setup do
        generate_project_membership(@current_user)
        post :report, :timesheet => {:projects => ['1']}, :format => 'csv'
      end

      should_respond_with_content_type 'text/csv'
      should_respond_with :success
    end
  end

  context "#report with request with no data" do
    setup do
      generate_and_login_user
    end

    context 'should redirect to the index' do
      context "from a GET request" do
        setup do
          get 'report', { }
        end

        should_respond_with :redirect
        should_redirect_to('index') {{:action => 'index' }}
      end

      context "from a POST request" do
        setup do
          post 'report', { }
        end

        should_respond_with :redirect
        should_redirect_to('index') {{:action => 'index' }}
      end
    end
  end

  context "DELETE to :reset" do
    setup do
      generate_and_login_user
      @current_user.admin = true
      @current_user.save!

      @project = Project.generate!
      session[TimesheetController::SessionKey] = HashWithIndifferentAccess.new(
                                                                               :projects => [@project.id.to_s],
                                                                               :date_to => '2009-01-01',
                                                                               :date_from => '2009-01-01'
                                                                               )

      delete :reset
    end
    
    should_respond_with :redirect
    should_redirect_to('index') {{:action => 'index'}}
    should 'clear the session' do
      assert session[TimesheetController::SessionKey].blank?
    end

  end
end
