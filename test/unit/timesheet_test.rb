require File.dirname(__FILE__) + '/../test_helper'

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
      :spent_on => Date.today,
    }.merge(options)

    time_entry = TimeEntry.generate!(object_options)
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
    @current_user = User.generate_with_protected!(:admin => true, :firstname => "Administrator", :lastname => "Bob")
    assert @current_user.admin?
    User.current = @current_user
  end

  def stub_common_csv_records
    {
      :user => User.current,
      :activity => stub('Activity', :name => 'activity'),
      :spent_on => '2009-04-05',
      :project => mock_model(Project, :name => 'Project Name'),
      :comments => 'comments',
      :hours => 10.0,
      :issue => mock_model(Issue, :id => 1, :tracker => mock_model(Tracker, :name => 'Tracker'))
    }
  end
end

class TimesheetTest < ActiveSupport::TestCase
  include TimesheetSpecHelper
  
  should 'not be an ActiveRecord class' do
    assert_kind_of !ActionRecord::Base, Timesheet
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

      assert_difference('timesheet.time_entries') do
        timesheet.fetch_time_entries
      end
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
      
      timesheet = timesheet_factory

      project1 = project_factory(1)
      project1.should_receive(:name).and_return('Project 1')
      project2 = project_factory(2)
      project2.should_receive(:name).and_return('Project 2')

      stub_admin_user
      timesheet.projects = [project1, project2]
      
      timesheet.fetch_time_entries
      assert_contains timesheet.time_entries.keys, "Project 1"
      assert_contains timesheet.time_entries.keys, "Project 2"
    end

    should 'should add the parent project name for each time_entry array for sub-projects' do
      timesheet = timesheet_factory

      project1 = project_factory(1)
      project1.should_receive(:name).twice.and_return('Project 1')
      project2 = project_factory(2, :parent => project1 )
      project2.should_receive(:name).and_return('Project 2')

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
    
    should 'should clear .time_entries' do
      stub_admin_user
      timesheet = Timesheet.new({ :sort => :user })
      timesheet.time_entries = { :filled => 'data' }
      proc { 
        timesheet.fetch_time_entries
      }.should change(timesheet, :time_entries)
      
    end

    should 'should add a time_entry array for each user' do
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
    
    should 'should use the user name for each time_entry array' do 
      stub_admin_user
      activity = TimeEntryActivity.generate!
      timesheet = timesheet_factory(:sort => :user, :users => [User.current.id])

      project = Project.generate!
      
      time_entries = [
                      time_entry_factory(1, { :user => User.current, :activity => activity, :project => project }),
                      time_entry_factory(2, { :user => User.current, :activity => activity, :project => project }),
                      time_entry_factory(3, { :user => User.current, :activity => activity, :project => project }),
                      time_entry_factory(4, { :user => User.current, :activity => activity, :project => project }),
                      time_entry_factory(5, { :user => User.current, :activity => activity, :project => project })
                     ]

      timesheet.allowed_projects << project.id
      timesheet.projects << project.id
      
      timesheet.fetch_time_entries
      assert_contains timesheet.time_entries.keys, "Administrator Bob"
    end
  end

  context '#fetch_time_entries with issue sorting' do

    should 'should clear .time_entries' do
      timesheet = Timesheet.new({ :sort => :issue })
      timesheet.time_entries = { :filled => 'data' }
      proc { 
        timesheet.fetch_time_entries
      }.should change(timesheet, :time_entries)
      
    end

    should 'should add a time_entry array for each project' do
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
    
    should 'should use the project for each time_entry array' do 
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

  context "#fetch_time_entries as an administrator" do

    should 'should collect time entries for all users on each project' do
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

  context '#fetch_time_entries as a user with see_project_timesheet permission on a project' do

    should 'should collect time entries for all users' do
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

  context '#fetch_time_entries as a user with view_time_entries permission on a project' do

    should 'should collect time entries for only themself' do
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

  context '#fetch_time_entries as a non-member of a project' do

    should 'should get no time entries' do
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

  context '#period=' do
    
    context 'should set the date_to and date_from for' do
      setup do
        @date = Date.new(2009,2,4)
        Date.stub!(:today).and_return(@date)
        @timesheet = Timesheet.new(:period_type => Timesheet::ValidPeriodType[:default])
      end
      
      should 'today' do
        @timesheet.should_receive(:date_from=).with(@date)
        @timesheet.should_receive(:date_to=).with(@date)
        @timesheet.period = 'today'
      end
      
      should 'yesterday' do
        @timesheet.should_receive(:date_from=).with(@date.yesterday)
        @timesheet.should_receive(:date_to=).with(@date.yesterday)
        @timesheet.period = 'yesterday'
      end
      
      should 'current_week' do
        @timesheet.should_receive(:date_from=).with(Date.new(2009, 2, 2))
        @timesheet.should_receive(:date_from).and_return(Date.new(2009, 2, 2))
        @timesheet.should_receive(:date_to=).with(Date.new(2009, 2, 8))
        @timesheet.period = 'current_week'
      end
      
      should 'last_week' do
        @timesheet.should_receive(:date_from=).with(Date.new(2009, 1, 26))
        @timesheet.should_receive(:date_from).and_return(Date.new(2009, 1, 26))
        @timesheet.should_receive(:date_to=).with(Date.new(2009, 2, 1))
        @timesheet.period = 'last_week'
      end
      
      should '7_days' do
        @timesheet.should_receive(:date_from=).with(@date - 7)
        @timesheet.should_receive(:date_to=).with(@date)
        @timesheet.period = '7_days'
      end
      
      should 'current_month' do
        @timesheet.should_receive(:date_from=).with(Date.new(2009, 2, 1))
        @timesheet.should_receive(:date_from).and_return(Date.new(2009, 2, 1))
        @timesheet.should_receive(:date_to=).with(Date.new(2009, 2, 28))
        @timesheet.period = 'current_month'
      end
      
      should 'last_month' do
        @timesheet.should_receive(:date_from=).with(Date.new(2009, 1, 1))
        @timesheet.should_receive(:date_from).and_return(Date.new(2009, 1, 1))
        @timesheet.should_receive(:date_to=).with(Date.new(2009, 1, 31))
        @timesheet.period = 'last_month'
      end
      
      should '30_days' do
        @timesheet.should_receive(:date_from=).with(@date - 30)
        @timesheet.should_receive(:date_to=).with(@date)
        @timesheet.period = '30_days'
      end
      
      should 'current_year' do
        @timesheet.should_receive(:date_from=).with(Date.new(2009,1,1))
        @timesheet.should_receive(:date_to=).with(Date.new(2009,12,31))
        @timesheet.period = 'current_year'
      end
      
      should 'all' do
        @timesheet.should_receive(:date_from=).with(nil)
        @timesheet.should_receive(:date_to=).with(nil)
        @timesheet.period = 'all'
      end
    end
  end

  context '#to_csv' do
    

    setup do
      stub_admin_user
      @another_user = mock_model(User, :admin? => true, :allowed_to? => true, :name => "Another user")
      @another_user.stub!(:<=>).with(User.current).and_return(-1)
    end

    context "sorted by :user" do
      should "should return a csv grouped by user" do
        timesheet = timesheet_factory(:sort => :user, :users => [User.current.id, @another_user.id])

        time_entries = [
                        time_entry_factory(1, stub_common_csv_records.merge({})),
                        time_entry_factory(3, stub_common_csv_records.merge({})),
                        time_entry_factory(4, stub_common_csv_records.merge({})),
                        time_entry_factory(5, stub_common_csv_records.merge({:issue => nil}))
                       ]

        time_entries_another_user = [
                                     time_entry_factory(2, stub_common_csv_records.merge({:user => @another_user }))
                                    ]


        timesheet.stub!(:time_entries_for_user).with(User.current.id).and_return(time_entries)
        timesheet.stub!(:time_entries_for_user).with(@another_user.id).and_return(time_entries_another_user)
        User.stub!(:find_by_id).with(User.current.id).and_return(User.current)
        User.stub!(:find_by_id).with(@another_user.id).and_return(@another_user)

        timesheet.fetch_time_entries
        timesheet.to_csv.should == [
                                    "#,Date,Member,Activity,Project,Issue,Comment,Hours",
                                    "1,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                                    "3,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                                    "4,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                                    "5,2009-04-05,Administrator Bob,activity,Project Name,,comments,10.0",
                                    "2,2009-04-05,Another user,activity,Project Name,Tracker #1,comments,10.0",
                                   ].join("\n") + "\n" # trailing newline
      end
    end

    context "sorted by :project" do
      should "should return a csv grouped by project" do
        project_a = mock_model(Project, :name => 'Project Name', :parent => nil)
        another_project = mock_model(Project, :name => 'Another Project', :parent => nil)
        timesheet = timesheet_factory(:sort => :project, :users => [User.current.id, @another_user.id])
        timesheet.projects = [project_a, another_project]
        
        project_a_time_entries = [
                                  time_entry_factory(1, stub_common_csv_records.merge({:project => project_a})),
                                  time_entry_factory(3, stub_common_csv_records.merge({:project => project_a})),
                                  time_entry_factory(5, stub_common_csv_records.merge({:issue => nil}))
                                 ]

        another_project_time_entries = [
                                        time_entry_factory(2, stub_common_csv_records.merge({:user => @another_user, :project => another_project })),
                                        time_entry_factory(4, stub_common_csv_records.merge({:project => another_project})),

                                       ]

        project_a.stub!(:time_entries).and_return do
          te = mock('TimeEntryProxy')
          te.stub!(:find).and_return(project_a_time_entries)
          te
        end

        another_project.stub!(:time_entries).and_return do
          te = mock('TimeEntryProxy')
          te.stub!(:find).and_return(another_project_time_entries)
          te
        end

        User.stub!(:find_by_id).with(User.current.id).and_return(User.current)
        User.stub!(:find_by_id).with(@another_user.id).and_return(@another_user)

        timesheet.fetch_time_entries
        timesheet.to_csv.should == [
                                    "#,Date,Member,Activity,Project,Issue,Comment,Hours",
                                    "2,2009-04-05,Another user,activity,Another Project,Tracker #1,comments,10.0",
                                    "4,2009-04-05,Administrator Bob,activity,Another Project,Tracker #1,comments,10.0",
                                    "1,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                                    "3,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                                    "5,2009-04-05,Administrator Bob,activity,Project Name,,comments,10.0",
                                   ].join("\n") + "\n" # trailing newline
      end
    end

    context "sorted by :issue" do
      should "should return a csv grouped by issue" do
        # Ignore the nasty mocks here, they will be gone once this is
        # moved to shoulda and object_daddy
        project_a = mock_model(Project, :name => 'Project Name', :parent => nil)
        another_project = mock_model(Project, :name => 'Another Project', :parent => nil)
        project_a.stub!(:<=>).with(another_project).and_return(1)
        another_project.stub!(:<=>).with(project_a).and_return(-1)
        
        @issue_1 = mock_model(Issue, :id => 1, :tracker => mock_model(Tracker, :name => 'Tracker'))
        @issue_1.stub!(:time_entries).and_return do
          te = mock('TimeEntryProxy')
          te.stub!(:find).and_return(time_entry_factory(1, stub_common_csv_records.merge({:project => project_a, :issue => @issue_1})))
          te
        end

        @issue_2 = mock_model(Issue, :id => 2, :tracker => mock_model(Tracker, :name => 'Tracker'))
        @issue_2.stub!(:time_entries).and_return do
          te = mock('TimeEntryProxy')
          te.stub!(:find).and_return(time_entry_factory(3, stub_common_csv_records.merge({:project => project_a, :issue => @issue_2})))
          te
        end
        
        @issue_3 = mock_model(Issue, :id => 3, :tracker => mock_model(Tracker, :name => 'Tracker'))
        @issue_3.stub!(:time_entries).and_return do
          te = mock('TimeEntryProxy')
          te.stub!(:find).and_return(time_entry_factory(2, stub_common_csv_records.merge({:project => another_project, :issue => @issue_3, :user => @another_user})))
          te
        end

        @issue_4 = mock_model(Issue, :id => 4, :tracker => mock_model(Tracker, :name => 'Tracker'))
        @issue_4.stub!(:time_entries).and_return do
          te = mock('TimeEntryProxy')
          te.stub!(:find).and_return(time_entry_factory(4, stub_common_csv_records.merge({:project => another_project, :issue => @issue_4})))
          te
        end
        
        project_a.stub!(:issues).and_return([@issue_1, @issue_2])
        another_project.stub!(:issues).and_return([@issue_3, @issue_4])

        timesheet = timesheet_factory(:sort => :issue, :users => [User.current.id, @another_user.id])
        timesheet.projects = [project_a, another_project]
        
        User.stub!(:find_by_id).with(User.current.id).and_return(User.current)
        User.stub!(:find_by_id).with(@another_user.id).and_return(@another_user)

        timesheet.fetch_time_entries
        timesheet.to_csv.should == [
                                    "#,Date,Member,Activity,Project,Issue,Comment,Hours",
                                    "2,2009-04-05,Another user,activity,Another Project,Tracker #3,comments,10.0",
                                    "4,2009-04-05,Administrator Bob,activity,Another Project,Tracker #4,comments,10.0",
                                    "1,2009-04-05,Administrator Bob,activity,Project Name,Tracker #1,comments,10.0",
                                    "3,2009-04-05,Administrator Bob,activity,Project Name,Tracker #2,comments,10.0",
                                   ].join("\n") + "\n" # trailing newline

      end
    end
  end
end
