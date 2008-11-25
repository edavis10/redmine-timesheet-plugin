class Timesheet
  attr_accessor :date_from, :date_to, :projects, :activities, :users, :allowed_projects

  # Time entries on the Timesheet in the form of:
  #   project.name => {:logs => [time entries], :users => [users shown in logs] }
  #   project.name => {:logs => [time entries], :users => [users shown in logs] }
  # project.name could be the parent project name also
  attr_accessor :time_entries

  # Sort time entries by this field
  attr_accessor :sort
  ValidSortOptions = {
    :project => 'Project',
    :user => 'User',
    :issue => 'Issue'
  }
  
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

    if !options[:sort].nil? && options[:sort].respond_to?(:to_sym) && ValidSortOptions.keys.include?(options[:sort].to_sym)
      self.sort = options[:sort].to_sym
    else
      self.sort = :project
    end
    
    self.date_from = options[:date_from] || Date.today.to_s
    self.date_to = options[:date_to] || Date.today.to_s
  end

  # Gets all the time_entries for all the projects
  def fetch_time_entries
    self.time_entries = { }
    case self.sort
    when :project
      fetch_time_entries_by_project
    when :user
      fetch_time_entries_by_user
    when :issue
      fetch_time_entries_by_issue
    else
      fetch_time_entries_by_project
    end
  end
  
  protected

  def conditions(users)
    conditions = ['spent_on >= (?) AND spent_on <= (?) AND activity_id IN (?) AND user_id IN (?)',
                  self.date_from, self.date_to, self.activities, users ]

    Redmine::Hook.call_hook(:plugin_timesheet_model_timesheet_conditions, { :timesheet => self, :conditions => conditions})
    return conditions
  end

  private

  
  def time_entries_for_all_users(project)
    return project.time_entries.find(:all,
                                     :conditions => self.conditions(self.users),
                                     :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                     :order => "spent_on ASC")
  end
  
  def time_entries_for_current_user(project)
    return project.time_entries.find(:all,
                                     :conditions => self.conditions(User.current.id),
                                     :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                     :order => "spent_on ASC")
  end
  
  def issue_time_entries_for_all_users(issue)
    return issue.time_entries.find(:all,
                                   :conditions => self.conditions(self.users),
                                   :include => [:activity, :user],
                                   :order => "spent_on ASC")
  end
  
  def issue_time_entries_for_current_user(issue)
    return issue.time_entries.find(:all,
                                   :conditions => self.conditions(User.current.id),
                                   :include => [:activity, :user],
                                   :order => "spent_on ASC")
  end
  
  def time_entries_for_user(user)
    return TimeEntry.find(:all,
                          :conditions => self.conditions([user]),
                          :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                          :order => "spent_on ASC"
                          )
  end
  
  def fetch_time_entries_by_project
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
  
  def fetch_time_entries_by_user
    self.users.each do |user_id|
      logs = []
      if User.current.admin?
        # Administrators can see all time entries
        logs = time_entries_for_user(user_id)
      elsif User.current.id == user_id
        # Users can see their own their time entries
        logs = time_entries_for_user(user_id)
      else
        # Rest can see nothing
      end
      
      unless logs.empty?
        user = User.find_by_id(user_id)
        self.time_entries[user.name] = { :logs => logs }  unless user.nil?
      end
    end
  end
  
  #   project => { :users => [users shown in logs],
  #                :issues => 
  #                  { issue => {:logs => [time entries],
  #                    issue => {:logs => [time entries],
  #                    issue => {:logs => [time entries]}
  #     
  def fetch_time_entries_by_issue
    self.projects.each do |project|
      logs = []
      users = []
      project.issues.each do |issue|
        if User.current.admin?
          # Administrators can see all time entries
          logs << issue_time_entries_for_all_users(issue)
        elsif User.current.allowed_to?(:see_project_timesheets, project)
          # Users with the Role and correct permission can see all time entries
          logs << issue_time_entries_for_all_users(issue)
        elsif User.current.allowed_to?(:view_time_entries, project)
          # Users with permission to see their time entries
          logs << issue_time_entries_for_current_user(issue)
        else
          # Rest can see nothing
        end
      end

      logs.flatten! if logs.respond_to?(:flatten!)
      logs.uniq! if logs.respond_to?(:uniq!)
      
      unless logs.empty?
        users << logs.collect(&:user).uniq.sort

        
        issues = logs.collect(&:issue).uniq
        issue_logs = { }
        issues.each do |issue|
          issue_logs[issue] = logs.find_all {|time_log| time_log.issue == issue } # TimeEntry is for this issue
        end
        
        # TODO: TE without an issue
        
        self.time_entries[project] = { :issues => issue_logs, :users => users}
      end
    end
  end
  
end
