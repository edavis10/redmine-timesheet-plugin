require File.dirname(__FILE__) + '/../test_helper'

module TimesheetSpecHelper
  def timesheet_factory(options={ })
    timesheet = Timesheet.new(options)
    timesheet.date_from ||= Date.today.to_s
    timesheet.date_to ||= Date.today.to_s
    timesheet.allowed_projects = options[:projects] if options[:projects]
    timesheet.projects = options[:projects] if options[:projects]
    
    return timesheet
  end
  
  def project_factory(id, options = { })
    object_options = { 
      :id => id,
      :trackers => [@tracker]
    }.merge(options)

    project = Project.generate!(object_options)
    project_te1 = TimeEntry.generate!(:project => project, :hours => '5', :activity => @activity, :spent_on => Date.today, :user_id => 1)
    project_te2 = TimeEntry.generate!(:project => project, :hours => '10', :activity => @activity, :spent_on => Date.today, :user_id => 1)
    
    return project
  end
  
  def time_entry_factory(id, options = { })
    object_options = {
      :id => id,
      :spent_on => Date.today,
    }.merge(options)

    time_entry = TimeEntry.generate!(object_options)
    return time_entry
  end

  def stub_non_member_user(projects)
    @current_user = User.generate_with_protected!(:admin => false, :firstname => "Non", :lastname => "Member")
    User.current = @current_user
  end
  
  def stub_normal_user(projects)
    @current_user = User.generate_with_protected!(:admin => false, :firstname => "Non", :lastname => "Member")
    projects.each do |project|
      Member.generate!(:principal => @current_user, :project => project)
    end
    User.current = @current_user
  end
  
  def stub_manager_user(projects)
    @current_user = User.generate_with_protected!(:admin => false, :firstname => "Non", :lastname => "Member")
    projects.each do |project|
      Member.generate!(:principal => @current_user, :project => project)
    end
    User.current = @current_user
  end
  
  def stub_admin_user
    @current_user = User.generate_with_protected!(:admin => true, :firstname => "Administrator", :lastname => "Bob")
    assert @current_user.admin?
    User.current = @current_user
  end

  def stub_common_csv_records(options={})
    @csv_tracker = @tracker
    @csv_project = options[:project] || Project.generate!(:name => 'Project Name', :trackers => [@csv_tracker])
    @csv_issue = options[:issue] # || Issue.generate_for_project!(@csv_project, :tracker => @csv_tracker, :priority => @issue_priority)
    @csv_activity ||= options[:activity] || TimeEntryActivity.generate!(:name => 'activity')
    @csv_user = options[:user] || User.current
    {
      :user => @csv_user,
      :activity => @csv_activity,
      :spent_on => '2009-04-05',
      :project => @csv_project,
      :comments => 'comments',
      :hours => 10.0,
      :issue => @csv_issue
    }
  end
end

