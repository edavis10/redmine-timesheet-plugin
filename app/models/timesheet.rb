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
      logs = project.time_entries.find(:all,
                                       :conditions => ['spent_on >= (?) AND spent_on <= (?) AND activity_id IN (?) AND user_id IN (?)',
                                                       self.date_from, self.date_to, self.activities, self.users ],
                                       :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                       :order => "spent_on ASC")
      # Append the parent project name
      if project.parent.nil?
        self.time_entries[project.name] = logs unless logs.empty?
      else
        self.time_entries[project.parent.name + ' / ' + project.name] = logs unless logs.empty?          
      end
    end
  end
end
