require File.dirname(__FILE__) + '/../spec_helper'

describe TimesheetController do
  it "should use TimesheetController" do
    controller.should be_an_instance_of(TimesheetController)
  end

end

describe TimesheetController,"#index with GET request" do
  it 'should set @project to the current project' do
    project = mock_model(Project, :to_param => '1')
    Project.should_receive(:find).with('1').and_return(project)
    
    get 'index', :id => '1'
    assigns[:project].should_not be_nil
  end

  it 'should set @project to nil if there are no projects' do
    get 'index'
    assigns[:project].should be_nil
  end
  
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
  it 'should set @timesheet.projects to all the projects if the user is an admin (#746)'

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


# describe TimesheetController,"#index with POST request"

