require File.dirname(__FILE__) + '/../spec_helper'

module TimesheetSpecHelper
  def timesheet_factory(options={ })
    timesheet = Timesheet.new(options)
    timesheet.date_from ||= Date.today.to_s
    timesheet.date_to ||= Date.today.to_s
    
    return timesheet
  end
  
  def project_factory(id, options = { })
    object_options = { 
      :parent => nil,
      :id => id,
      :to_param => id.to_s
    }.merge(options)

    project = mock_model(Project, object_options)
    project_te1 = mock_model(TimeEntry, :id => '100' + id.to_s, :project_id => project.id, :issue_id => '1', :hours => '5', :activity_id => '1', :spent_on => Date.today, :user => 1)
    project_te2 = mock_model(TimeEntry, :id => '101' + id.to_s, :project_id => project.id, :issue_id => '1', :hours => '10', :activity_id => '1', :spent_on => Date.today, :user => 1)
    project_time_entries_mock = mock('project_time_entries_mock')
    project_time_entries_mock.stub!(:find).and_return([project_te1, project_te2])
    project.stub!(:time_entries).and_return(project_time_entries_mock)
    project.stub!(:name).and_return('Project ' + id.to_s)
    
    return project
  end

  def stub_non_member_user(projects)
    @current_user = mock_model(User)
    @current_user.stub!(:admin?).and_return(false)
    projects.each do |project|
      @current_user.stub!(:allowed_to?).with(:view_time_entries, project).and_return(false)
      @current_user.stub!(:allowed_to?).with(:see_project_timesheets, project).and_return(false)
    end
    User.stub!(:current).and_return(@current_user)
  end
  
  def stub_normal_user(projects)
    @current_user = mock_model(User)
    @current_user.stub!(:admin?).and_return(false)
    projects.each do |project|
      @current_user.stub!(:allowed_to?).with(:view_time_entries, project).and_return(true)
      @current_user.stub!(:allowed_to?).with(:see_project_timesheets, project).and_return(false)
    end
    User.stub!(:current).and_return(@current_user)
  end
  
  def stub_manager_user(projects)
    @current_user = mock_model(User)
    @current_user.stub!(:admin?).and_return(false)
    projects.each do |project|
      @current_user.stub!(:allowed_to?).with(:view_time_entries, project).and_return(true)
      @current_user.stub!(:allowed_to?).with(:see_project_timesheets, project).and_return(true)
    end
    User.stub!(:current).and_return(@current_user)
  end
  
  def stub_admin_user
    @current_user = mock_model(User)
    @current_user.stub!(:admin?).and_return(true)
    @current_user.stub!(:allowed_to?).and_return(true)
    User.stub!(:current).and_return(@current_user)    
  end
end

describe Timesheet do
  it 'should not be an ActiveRecord class' do
    Timesheet.should_not be_a_kind_of(ActiveRecord::Base)
  end
end

describe Timesheet, 'initializing' do
  it 'should initialize time_entries to an empty Hash' do 
    timesheet = Timesheet.new
    timesheet.time_entries.should be_a_kind_of(Hash)
    timesheet.time_entries.should be_empty
  end

  it 'should initialize projects to an empty Array' do 
    timesheet = Timesheet.new
    timesheet.projects.should be_a_kind_of(Array)
    timesheet.projects.should be_empty
  end

  it 'should initialize allowed_projects to an empty Array' do 
    timesheet = Timesheet.new
    timesheet.allowed_projects.should be_a_kind_of(Array)
    timesheet.allowed_projects.should be_empty
  end

  it 'should initialize activities to an empty Array' do 
    timesheet = Timesheet.new
    timesheet.activities.should be_a_kind_of(Array)
    timesheet.activities.should be_empty
  end

  it 'should initialize users to an empty Array' do 
    timesheet = Timesheet.new
    timesheet.users.should be_a_kind_of(Array)
    timesheet.users.should be_empty
  end

  it 'should initialize time_entries to the passed in options' do 
    data = { :test => true }
    timesheet = Timesheet.new({ :time_entries => data })
    timesheet.time_entries.should_not be_empty
    timesheet.time_entries.should eql(data)
  end

  it 'should initialize projects to the passed in options' do 
    data = ['project1', 'project2']
    timesheet = Timesheet.new({ :projects => data })
    timesheet.projects.should_not be_empty
    timesheet.projects.should eql(data)
  end

  it 'should initialize allowed_projects to the passed in options' do 
    data = ['project1', 'project2']
    timesheet = Timesheet.new({ :allowed_projects => data })
    timesheet.allowed_projects.should_not be_empty
    timesheet.allowed_projects.should eql(data)
  end

  it 'should initialize activities to the passed in options' do 
    data = ['code', 'test']
    timesheet = Timesheet.new({ :activities => data })
    timesheet.activities.should_not be_empty
    timesheet.activities.should eql(data)
  end

  it 'should initialize users to the passed in options' do 
    data = ['user1', 'user2']
    timesheet = Timesheet.new({ :users => data })
    timesheet.users.should_not be_empty
    timesheet.users.should eql(data)
  end
