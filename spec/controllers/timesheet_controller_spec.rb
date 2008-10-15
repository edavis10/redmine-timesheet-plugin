require File.dirname(__FILE__) + '/../spec_helper'

describe TimesheetController do
  it "should use TimesheetController" do
    controller.should be_an_instance_of(TimesheetController)
  end

end
describe TimesheetController,"#index with GET request" do
  it 'should get the list size from the settings' do
    settings = { 'list_size' => 10 }
    Setting.should_receive(:plugin_timesheet_plugin).and_return(settings)
    
    get 'index'
    assigns[:list_size].should eql(10)
  end

  it 'should create a new @timesheet' do
    timesheet = mock_model(Timesheet)
    timesheet.stub!(:projects=)
    Timesheet.should_receive(:new).and_return(timesheet)

    get 'index'
    assigns[:timesheet].should eql(timesheet)
  end

  it 'should set @timesheet.projects to the list of current projects the user is a member of (#746)'

  it 'should set @timesheet.projects to all the projects if the user is an admin' do
    project1 = mock_model(Project)
    project2 = mock_model(Project)
    projects = [project1, project2]
    Project.should_receive(:find).with(:all).and_return(projects)
    
    timesheet = mock_model(Timesheet)
    timesheet.should_receive(:projects=).with(projects)
    timesheet.should_receive(:projects).and_return(projects)
    Timesheet.should_receive(:new).and_return(timesheet)
    
    get 'index'
    assigns[:timesheet].projects.should eql(projects)
  end

  it 'should set the from date to today' do
    get 'index'
    assigns[:from].should eql(Date.today.to_s)
  end

  it 'should set the to date to today' do
    get 'index'
    assigns[:to].should eql(Date.today.to_s)
  end

  it 'should have no timelog entries' do
    get 'index'
    assigns[:entries].should be_empty
  end

  it 'should render the index template' do
    get 'index'
    response.should render_template('index')
  end
end


describe TimesheetController,"#index with POST request" do
  before(:each) do
    # Timesheet mock
    @timesheet = mock_model(Timesheet)
    @timesheet.stub!(:projects=)
    @timesheet.stub!(:date_from=)
    @timesheet.stub!(:date_to=)
    @timesheet.stub!(:activities=)
    @timesheet.stub!(:users=)
    @timesheet.stub!(:projects).and_return([ ])
    Timesheet.stub!(:new).and_return(@timesheet)
    
    
  end
  
  def post_index(data={ })
    post 'index', data
  end
  
  it 'should get the list size from the settings' do
    settings = { 'list_size' => 10 }
    Setting.should_receive(:plugin_timesheet_plugin).and_return(settings)
    
    post 'index', :timesheet => { }
    assigns[:list_size].should eql(10)
  end

  it 'should create a new @timesheet' do
    Timesheet.should_receive(:new).and_return(@timesheet)

    post 'index', :timesheet => { }
    assigns[:timesheet].should eql(@timesheet)
  end
  
end

