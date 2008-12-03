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
  
  def time_entry_factory(id, options = { })
    object_options = {
      :id => id,
      :to_param => id.to_s,
      :spent_on => Date.today,
    }.merge(options)
    
    time_entry = mock_model(TimeEntry, object_options)
    time_entry.stub!(:issue).and_return(options[:issue]) unless options[:issue].nil?
    return time_entry
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
    @current_user.stub!(:name).and_return("Administrator Bob")
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

  it 'should initialize activities to an Array' do 
    timesheet = Timesheet.new
    timesheet.activities.should be_a_kind_of(Array)
  end

  it 'should initialize users to an Array' do 
    timesheet = Timesheet.new
    timesheet.users.should be_a_kind_of(Array)
  end

  it 'should initialize sort to :project' do 
    timesheet = Timesheet.new
    timesheet.sort.should eql(:project)
  end

  it 'should initialize time_entries to the passed in options' do 
    data = { :test => true }
    timesheet = Timesheet.new({ :time_entries => data })
    timesheet.time_entries.should_not be_empty
    timesheet.time_entries.should eql(data)
  end

  it 'should initialize allowed_projects to the passed in options' do 
    data = ['project1', 'project2']
    timesheet = Timesheet.new({ :allowed_projects => data })
    timesheet.allowed_projects.should_not be_empty
    timesheet.allowed_projects.should eql(data)
  end

  it 'should initialize activities to the integers of the passed in options' do 
    act1 = mock('act1')
    act1.stub!(:to_i).and_return(200)
    act2 = mock('act2')
    act2.stub!(:to_i).and_return(300)
    data = [act1, act2]
    timesheet = Timesheet.new({ :activities => data })
    timesheet.activities.should_not be_empty
    timesheet.activities.should eql([200, 300])
  end

  it 'should initialize users to the ids of the passed in options' do 
    user1 = mock('user1')
    user1.stub!(:to_i).and_return(100)
    user2 = mock('user2')
    user2.stub!(:to_i).and_return(101)
    data = [user1, user2]
    timesheet = Timesheet.new({ :users => data })
    timesheet.users.should_not be_empty
    timesheet.users.should eql([100, 101])
  end

  it 'should initialize sort to the :user option when passed :user' do 
    timesheet = Timesheet.new({ :sort => :user })
    timesheet.sort.should eql(:user)
  end

  it 'should initialize sort to the :project option when passed :project' do 
    timesheet = Timesheet.new({ :sort => :project })
    timesheet.sort.should eql(:project)
  end

  it 'should initialize sort to the :issue option when passed :issue' do 
    timesheet = Timesheet.new({ :sort => :issue })
    timesheet.sort.should eql(:issue)
  end

  it 'should initialize sort to the :project option when passed an invalid sort' do 
    timesheet = Timesheet.new({ :sort => :invalid })
    timesheet.sort.should eql(:project)
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

  it 'should add a time_entry Hash for each project' do
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project2 = project_factory(2)

    stub_admin_user
    timesheet.projects = [project1, project2]

    timesheet.fetch_time_entries
    timesheet.time_entries.should_not be_empty
    timesheet.time_entries.should have(2).things
  end
  
  it 'should use the project name for each time_entry key' do 
    
    timesheet = timesheet_factory

    project1 = project_factory(1)
    project1.should_receive(:name).and_return('Project 1')
    project2 = project_factory(2)
    project2.should_receive(:name).and_return('Project 2')

    stub_admin_user
    timesheet.projects = [project1, project2]
    
    timesheet.fetch_time_entries
    timesheet.time_entries.keys.should include("Project 1")
    timesheet.time_entries.keys.should include("Project 2")
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
    timesheet.time_entries.keys.should include("Project 1")
    timesheet.time_entries.keys.should include("Project 1 / Project 2")
  end

  it 'should fetch all the time entries on a project in the date range'
  it 'should fetch all the time entries on a project matching the activities'
  it 'should fetch all the time entries on a project matching the users'
end

