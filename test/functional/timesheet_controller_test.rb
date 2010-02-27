require File.dirname(__FILE__) + '/../test_helper'

module TimesheetControllerHelper
  # Sets up the default mocks
  def default_mocks(options = {})
    # User
    @current_user = User.generate_with_protected!(:admin => false)
    User.current = @current_user
    
    # Redmine application controller
#    controller.stub!(:check_if_login_required).and_return(true)
#    controller.stub!(:set_localization)
    
    # Timesheet
    @timesheet = Timesheet.new
    # @timesheet.stub!(:projects).and_return([ ])
    # @timesheet.stub!(:projects=)
    # @timesheet.stub!(:allowed_projects).and_return(['not empty'])
    # @timesheet.stub!(:allowed_projects=)
    # @timesheet.stub!(:date_from)
    # @timesheet.stub!(:date_from=)
    # @timesheet.stub!(:date_to)
    # @timesheet.stub!(:date_to=)
    # @timesheet.stub!(:activities)
    # @timesheet.stub!(:activities=)
    # @timesheet.stub!(:users)
    # @timesheet.stub!(:users=)
    # @timesheet.stub!(:fetch_time_entries)
    # @timesheet.stub!(:time_entries).and_return([ ])
    # @timesheet.stub!(:sort)
    # @timesheet.stub!(:sort=)
    # @timesheet.stub!(:period_type=)
    # stub_timesheet unless options[:skip_timesheet_stub]
  end
  
  # Restubs the current user
  def stub_current_user
    User.stub!(:current).and_return(@current_user)
  end
  
  # Restubs the new timesheet
  def stub_timesheet
    Timesheet.stub!(:new).and_return(@timesheet)
  end
end

class ActiveSupport::TestCase
  def self.use_timesheet_controller_shared(&block)
    should 'should set @timesheet.allowed_projects to the list of current projects the user is a member of' do
      project1 = Project.generate!
      project2 = Project.generate!
      projects = [project1, project2]

      projects.each do |project|
        Member.generate!(:principal => @current_user, :project => project, :roles => [@normal_role])
      end
      
      instance_eval &block

      assert_equal projects, assigns['timesheet'].allowed_projects
    end

    should 'should set @timesheet.allowed_projects to all the projects if the user is an admin' do
      @current_user.admin = true
      project1 = Project.generate!
      project2 = Project.generate!
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
  include TimesheetControllerHelper

  def setup
    @normal_role = Role.generate!(:name => 'Normal User', :permissions => [:view_time_entries])
  end

  context "#index with GET request" do
    setup do
      default_mocks
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
      default_mocks(:skip_timesheet_stub => true)

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
      default_mocks
    end

    use_timesheet_controller_shared do
      post :report, :timesheet => {}
    end
    
    should 'should only allow the allowed projects into @timesheet.projects' do
      project1 = Project.generate!
      project2 = Project.generate!
      projects = [project1, project2]

      Member.generate!(:principal => @current_user, :project => project1, :roles => [@normal_role])

      post :report, :timesheet => { :projects => [project1.id, project2.id] }
      assert_equal [project1.id], assigns['timesheet'].projects
    end

    should 'should save the session data' do
      post :report, :timesheet => { :projects => ['1'] }
      assert @request.session[TimesheetController::SessionKey]
      assert session[TimesheetController::SessionKey].keys.include?('projects')
      assert_equal ['1'], @request.session[TimesheetController::SessionKey]['projects']
    end

    context ":csv format" do
      setup do
        post :report, :timesheet => {:projects => ['1']}, :format => 'csv'
      end

      should_respond_with_content_type 'text/csv'
      should_respond_with :success
    end
  end

  context "#report with request with no data" do
    setup do
      default_mocks
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
end
