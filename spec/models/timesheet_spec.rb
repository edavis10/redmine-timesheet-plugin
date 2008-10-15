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
  it 'should clear .time_entries'
  it 'should add a time_entry array for each project'
  it 'should use the project name for each time_entry array'
  it 'should add the parent project name for each time_entry array for sub-projects'
  it 'should fetch all the time entries on a project in the date range'
  it 'should fetch all the time entries on a project matching the activities'
  it 'should fetch all the time entries on a project matching the users'
end

