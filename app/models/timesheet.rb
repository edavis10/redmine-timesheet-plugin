class Timesheet
  attr_accessor :date_from, :date_to, :projects, :activities, :users, :allowed_projects

  # Time entries on the Timesheet in the form of:
  #   project.name => [entries]
  #   project.name => [entries]
  # project.name could be the parent project name also
  attr_accessor :time_entries
  
  def initialize(options = { })
    self.time_entries = options[:time_entries] || { }
    self.projects = options[:projects] || [ ]
    self.allowed_projects = options[:allowed_projects] || [ ]
    self.activities = options[:activities] || [ ]
    self.users = options[:users] || [ ]
  end
  
  # Gets all the time_entries for all the projects
  def fetch_time_entries
    self.time_entries = { }
    self.projects.each do |project|
      if User.current.admin?
        # Administrators can see all time entries
        logs = time_entries_for_all_users(project)
      elsif User.current.allowed_to?(:see_project_timesheets, project)
        # Users with the Role and correct permission can see all time entries
        logs = time_entries_for_all_users(project)
      elsif User.current.allowed_to?(:view_time_entries, project)
        # Users with permission to see their time entries
        logs = time_entries_for_current_user(project)
      else
        # Rest can see nothing
        logs = []
      end
      
      # Append the parent project name
      if project.parent.nil?
        self.time_entries[project.name] = logs unless logs.empty?
      else
        self.time_entries[project.parent.name + ' / ' + project.name] = logs unless logs.empty?          
      end
    end
  end
  
  private

  
  def time_entries_for_all_users(project)
    return project.time_entries.find(:all,
                                     :conditions => ['spent_on >= (?) AND spent_on <= (?) AND activity_id IN (?) AND user_id IN (?)',
                                                     self.date_from, self.date_to, self.activities, self.users ],
                                     :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                     :order => "spent_on ASC")
  end
  
  def time_entries_for_current_user(project)
    return project.time_entries.find(:all,
                                     :conditions => ['spent_on >= (?) AND spent_on <= (?) AND activity_id IN (?) AND user_id = (?)',
                                                     self.date_from, self.date_to, self.activities, User.current.id ],
                                     :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                     :order => "spent_on ASC")
  end
end
