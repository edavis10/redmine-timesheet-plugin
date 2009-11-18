require File.dirname(__FILE__) + '/../spec_helper'

module TimesheetControllerHelper
  # Sets up the default mocks
  def default_mocks(options = {})
    # User
    @current_user = mock_model(User)
    @current_user.stub!(:admin?).and_return(false)
    @user_project_mock = mock_model(Project)
    @user_project_mock.stub!(:find).and_return([ ])
    @current_user.stub!(:projects).and_return(@user_project_mock)
    stub_current_user
    
    # Redmine application controller
    controller.stub!(:check_if_login_required).and_return(true)
    controller.stub!(:set_localization)
    
    # Timesheet
    @timesheet = mock_model(Timesheet)
    @timesheet.stub!(:projects).and_return([ ])
    @timesheet.stub!(:projects=)
    @timesheet.stub!(:allowed_projects).and_return(['not empty'])
    @timesheet.stub!(:allowed_projects=)
    @timesheet.stub!(:date_from)
    @timesheet.stub!(:date_from=)
    @timesheet.stub!(:date_to)
    @timesheet.stub!(:date_to=)
    @timesheet.stub!(:activities)
    @timesheet.stub!(:activities=)
    @timesheet.stub!(:users)
    @timesheet.stub!(:users=)
    @timesheet.stub!(:fetch_time_entries)
    @timesheet.stub!(:time_entries).and_return([ ])
    @timesheet.stub!(:sort)
    @timesheet.stub!(:sort=)
    @timesheet.stub!(:period_type=)
    stub_timesheet unless options[:skip_timesheet_stub]
  end
  
  # Converts current user to admin
  def mock_admin
    @current_user.stub!(:admin?).and_return(true)
    stub_current_user
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

describe 'TimesheetControllerShared', :shared => true do
  it 'should set @timesheet.allowed_projects to the list of current projects the user is a member of' do
    project1 = mock_model(Project)
    project2 = mock_model(Project)
    projects = [project1, project2]
    
    # Adjust mocks
    @user_project_mock.should_receive(:find).and_return(projects)
    stub_current_user
    @timesheet.should_receive(:allowed_projects=).with(projects)
    @timesheet.stub!(:allowed_projects).and_return(projects)
    stub_timesheet
    
    send_request
    assigns[:timesheet].allowed_projects.should eql(projects)
  end

  it 'should set @timesheet.allowed_projects to all the projects if the user is an admin' do
    mock_admin
    project1 = mock_model(Project)
    project2 = mock_model(Project)
    projects = [project1, project2]
    
    # Adjust mocks
    Project.stub!(:find).with(:all, { :order => "name ASC" }).and_return(projects)
    @timesheet.should_receive(:allowed_projects=).with(projects)
    @timesheet.stub!(:allowed_projects).and_return(projects)
    stub_timesheet
    
    send_request
    assigns[:timesheet].allowed_projects.should eql(projects)
  end

  it 'should get the list size from the settings' do
    settings = { 'list_size' => 10, 'precision' => '2' }
    Setting.should_receive(:plugin_timesheet_plugin).twice.and_return(settings)
    
    send_request
    assigns[:list_size].should eql(10)
  end

  it 'should get the precision from the settings' do
    settings = { 'list_size' => 10, 'precision' => '2' }
    Setting.should_receive(:plugin_timesheet_plugin).twice.and_return(settings)
    
    send_request
    assigns[:precision].should eql(2)
  end

  it 'should create a new @timesheet' do
    Timesheet.should_receive(:new).and_return(@timesheet)

    send_request
    assigns[:timesheet].should eql(@timesheet)
  end
end


describe TimesheetController do
  it "should use TimesheetController" do
    controller.should be_an_instance_of(TimesheetController)
  end

end
describe TimesheetController,"#index with GET request" do
  include TimesheetControllerHelper
  
  def send_request
    get 'index'
  end
  
  before(:each) do
    default_mocks
  end

  it_should_behave_like "TimesheetControllerShared"
  
  it 'should have no timelog entries' do
    get 'index'
    assigns[:timesheet].time_entries.should be_empty
  end

  it 'should render the index template' do
    get 'index'
    response.should render_template('index')
  end
end

describe TimesheetController,"#index with GET request and a session" do
  include TimesheetControllerHelper
  it 'should read the session data' do
    default_mocks(:skip_timesheet_stub => true)

    projects = []
    4.times do |i|
      projects << mock_model(Project, :id => i + 1)
    end
    
    controller.stub!(:allowed_projects).and_return(projects)
    session[TimesheetController::SessionKey] = HashWithIndifferentAccess.new(
      :projects => projects.collect(&:id).collect(&:to_s),
      :date_to => '2009-01-01',
      :date_from => '2009-01-01'
    )

    get :index
    assigns[:timesheet].date_from.should eql('2009-01-01')
    assigns[:timesheet].date_to.should eql('2009-01-01')
    assigns[:timesheet].projects.should eql(projects)
  end
end

describe TimesheetController,"#index with GET request from an Anonymous user" do
  include TimesheetControllerHelper

  it 'should render the no_projects template' do
    get 'index'
    response.should render_template('no_projects')
  end

end

describe TimesheetController,"#report with GET request from an Anonymous user" do
  include TimesheetControllerHelper

  it 'should redirect to the index' do
    get 'report'
    response.should be_redirect
    response.should redirect_to(:action => 'index')
  end

end

describe TimesheetController,"#report with POST request from an Anonymous user" do
  include TimesheetControllerHelper

  it 'should redirect to the index' do
    get 'report'
    response.should be_redirect
    response.should redirect_to(:action => 'index')
  end

end

describe TimesheetController,"#report with POST request" do
  include TimesheetControllerHelper
  
  before(:each) do
    default_mocks
  end

  def send_request
    post_report
  end
  
  def post_report(data={ :timesheet => { } })
    post 'report', data
  end
  
  it_should_behave_like "TimesheetControllerShared"
  
  it 'should only allow the allowed projects into @timesheet.projects' do
    project1 = mock_model(Project, :to_param => '1', :id => 1)
    project2 = mock_model(Project, :to_param => '2', :id => 2)
    projects = [project1, project2]
    
    # Adjust mocks
    @user_project_mock.should_receive(:find).and_return(projects)
    stub_current_user

    @timesheet.should_receive(:allowed_projects=).with(projects)
    @timesheet.should_receive(:allowed_projects).twice.and_return(projects)
    @timesheet.should_receive(:projects=).with([project1])
    stub_timesheet

    post_report({ :timesheet => { :projects => ['1'] } })
  end

  it 'should save the session data' do
    post_report({ :timesheet => { :projects => ['1'] } })
    session[TimesheetController::SessionKey].should_not be_nil
    session[TimesheetController::SessionKey].keys.should include('projects')
    session[TimesheetController::SessionKey]['projects'].should eql(['1'])
  end

  context ":csv format" do
    it 'should return the timesheet data as csv' do
      @timesheet.should_receive(:to_csv).and_return('csv content')
      post_report({:timesheet => {:projects => ['1']}, :format => 'csv'})
      response.body.should == 'csv content'
      response.content_type.should == 'text/csv'
    end
  end
end

describe TimesheetController,"#report with request with no data" do
  include TimesheetControllerHelper
  
  before(:each) do
    default_mocks
  end

  describe 'should redirect to the index' do
    it 'from a GET request' do
      post 'report', { }
      response.should be_redirect
      response.should redirect_to(:action => 'index')
    end

    it 'from a POST request' do
      post 'report', { }
      response.should be_redirect
      response.should redirect_to(:action => 'index')
    end
  end
end
