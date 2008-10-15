require File.dirname(__FILE__) + '/../spec_helper'

module TimesheetControllerHelper
  # Sets up the default mocks
  def default_mocks
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
    @timesheet.stub!(:allowed_projects)
    @timesheet.stub!(:allowed_projects=)
    @timesheet.stub!(:date_from)
    @timesheet.stub!(:date_from=)
    @timesheet.stub!(:date_to)
    @timesheet.stub!(:date_to=)
    @timesheet.stub!(:activities)
    @timesheet.stub!(:activities=)
    @timesheet.stub!(:users)
    @timesheet.stub!(:users=)
    stub_timesheet
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
    @timesheet.should_receive(:allowed_projects).and_return(projects)
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
    @timesheet.should_receive(:allowed_projects).and_return(projects)
    stub_timesheet
    
    send_request
    assigns[:timesheet].allowed_projects.should eql(projects)
  end

    it 'should get the list size from the settings' do
    settings = { 'list_size' => 10 }
    Setting.should_receive(:plugin_timesheet_plugin).and_return(settings)
    
    send_request
    assigns[:list_size].should eql(10)
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
    assigns[:entries].should be_empty
  end

  it 'should render the index template' do
    get 'index'
    response.should render_template('index')
  end
  
    it 'should set the from date to today' do
    send_request
    assigns[:from].should eql(Date.today.to_s)
  end

  it 'should set the to date to today' do
    send_request
    assigns[:to].should eql(Date.today.to_s)
  end
end


describe TimesheetController,"#index with POST request" do
  include TimesheetControllerHelper
  
  before(:each) do
    default_mocks
  end

  def send_request
    post_index
  end
  
  def post_index(data={ :timesheet => { } })
    post 'index', data
  end
  
  it_should_behave_like "TimesheetControllerShared"
end