describe Timesheet,'.fetch_time_entries with user sorting' do
  include TimesheetSpecHelper
  
  it 'should clear .time_entries' do
    timesheet = Timesheet.new({ :sort => :user })
    timesheet.time_entries = { :filled => 'data' }
    proc { 
      timesheet.fetch_time_entries
    }.should change(timesheet, :time_entries)
    
  end

  it 'should add a time_entry array for each user' do
    stub_admin_user
    timesheet = timesheet_factory(:sort => :user, :users => [User.current.id])

    time_entries = [
                    time_entry_factory(1, { :user => User.current }),
                    time_entry_factory(2, { :user => User.current }),
                    time_entry_factory(3, { :user => User.current }),
                    time_entry_factory(4, { :user => User.current }),
                    time_entry_factory(5, { :user => User.current })
                   ]
    
    TimeEntry.stub!(:find).and_return(time_entries)
    User.stub!(:find_by_id).and_return(User.current)

    timesheet.fetch_time_entries
    timesheet.time_entries.should_not be_empty
    timesheet.time_entries.should have(1).thing # One user
  end
  
  it 'should use the user name for each time_entry array' do 
    stub_admin_user
    timesheet = timesheet_factory(:sort => :user, :users => [User.current.id])

    time_entries = [
                    time_entry_factory(1, { :user => User.current }),
                    time_entry_factory(2, { :user => User.current }),
                    time_entry_factory(3, { :user => User.current }),
                    time_entry_factory(4, { :user => User.current }),
                    time_entry_factory(5, { :user => User.current })
                   ]

    TimeEntry.stub!(:find).and_return(time_entries)
    User.stub!(:find_by_id).and_return(User.current)
    
    timesheet.fetch_time_entries
    timesheet.time_entries.keys.should include("Administrator Bob")
  end
end

describe Timesheet,'.fetch_time_entries with issue sorting' do
  include TimesheetSpecHelper

  it 'should clear .time_entries' do
    timesheet = Timesheet.new({ :sort => :issue })
    timesheet.time_entries = { :filled => 'data' }
    proc { 
      timesheet.fetch_time_entries
    }.should change(timesheet, :time_entries)
    
  end

  it 'should add a time_entry array for each project' do
    stub_admin_user
    project1 = project_factory(1)
    timesheet = timesheet_factory(:sort => :issue, :users => [User.current.id])
    timesheet.projects = [project1]

    @issue1 = mock_model(Issue, :id => 1, :to_param => '1', :project => project1)
    @issue2 = mock_model(Issue, :id => 1, :to_param => '1', :project => project1)
    @issue3 = mock_model(Issue, :id => 1, :to_param => '1', :project => project1)
    
    time_entry1 = time_entry_factory(1, { :user => User.current, :issue => @issue1 })
    time_entry2 = time_entry_factory(2, { :user => User.current, :issue => @issue1 })
    time_entry3 = time_entry_factory(3, { :user => User.current, :issue => @issue2 })
    time_entry4 = time_entry_factory(4, { :user => User.current, :issue => @issue2 })
    time_entry5 = time_entry_factory(5, { :user => User.current, :issue => @issue3 })

    project1.should_receive(:issues).and_return([@issue1, @issue2, @issue3])
    
    time_entries = [
                    time_entry1,
                    time_entry2,
                    time_entry3,
                    time_entry4,
                    time_entry5
                   ]
    
    timesheet.should_receive(:issue_time_entries_for_all_users).with(@issue1).and_return([time_entry1, time_entry2])
    timesheet.should_receive(:issue_time_entries_for_all_users).with(@issue2).and_return([time_entry3, time_entry4])
    timesheet.should_receive(:issue_time_entries_for_all_users).with(@issue3).and_return([time_entry5])
    
    timesheet.fetch_time_entries
    timesheet.time_entries.should_not be_empty
    timesheet.time_entries.should have(1).thing
  end
  
  it 'should use the project for each time_entry array' do 
    stub_admin_user
    project1 = project_factory(1)
    timesheet = timesheet_factory(:sort => :issue, :users => [User.current.id])
    timesheet.projects = [project1]

    @issue1 = mock_model(Issue, :id => 1, :to_param => '1', :project => project1)
    @issue2 = mock_model(Issue, :id => 1, :to_param => '1', :project => project1)
    @issue3 = mock_model(Issue, :id => 1, :to_param => '1', :project => project1)
    
    time_entry1 = time_entry_factory(1, { :user => User.current, :issue => @issue1 })
    time_entry2 = time_entry_factory(2, { :user => User.current, :issue => @issue1 })
    time_entry3 = time_entry_factory(3, { :user => User.current, :issue => @issue2 })
    time_entry4 = time_entry_factory(4, { :user => User.current, :issue => @issue2 })
    time_entry5 = time_entry_factory(5, { :user => User.current, :issue => @issue3 })

    project1.should_receive(:issues).and_return([@issue1, @issue2, @issue3])
    
    time_entries = [
                    time_entry1,
                    time_entry2,
                    time_entry3,
                    time_entry4,
                    time_entry5
                   ]
    
    timesheet.should_receive(:issue_time_entries_for_all_users).with(@issue1).and_return([time_entry1, time_entry2])
    timesheet.should_receive(:issue_time_entries_for_all_users).with(@issue2).and_return([time_entry3, time_entry4])
    timesheet.should_receive(:issue_time_entries_for_all_users).with(@issue3).and_return([time_entry5])
    
    timesheet.fetch_time_entries
    timesheet.time_entries.keys.should include(project1)
  end
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
