class Timesheet
  attr_accessor :date_from, :date_to, :projects, :activities, :users, :allowed_projects

  # Time entries on the Timesheet in the form of:
  #   project.name => {:logs => [time entries], :users => [users shown in logs] }
  #   project.name => {:logs => [time entries], :users => [users shown in logs] }
  # project.name could be the parent project name also
  attr_accessor :time_entries

  def initialize(options = { })
    self.projects = [ ]
    self.time_entries = options[:time_entries] || { }
    self.allowed_projects = options[:allowed_projects] || [ ]

    unless options[:activities].nil?
      self.activities = options[:activities].collect { |a| a.to_i }
    else
      self.activities =  Enumeration::get_values('ACTI').collect(&:id)
    end
    
    unless options[:users].nil?
      self.users = options[:users].collect { |u| u.to_i }
    else
      self.users = User.find(:all).collect(&:id)
    end
    
    
    self.date_from = options[:date_from] || Date.today.to_s
    self.date_to = options[:date_to] || Date.today.to_s
  end

  # Gets all the time_entries for all the projects
  def fetch_time_entries
    self.time_entries = { }
    self.projects.each do |project|
      logs = []
      users = []
      if User.current.admin?
        # Administrators can see all time entries
        logs = time_entries_for_all_users(project)
        users = logs.collect(&:user).uniq.sort
      elsif User.current.allowed_to?(:see_project_timesheets, project)
        # Users with the Role and correct permission can see all time entries
        logs = time_entries_for_all_users(project)
        users = logs.collect(&:user).uniq.sort
      elsif User.current.allowed_to?(:view_time_entries, project)
        # Users with permission to see their time entries
        logs = time_entries_for_current_user(project)
        users = logs.collect(&:user).uniq.sort
      else
        # Rest can see nothing
      end
      
      # Append the parent project name
      if project.parent.nil?
        unless logs.empty?
          self.time_entries[project.name] = { :logs => logs, :users => users } 
        end
      else
        unless logs.empty?
          self.time_entries[project.parent.name + ' / ' + project.name] = { :logs => logs, :users => users }
        end
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