end

describe Timesheet,'.fetch_time_entries' do
  include TimesheetSpecHelper
  
  it 'should clear .time_entries' do
    timesheet = Timesheet.new
    timesheet.time_entries = { :filled => 'data' }
    proc { 
      timesheet.fetch_time_entries
    }.should change(timesheet, :time_entries)
    
  end

  it 'should add a time_entry array for each project' do
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project2 = project_factory(2)

    stub_admin_user
    timesheet.projects = [project1, project2]
    
    timesheet.fetch_time_entries
    timesheet.time_entries.should_not be_empty
    timesheet.time_entries.should have(2).things
  end
  
  it 'should use the project name for each time_entry array' do 
    
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project1.should_receive(:name).and_return('Project 1')
    project2 = project_factory(2)
    project2.should_receive(:name).and_return('Project 2')

    stub_admin_user
    timesheet.projects = [project1, project2]
    
    timesheet.fetch_time_entries
    timesheet.time_entries.should include("Project 1")
    timesheet.time_entries.should include("Project 2")
  end

  it 'should add the parent project name for each time_entry array for sub-projects' do
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project1.should_receive(:name).twice.and_return('Project 1')
    project2 = project_factory(2, :parent => project1 )
    project2.should_receive(:name).and_return('Project 2')

    stub_admin_user
    timesheet.projects = [project1, project2]
    
    timesheet.fetch_time_entries
    timesheet.time_entries.should include("Project 1")
    timesheet.time_entries.should include("Project 1 / Project 2")
  end

  it 'should fetch all the time entries on a project in the date range'
  it 'should fetch all the time entries on a project matching the activities'
  it 'should fetch all the time entries on a project matching the users'
end

describe Timesheet,'.fetch_time_entries as an administrator' do
  include TimesheetSpecHelper

  it 'should collect time entries for all users on each project' do
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project1.stub!(:name).and_return('Project 1')
    project2 = project_factory(2)
    project2.stub!(:name).and_return('Project 2')

    stub_admin_user
    timesheet.projects = [project1, project2] 

    timesheet.should_receive(:time_entries_for_all_users).with(project1).and_return([ ])
    timesheet.should_receive(:time_entries_for_all_users).with(project2).and_return([ ])
    timesheet.fetch_time_entries
  end
end

describe Timesheet,'.fetch_time_entries as a user with see_project_timesheet permission on a project' do
  include TimesheetSpecHelper

  it 'should collect time entries for all users' do
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project1.stub!(:name).and_return('Project 1')
    project2 = project_factory(2)
    project2.stub!(:name).and_return('Project 2')
    project3 = project_factory(3)
    project3.stub!(:name).and_return('Project 3')

    stub_manager_user([project1, project2])
    # Make user a 'non-manager' on project3 
    @current_user.stub!(:allowed_to?).with(:view_time_entries, project3).and_return(true)
    @current_user.stub!(:allowed_to?).with(:see_project_timesheets, project3).and_return(false)
    User.stub!(:current).and_return(@current_user)

    timesheet.projects = [project1, project2, project3]

    timesheet.should_receive(:time_entries_for_all_users).with(project1).and_return([ ])
    timesheet.should_receive(:time_entries_for_all_users).with(project2).and_return([ ])
    timesheet.should_receive(:time_entries_for_current_user).with(project3).and_return([ ])
    timesheet.fetch_time_entries
  end
end

describe Timesheet,'.fetch_time_entries as a user with view_time_entries permission on a project' do
  include TimesheetSpecHelper

  it 'should collect time entries for only themself' do
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project1.stub!(:name).and_return('Project 1')
    project2 = project_factory(2)
    project2.stub!(:name).and_return('Project 2')

    stub_normal_user([project1, project2])
    timesheet.projects = [project1, project2]

    timesheet.should_receive(:time_entries_for_current_user).with(project1).and_return([ ])
    timesheet.should_receive(:time_entries_for_current_user).with(project2).and_return([ ])
    timesheet.fetch_time_entries
  end
end

describe Timesheet,'.fetch_time_entries as a non-member of a project' do
  include TimesheetSpecHelper

  it 'should get no time entries' do
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project1.stub!(:name).and_return('Project 1')
    project2 = project_factory(2)
    project2.stub!(:name).and_return('Project 2')

    stub_non_member_user([project1, project2])
    timesheet.projects = [project1, project2]

    timesheet.should_not_receive(:time_entries_for_current_user).with(project1).and_return([ ])
    timesheet.should_not_receive(:time_entries_for_current_user).with(project2).and_return([ ])
    timesheet.fetch_time_entries
  end
end
