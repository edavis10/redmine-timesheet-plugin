  class Timesheet
  attr_accessor :date_from, :date_to, :projects, :activities, :users, :allowed_projects, :period, :period_type, :version, :order

  # Time entries on the Timesheet in the form of:
  #   project.name => {:logs => [time entries], :users => [users shown in logs] }
  #   project.name => {:logs => [time entries], :users => [users shown in logs] }
  # project.name could be the parent project name also
  attr_accessor :time_entries
  
  # Array of TimeEntry ids to fetch
  attr_accessor :potential_time_entry_ids

  # Sort time entries by this field
  attr_accessor :sort
  ValidSortOptions = {
    :project => 'Project',
    :user => 'User',
    :issue => 'Issue',
    :version => 'Version'
  }

  ValidPeriodType = {
    :free_period => 0,
    :default => 1
  }
  
  def initialize(options = { })
    self.projects = [ ]
    self.time_entries = options[:time_entries] || { }
    self.potential_time_entry_ids = options[:potential_time_entry_ids] || [ ]
    self.allowed_projects = options[:allowed_projects] || [ ]

    unless options[:activities].nil?
      self.activities = options[:activities].collect do |activity_id|
        # Include project-overridden activities
        activity = TimeEntryActivity.find(activity_id)
        project_activities = TimeEntryActivity.all(:conditions => ['parent_id IN (?)', activity.id]) if activity.parent_id.nil?
        project_activities ||= []
        
        [activity.id.to_i] + project_activities.collect(&:id)
      end.flatten.uniq.compact
    else
      self.activities =  TimeEntryActivity.all.collect { |a| a.id.to_i }
    end
    
    unless options[:users].nil?
      self.users = options[:users].collect { |u| u.to_i }
    else
      self.users = Timesheet.viewable_users.collect {|user| user.id.to_i }
    end

    if !options[:sort].nil? && options[:sort].respond_to?(:to_sym) && ValidSortOptions.keys.include?(options[:sort].to_sym)
      self.sort = options[:sort].to_sym
    else
      self.sort = :project
    end
    
    self.date_from = options[:date_from] || Date.today.to_s
    self.date_to = options[:date_to] || Date.today.to_s

    if options[:period_type] && ValidPeriodType.values.include?(options[:period_type].to_i)
      self.period_type = options[:period_type].to_i
    else
      self.period_type = ValidPeriodType[:free_period]
    end
    self.period = options[:period] || nil
    self.order = options[:order] || nil
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
    when :version
      fetch_time_entries_by_version
    else
      fetch_time_entries_by_project
    end
  end

  def period=(period)
    return if self.period_type == Timesheet::ValidPeriodType[:free_period]
    # Stolen from the TimelogController
    case period.to_s
    when 'today'
      self.date_from = self.date_to = Date.today
    when 'yesterday'
      self.date_from = self.date_to = Date.today - 1
    when 'current_week' # Mon -> Sun
      self.date_from = Date.today - (Date.today.cwday - 1)%7
      self.date_to = self.date_from + 6
    when 'last_week'
      self.date_from = Date.today - 7 - (Date.today.cwday - 1)%7
      self.date_to = self.date_from + 6
    when '7_days'
      self.date_from = Date.today - 7
      self.date_to = Date.today
    when 'current_month'
      self.date_from = Date.civil(Date.today.year, Date.today.month, 1)
      self.date_to = (self.date_from >> 1) - 1
    when 'last_month'
      self.date_from = Date.civil(Date.today.year, Date.today.month, 1) << 1
      self.date_to = (self.date_from >> 1) - 1
    when '30_days'
      self.date_from = Date.today - 30
      self.date_to = Date.today
    when 'current_year'
      self.date_from = Date.civil(Date.today.year, 1, 1)
      self.date_to = Date.civil(Date.today.year, 12, 31)
    when 'all'
      self.date_from = self.date_to = nil
    end
    self
  end

  def to_param
    {
      :projects => projects.collect(&:id),
      :date_from => date_from,
      :date_to => date_to,
      :activities => activities,
      :users => users,
      :sort => sort
    }
  end

  def to_csv
    returning '' do |out|
      FCSV.generate out do |csv|
        csv << csv_header

        # Write the CSV based on the group/sort
        case sort
        when :user, :project, :version
          time_entries.sort.each do |entryname, entry|
            entry[:logs].each do |e|
              csv << time_entry_to_csv(e)
            end
          end
        when :issue
          time_entries.sort.each do |project, entries|
            entries[:issues].sort {|a,b| a[0].id <=> b[0].id}.each do |issue, time_entries|
              time_entries.each do |e|
                csv << time_entry_to_csv(e)
              end
            end
          end
        end
      end
    end
  end

  def to_xlsx
    path ="#{RAILS_ROOT}/files/timesheet.xlsx"   
    FileUtils.rm(path) if FileTest.exists?(path)

  case sort
  when :user, :project, :version
    SimpleXlsx::Serializer.new(path) do |doc|
      doc.add_sheet("Sesit") do |sheet|
        sheet.add_row csv_header
        time_entries.sort.each do |entryname, entry|
          entry[:logs].each do |e|
            sheet.add_row time_entry_to_csv(e)
          end
        end
      end
    end
  end

  return path

  end

  def self.viewable_users
    if Setting['plugin_timesheet_plugin'].present? && Setting['plugin_timesheet_plugin']['user_status'] == 'all'
      user_scope = User.all
    else
      user_scope = User.active
    end
    
    user_scope.select {|user|
      user.allowed_to?(:log_time, nil, :global => true)
    }
  end
  
  protected

  def csv_header
    csv_data = [
                '#',
                l(:label_date),
                l(:label_member),
                l(:label_activity),
                l(:label_project),
                l(:label_issue),
                "#{l(:label_issue)} #{l(:field_subject)}",
                l(:field_comments),
                l(:field_hours)
               ]
    Redmine::Hook.call_hook(:plugin_timesheet_model_timesheet_csv_header, { :timesheet => self, :csv_data => csv_data})
    return csv_data
  end

  def time_entry_to_csv(time_entry)
    csv_data = [
                time_entry.id,
                time_entry.spent_on,
                time_entry.user.name,
                time_entry.activity.name,
                time_entry.project.name,
                ("#{time_entry.issue.tracker.name} ##{time_entry.issue.id}" if time_entry.issue),
                (time_entry.issue.subject if time_entry.issue),
                time_entry.comments,
                time_entry.hours
               ]
    Redmine::Hook.call_hook(:plugin_timesheet_model_timesheet_time_entry_to_csv, { :timesheet => self, :time_entry => time_entry, :csv_data => csv_data})
    return csv_data
  end

  # Array of users to find
  # String of extra conditions to add onto the query (AND)
  def conditions(users, extra_conditions=nil)
    if self.potential_time_entry_ids.empty?
      if self.date_from.present? && self.date_to.present?
        conditions = ["spent_on >= (:from) AND spent_on <= (:to) AND #{TimeEntry.table_name}.project_id IN (:projects) AND user_id IN (:users) AND activity_id IN (:activities)",
                      {
                        :from => self.date_from,
                        :to => self.date_to,
                        :projects => self.projects,
                        :activities => self.activities,
                        :users => users
                      }]
      else # All time
        conditions = ["#{TimeEntry.table_name}.project_id IN (:projects) AND user_id IN (:users) AND activity_id IN (:activities)",
                      {
                        :projects => self.projects,
                        :activities => self.activities,
                        :users => users
                      }]
      end
    else
      conditions = ["user_id IN (:users) AND #{TimeEntry.table_name}.id IN (:potential_time_entries)",
                    {
                      :users => users,
                      :potential_time_entries => self.potential_time_entry_ids
                    }]
    end

    if extra_conditions
      conditions[0] = conditions.first + ' AND ' + extra_conditions
    end
      
    Redmine::Hook.call_hook(:plugin_timesheet_model_timesheet_conditions, { :timesheet => self, :conditions => conditions})
    return conditions
  end

  def includes
    includes = [:activity, :user, :project, {:issue => [:tracker, :assigned_to, :priority]}]
    Redmine::Hook.call_hook(:plugin_timesheet_model_timesheet_includes, { :timesheet => self, :includes => includes})
    return includes
  end

  private

  
  def time_entries_for_all_users(project)
    return project.time_entries.find(:all,
                                     :conditions => self.conditions(self.users),
                                     :include => self.includes,
                                     :order => self.order)
  end
  
  def time_entries_for_current_user(project)
    return project.time_entries.find(:all,
                                     :conditions => self.conditions(User.current.id),
                                     :include => self.includes,
                                     :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                     :order => self.order)
  end

  def empty_version_time_entries_for_all_users(project)
    return project.time_entries.find(:all,
                                     :conditions => self.conditions(self.users, "version_id is NULL"),
                                     :include => self.includes,
                                     :order => self.order)
  end

  def empty_version_time_entries_for_current_user(project)
    return project.time_entries.find(:all,
                                     :conditions => self.conditions(User.current.id, "version_id is NULL"),
                                     :include => self.includes,
                                     :order => self.order)
  end

  def version_time_entries_for_all_users(version)
    return version.time_entries.find(:all,
                                     :conditions => self.conditions(self.users),
                                     :include => self.includes,
                                     :order => self.order)
  end
  
  def version_time_entries_for_current_user(version)
    return version.time_entries.find(:all,
                                     :conditions => self.conditions(User.current.id),
                                     :include => self.includes,
                                     :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                     :order => self.order)
  end
  
  def issue_time_entries_for_all_users(issue)
    return issue.time_entries.find(:all,
                                   :conditions => self.conditions(self.users),
                                   :include => self.includes,
                                   :include => [:activity, :user],
                                   :order => self.order)
  end
  
  def issue_time_entries_for_current_user(issue)
    return issue.time_entries.find(:all,
                                   :conditions => self.conditions(User.current.id),
                                   :include => self.includes,
                                   :include => [:activity, :user],
                                   :order => self.order)
  end
  
  def time_entries_for_user(user, options={})
    extra_conditions = options.delete(:conditions)
    
    return TimeEntry.find(:all,
                          :conditions => self.conditions([user], extra_conditions),
                          :include => self.includes,
                          :order => self.order
                          )
  end

  def fetch_time_entries_by_version
    self.projects.each do |project|
      project.versions.each do |version|
        unless version.nil?
          logs = []
          users = []

          if User.current.admin?
            # Administrators can see all time entries
            logs = version_time_entries_for_all_users(version)
            users = logs.collect(&:user).uniq.sort
          elsif User.current.allowed_to_on_single_potentially_archived_project?(:see_project_timesheets, project)
            # Users with the Role and correct permission can see all time entries
            logs = time_entries_for_all_users(project)
            users = logs.collect(&:user).uniq.sort
          elsif User.current.allowed_to_on_single_potentially_archived_project?(:view_time_entries, project)
            # Users with permission to see their time entries
            logs = version_time_entries_for_current_user(version)
            users = logs.collect(&:user).uniq.sort
          else
            # Rest can see nothing
          end
          
          # Append project and version name
          unless logs.empty?
            self.time_entries[project.name + ' / v: ' + version.name] = { :logs => logs, :users => users } 
          end
        end
      end

    logs = []
    users = []
    if User.current.admin?
      # Administrators can see all time entries
      logs = empty_version_time_entries_for_all_users(project)
      users = logs.collect(&:user).uniq.sort
    elsif User.current.allowed_to_on_single_potentially_archived_project?(:see_project_timesheets, project)
      # Users with the Role and correct permission can see all time entries
      logs = time_entries_for_all_users(project)
      users = logs.collect(&:user).uniq.sort
    elsif User.current.allowed_to_on_single_potentially_archived_project?(:view_time_entries, project)
      # Users with permission to see their time entries
      logs = empty_version_time_entries_for_current_user(project)
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
  
  def fetch_time_entries_by_project
    self.projects.each do |project|
      logs = []
      users = []
      if User.current.admin?
        # Administrators can see all time entries
        logs = time_entries_for_all_users(project)
        users = logs.collect(&:user).uniq.sort
      elsif User.current.allowed_to_on_single_potentially_archived_project?(:see_project_timesheets, project)
        # Users with the Role and correct permission can see all time entries
        logs = time_entries_for_all_users(project)
        users = logs.collect(&:user).uniq.sort
      elsif User.current.allowed_to_on_single_potentially_archived_project?(:view_time_entries, project)
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
      elsif User.current.allowed_to_on_single_potentially_archived_project?(:see_project_timesheets, nil, :global => true)
        # User can see project timesheets in at least once place, so
        # fetch the user timelogs for those projects
        logs = time_entries_for_user(user_id, :conditions => Project.allowed_to_condition(User.current, :see_project_timesheets))
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
        elsif User.current.allowed_to_on_single_potentially_archived_project?(:see_project_timesheets, project)
          # Users with the Role and correct permission can see all time entries
          logs << issue_time_entries_for_all_users(issue)
        elsif User.current.allowed_to_on_single_potentially_archived_project?(:view_time_entries, project)
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


  def l(*args)
    I18n.t(*args)
  end

  # def number_with_custom_delimiter(number)
  #   number.to_s.gsub('.', Setting.plugin_timesheet_plugin['custom_delimiter'])
  # end
end
