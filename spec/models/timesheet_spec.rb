require File.dirname(__FILE__) + '/../spec_helper'

describe Timesheet do
  it 'should not be an ActiveRecord class' do
    Timesheet.should_not be_a_kind_of(ActiveRecord::Base)
  end
  
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
end

describe Timesheet,'.fetch_time_entries' do
  it 'should clear .time_entries' do
    timesheet = Timesheet.new
    timesheet.time_entries = { :filled => 'data' }
    proc { 
      timesheet.fetch_time_entries
    }.should change(timesheet, :time_entries)
    
  end

  it 'should add a time_entry array for each project' do
    timesheet = Timesheet.new
    timesheet.date_from = Date.today.to_s
    timesheet.date_to = Date.today.to_s

    # First project
    project1 = mock_model(Project, :parent => nil)
    project1_te1 = mock_model(TimeEntry, :id => '100', :project_id => project1.id, :issue_id => '1', :hours => '5', :activity_id => '1', :spent_on => Date.today)
    project1_te2 = mock_model(TimeEntry, :id => '101', :project_id => project1.id, :issue_id => '1', :hours => '10', :activity_id => '1', :spent_on => Date.today)
    project1_time_entries_mock = mock('project1_time_entries_mock')
    project1_time_entries_mock.stub!(:find).and_return([project1_te1, project1_te2])
    project1.stub!(:time_entries).and_return(project1_time_entries_mock)
    project1.should_receive(:name).and_return('Project one')
    
    # Second project
    project2 = mock_model(Project, :parent => nil)
    project2_te1 = mock_model(TimeEntry, :id => '100', :project_id => project2.id, :issue_id => '2', :hours => '5', :activity_id => '1', :spent_on => Date.today)
    project2_te2 = mock_model(TimeEntry, :id => '101', :project_id => project2.id, :issue_id => '2', :hours => '10', :activity_id => '1', :spent_on => Date.today)
    project2_time_entries_mock = mock('project2_time_entries_mock')
    project2_time_entries_mock.stub!(:find).and_return([project2_te1, project2_te2])
    project2.stub!(:time_entries).and_return(project2_time_entries_mock)
    project2.should_receive(:name).and_return('Project two')
    
    
    timesheet.projects = [project1, project2]
    
    timesheet.fetch_time_entries
    timesheet.time_entries.should_not be_empty
    timesheet.time_entries.should have(2).things
  end
  
  it 'should use the project name for each time_entry array' do 
    timesheet = Timesheet.new
    timesheet.date_from = Date.today.to_s
    timesheet.date_to = Date.today.to_s

    # First project
    project1 = mock_model(Project, :parent => nil)
    project1_te1 = mock_model(TimeEntry, :id => '100', :project_id => project1.id, :issue_id => '1', :hours => '5', :activity_id => '1', :spent_on => Date.today)
    project1_te2 = mock_model(TimeEntry, :id => '101', :project_id => project1.id, :issue_id => '1', :hours => '10', :activity_id => '1', :spent_on => Date.today)
    project1_time_entries_mock = mock('project1_time_entries_mock')
    project1_time_entries_mock.stub!(:find).and_return([project1_te1, project1_te2])
    project1.stub!(:time_entries).and_return(project1_time_entries_mock)
    project1.should_receive(:name).and_return('Project one')
    
    # Second project
    project2 = mock_model(Project, :parent => nil)
    project2_te1 = mock_model(TimeEntry, :id => '100', :project_id => project2.id, :issue_id => '2', :hours => '5', :activity_id => '1', :spent_on => Date.today)
    project2_te2 = mock_model(TimeEntry, :id => '101', :project_id => project2.id, :issue_id => '2', :hours => '10', :activity_id => '1', :spent_on => Date.today)
    project2_time_entries_mock = mock('project2_time_entries_mock')
    project2_time_entries_mock.stub!(:find).and_return([project2_te1, project2_te2])
    project2.stub!(:time_entries).and_return(project2_time_entries_mock)
    project2.should_receive(:name).and_return('Project two')
    
    
    timesheet.projects = [project1, project2]
    
    timesheet.fetch_time_entries
    timesheet.time_entries.should include("Project one")
    timesheet.time_entries.should include("Project two")
  end
  it 'should add the parent project name for each time_entry array for sub-projects'
  it 'should fetch all the time entries on a project in the date range'
  it 'should fetch all the time entries on a project matching the activities'
  it 'should fetch all the time entries on a project matching the users'
end