class TimesheetTest < ActiveSupport::TestCase
  include TimesheetSpecHelper

  def setup
    @issue_priority = IssuePriority.generate!(:name => 'common_csv_records')
    @tracker = Tracker.generate!(:name => 'Tracker')
    @activity = TimeEntryActivity.generate!(:name => 'activity')
  end
  
  should 'not be an ActiveRecord class' do
    assert !Timesheet.new.is_a?(ActiveRecord::Base)
  end
  
  context "initializing" do
    should 'should initialize time_entries to an empty Hash' do 
      timesheet = Timesheet.new
      assert_kind_of Hash, timesheet.time_entries
      assert timesheet.time_entries.empty?
    end

    should 'should initialize projects to an empty Array' do 
      timesheet = Timesheet.new
      assert_kind_of Array, timesheet.projects
      assert timesheet.projects.empty?
    end

    should 'should initialize allowed_projects to an empty Array' do 
      timesheet = Timesheet.new
      assert_kind_of Array, timesheet.allowed_projects
      assert timesheet.allowed_projects.empty?
    end

    should 'should initialize activities to an Array' do 
      timesheet = Timesheet.new
      assert_kind_of Array, timesheet.activities
    end

    should 'should initialize users to an Array' do 
      timesheet = Timesheet.new
      assert_kind_of Array, timesheet.users
    end

    should 'should initialize sort to :project' do 
      timesheet = Timesheet.new
      assert_equal :project, timesheet.sort
    end

    should 'should initialize time_entries to the passed in options' do 
      data = { :test => true }
      timesheet = Timesheet.new({ :time_entries => data })
      assert !timesheet.time_entries.empty?
      assert_equal data, timesheet.time_entries
    end

    should 'should initialize allowed_projects to the passed in options' do 
      data = ['project1', 'project2']
      timesheet = Timesheet.new({ :allowed_projects => data })
      assert !timesheet.allowed_projects.empty?
      assert_equal data, timesheet.allowed_projects
    end

    should 'should initialize activities to the integers of the passed in options' do
      act1 = TimeEntryActivity.generate!
      act2 = TimeEntryActivity.generate!
      
      data = [act1.id, act2.id]
      timesheet = Timesheet.new({ :activities => data })
      assert !timesheet.activities.empty?
      assert_equal [act1.id, act2.id], timesheet.activities
    end

    should 'should initialize users to the ids of the passed in options' do 
      user1 = User.generate_with_protected!
      user2 = User.generate_with_protected!
      data = [user1.id, user2.id]

      timesheet = Timesheet.new({ :users => data })
      assert !timesheet.users.empty?
      assert_equal [user1.id, user2.id], timesheet.users
    end

    should 'should initialize sort to the :user option when passed :user' do 
      timesheet = Timesheet.new({ :sort => :user })
      assert_equal :user, timesheet.sort
    end

    should 'should initialize sort to the :project option when passed :project' do 
      timesheet = Timesheet.new({ :sort => :project })
      assert_equal :project, timesheet.sort
    end

    should 'should initialize sort to the :issue option when passed :issue' do 
      timesheet = Timesheet.new({ :sort => :issue })
      assert_equal :issue, timesheet.sort
    end

    should 'should initialize sort to the :project option when passed an invalid sort' do 
      timesheet = Timesheet.new({ :sort => :invalid })
      assert_equal :project, timesheet.sort
    end
  end

  context "#fetch_time_entries" do

    should 'should clear .time_entries' do
      timesheet = Timesheet.new
      timesheet.time_entries = { :filled => 'data' }

      previous = timesheet.time_entries

      timesheet.fetch_time_entries
      
      assert_not_same previous, timesheet.time_entries
    end

    should 'should add a time_entry Hash for each project' do
      timesheet = timesheet_factory

      project1 = project_factory(1)
      project2 = project_factory(2)

      stub_admin_user
      timesheet.projects = [project1, project2]

      timesheet.fetch_time_entries
      assert !timesheet.time_entries.empty?
      assert_equal 2, timesheet.time_entries.size
    end
    
    should 'should use the project name for each time_entry key' do 
      stub_admin_user
      project1 = project_factory(1, :name => 'Project 1')
      project2 = project_factory(2, :name => 'Project 2')
      
      timesheet = timesheet_factory(:users => [User.current.id], :activities => [@activity.id], :projects => [project1, project2])


      
      timesheet.fetch_time_entries
      assert_contains timesheet.time_entries.keys, "Project 1"
      assert_contains timesheet.time_entries.keys, "Project 2"
    end

    should 'should add the parent project name for each time_entry array for sub-projects' do
      timesheet = timesheet_factory

      project1 = project_factory(1, :name => 'Project 1')
      project2 = project_factory(2, :name => 'Project 2')
      project2.set_parent!(project1)

      stub_admin_user
      timesheet.projects = [project1, project2]
      
      timesheet.fetch_time_entries
      assert_contains timesheet.time_entries.keys, "Project 1"
      assert_contains timesheet.time_entries.keys, "Project 1 / Project 2"
    end

    should 'should fetch all the time entries on a project in the date range'
    should 'should fetch all the time entries on a project matching the activities'
    should 'should fetch all the time entries on a project matching the users'
  end

  context "#fetch_time_entries with user sorting" do
    setup do
      @project = Project.generate!(:trackers => [@tracker], :name => 'Project Name')
    end
    
    should 'should clear .time_entries' do
      stub_admin_user
      timesheet = Timesheet.new({ :sort => :user })
      timesheet.time_entries = { :filled => 'data' }

      previous = timesheet.time_entries

      timesheet.fetch_time_entries
      
      assert_not_same previous, timesheet.time_entries
    end

    should 'should add a time_entry array for each user' do
      stub_admin_user
      timesheet = timesheet_factory(:sort => :user, :users => [User.current.id], :projects => [@project], :activities => [@activity.id])

      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity)
      
      timesheet.fetch_time_entries
      assert !timesheet.time_entries.empty?
      assert_equal 1, timesheet.time_entries.size # One user
    end
    
    should 'should use the user name for each time_entry array' do 
      stub_admin_user
      @project = Project.generate!
      timesheet = timesheet_factory(:sort => :user, :users => [User.current.id], :projects => [@project.id], :activities => [@activity.id])

      
      time_entries = [
                      time_entry_factory(1, { :user => User.current, :activity => @activity, :project => @project }),
                      time_entry_factory(2, { :user => User.current, :activity => @activity, :project => @project }),
                      time_entry_factory(3, { :user => User.current, :activity => @activity, :project => @project }),
                      time_entry_factory(4, { :user => User.current, :activity => @activity, :project => @project }),
                      time_entry_factory(5, { :user => User.current, :activity => @activity, :project => @project })
                     ]

      timesheet.fetch_time_entries
      assert_contains timesheet.time_entries.keys, "Administrator Bob"
    end
  end

  context '#fetch_time_entries with issue sorting' do
    should 'should clear .time_entries' do
      timesheet = Timesheet.new({ :sort => :issue })
      timesheet.time_entries = { :filled => 'data' }

      previous = timesheet.time_entries

      timesheet.fetch_time_entries
      
      assert_not_same previous, timesheet.time_entries
    end

    should 'should add a time_entry array for each project' do
      stub_admin_user
      project1 = project_factory(1)
      timesheet = timesheet_factory(:sort => :issue, :users => [User.current.id])
      timesheet.projects = [project1]

      @issue1 = Issue.generate_for_project!(project1, :priority => @issue_priority)
      @issue2 = Issue.generate_for_project!(project1, :priority => @issue_priority)
      @issue3 = Issue.generate_for_project!(project1, :priority => @issue_priority)

      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue1)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue1)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue2)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue2)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue3)

      timesheet.fetch_time_entries
      assert !timesheet.time_entries.empty?
      assert_equal 1, timesheet.time_entries.size
    end
    
    should 'should use the project for each time_entry array' do 
      stub_admin_user
      project1 = project_factory(1)
      timesheet = timesheet_factory(:sort => :issue, :users => [User.current.id])
      timesheet.projects = [project1]

      @issue1 = Issue.generate_for_project!(project1, :priority => @issue_priority)
      @issue2 = Issue.generate_for_project!(project1, :priority => @issue_priority)
      @issue3 = Issue.generate_for_project!(project1, :priority => @issue_priority)
      
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue1)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue1)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue2)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue2)
      TimeEntry.generate!(:user => User.current, :project => @project, :activity => @activity, :issue => @issue3)

      timesheet.fetch_time_entries
      assert_contains timesheet.time_entries.keys, project1
    end
  end

  context "#fetch_time_entries as an administrator" do

    should 'should collect time entries for all users on each project' do
      timesheet = timesheet_factory

      project1 = project_factory(1, :name => "Project 1")
      project2 = project_factory(2, :name => "Project 2")

      stub_admin_user
      timesheet.projects = [project1, project2] 

      timesheet.fetch_time_entries
      flunk # Need to check responses
    end
  end

  context '#fetch_time_entries as a user with see_project_timesheet permission on a project' do

    should 'should collect time entries for all users' do
      timesheet = timesheet_factory

      project1 = project_factory(1, :name => "Project 1")
      project2 = project_factory(2, :name => "Project 2")
      project3 = project_factory(3, :name => "Project 3")

      stub_manager_user([project1, project2])
      # Make user a 'non-manager' on project3 
      timesheet.projects = [project1, project2, project3]

      timesheet.fetch_time_entries
      flunk # Need to check responses
    end
  end

  context '#fetch_time_entries as a user with view_time_entries permission on a project' do

    should 'should collect time entries for only themself' do
      timesheet = timesheet_factory

      project1 = project_factory(1, :name => 'Project 1')
      project2 = project_factory(2, :name => 'Project 2')

      stub_normal_user([project1, project2])
      timesheet.projects = [project1, project2]

      timesheet.fetch_time_entries
      flunk # Need to check response
    end
  end

  context '#fetch_time_entries as a non-member of a project' do

    should 'should get no time entries' do
      timesheet = timesheet_factory

      project1 = project_factory(1, :name => 'Proejct 1')
      project2 = project_factory(2, :name => 'Project 2')

      stub_non_member_user([project1, project2])
      timesheet.projects = [project1, project2]

      timesheet.fetch_time_entries
      assert timesheet.time_entries.empty?
    end
  end

  context '#period=' do
    
    context 'should set the date_to and date_from for' do
      setup do
        @date = Date.new(2009,2,4)
        Date.stubs(:today).returns(@date)
        @timesheet = Timesheet.new(:period_type => Timesheet::ValidPeriodType[:default])
      end
      
      should 'today' do
        @timesheet.period = 'today'
        assert_equal @date, @timesheet.date_from
        assert_equal @date, @timesheet.date_to
      end
      
      should 'yesterday' do
        @timesheet.period = 'yesterday'
        assert_equal @date.yesterday, @timesheet.date_from
        assert_equal @date.yesterday, @timesheet.date_to
      end
      
      should 'current_week' do
        @timesheet.period = 'current_week'
        assert_equal Date.new(2009,2,2), @timesheet.date_from
        assert_equal Date.new(2009,2,8), @timesheet.date_to
      end
      
      should 'last_week' do
        @timesheet.period = 'last_week'
        assert_equal Date.new(2009,1,26), @timesheet.date_from
        assert_equal Date.new(2009,2,1), @timesheet.date_to
      end
      
      should '7_days' do
        @timesheet.period = '7_days'
        assert_equal @date - 7, @timesheet.date_from
        assert_equal @date, @timesheet.date_to
      end
      
      should 'current_month' do
        @timesheet.period = 'current_month'
        assert_equal Date.new(2009,2,1), @timesheet.date_from
        assert_equal Date.new(2009,2,28), @timesheet.date_to
      end
      
      should 'last_month' do
        @timesheet.period = 'last_month'
        assert_equal Date.new(2009,1,1), @timesheet.date_from
        assert_equal Date.new(2009,1,31), @timesheet.date_to
      end
      
      should '30_days' do
        @timesheet.period = '30_days'
        assert_equal @date - 30, @timesheet.date_from
        assert_equal @date, @timesheet.date_to
      end
      
      should 'current_year' do
        @timesheet.period = 'current_year'
        assert_equal Date.new(2009,1,1), @timesheet.date_from
        assert_equal Date.new(2009,12,31), @timesheet.date_to
      end
      
      should 'all' do
        @timesheet.period = 'all'
        assert_equal nil, @timesheet.date_from
        assert_equal nil, @timesheet.date_to
      end
    end
  end

  context '#to_csv' do
    setup do
      stub_admin_user
      @another_user = User.generate_with_protected!(:admin => true, :firstname => 'Another', :lastname => 'user')
      @project = Project.generate!(:trackers => [@tracker], :name => 'Project Name')
    end

    context "sorted by :user" do
      should "should return a csv grouped by user" do
        timesheet = timesheet_factory(:sort => :user, :users => [User.current.id, @another_user.id], :projects => [@project.id], :activities => [@activity.id], :date_from => '2009-04-05', :date_to => '2009-04-05')
        issue = Issue.generate_for_project!(@project, :tracker => @tracker, :priority => @issue_priority)

        time_entries = [
                        time_entry_factory(1, stub_common_csv_records(:activity => @activity, :project => @project,:issue => issue).merge({})),
                        time_entry_factory(3, stub_common_csv_records(:activity => @activity, :project => @project,:issue => issue).merge({})),
                        time_entry_factory(4, stub_common_csv_records(:activity => @activity, :project => @project,:issue => issue).merge({})),
                        time_entry_factory(5, stub_common_csv_records(:activity => @activity, :project => @project,:issue => nil))
                       ]

        time_entries_another_user = [
                                     time_entry_factory(2, stub_common_csv_records(:project => @project, :issue => issue).merge({:user => @another_user }))
                                    ]

        timesheet.fetch_time_entries

        # trailing newline
        assert_equal [
                      "#,Date,Member,Activity,Project,Issue,Comment,Hours",
                      "1,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                      "3,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                      "4,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                      "5,2009-04-05,Administrator Bob,activity,Project Name,,comments,10.0",
                      "2,2009-04-05,Another user,activity,Project Name,Tracker #1,comments,10.0",
                     ].join("\n") + "\n", timesheet.to_csv
        
      end
    end

    context "sorted by :project" do
      should "should return a csv grouped by project" do

        another_project = Project.generate!(:trackers => [@tracker], :name => 'Another Project')
        timesheet = timesheet_factory(:sort => :project, :users => [User.current.id, @another_user.id], :projects => [@project, another_project], :activities => [@activity.id], :date_from => '2009-04-05', :date_to => '2009-04-05')
        issue = Issue.generate_for_project!(@project, :tracker => @tracker, :priority => @issue_priority)
        another_issue = Issue.generate_for_project!(another_project, :tracker => @tracker, :priority => @issue_priority)
        
        project_a_time_entries = [
                                  time_entry_factory(1, stub_common_csv_records({:activity => @activity, :project => @project,:issue => issue})),
                                  time_entry_factory(3, stub_common_csv_records({:activity => @activity, :project => @project,:issue => issue})),
                                  time_entry_factory(5, stub_common_csv_records({:activity => @activity, :project => @project,:issue => nil}))
                                 ]

        another_project_time_entries = [
                                        time_entry_factory(2, stub_common_csv_records({:activity => @activity,:user => @another_user, :project => another_project,:issue => another_issue })),
                                        time_entry_factory(4, stub_common_csv_records({:activity => @activity, :project => another_project,:issue => another_issue}))

                                       ]

        timesheet.fetch_time_entries
        # trailing newline
        assert_equal [
                      "#,Date,Member,Activity,Project,Issue,Comment,Hours",
                      "2,2009-04-05,Another user,activity,Another Project,Tracker #2,comments,10.0",
                      "4,2009-04-05,Administrator Bob,activity,Another Project,Tracker #2,comments,10.0",
                      "1,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                      "3,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                      "5,2009-04-05,Administrator Bob,activity,Project Name,,comments,10.0",
                     ].join("\n") + "\n", timesheet.to_csv
      end
    end

    context "sorted by :issue" do
      should "should return a csv grouped by issue" do
        another_project = Project.generate!(:trackers => [@tracker], :name => 'Another Project')

        @issue1 = Issue.generate_for_project!(@project, :tracker => @tracker, :priority => @issue_priority)
        @issue1.time_entries << time_entry_factory(1, stub_common_csv_records({:activity => @activity, :project => @project}))

        @issue2 = Issue.generate_for_project!(@project, :tracker => @tracker, :priority => @issue_priority)
        @issue2.time_entries << time_entry_factory(3, stub_common_csv_records({:activity => @activity, :project => @project}))

        @issue3 = Issue.generate_for_project!(another_project, :tracker => @tracker, :priority => @issue_priority)
        @issue3.time_entries << time_entry_factory(2, stub_common_csv_records({:user => @another_user, :activity => @activity, :project => another_project}))

        @issue4 = Issue.generate_for_project!(another_project, :tracker => @tracker, :priority => @issue_priority)
        @issue4.time_entries << time_entry_factory(4, stub_common_csv_records({:activity => @activity, :project => another_project}))
                                                                 
        timesheet = timesheet_factory(:sort => :issue, :users => [User.current.id, @another_user.id], :projects => [@project, another_project], :activities => [@activity.id], :date_from => '2009-04-05', :date_to => '2009-04-05')

        timesheet.fetch_time_entries
        assert_equal [
                      "#,Date,Member,Activity,Project,Issue,Comment,Hours",
                      "2,2009-04-05,Another user,activity,Another Project,Tracker #3,comments,10.0",
                      "4,2009-04-05,Administrator Bob,activity,Another Project,Tracker #4,comments,10.0",
                      "1,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                      "3,2009-04-05,Administrator Bob,activity,Project Name,Tracker #2,comments,10.0",
                     ].join("\n") + "\n", timesheet.to_csv

      end
    end
  end
end
