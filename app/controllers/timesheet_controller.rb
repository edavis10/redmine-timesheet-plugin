class TimesheetController < ApplicationController
  unloadable

  layout 'base'
  before_filter :get_list_size
  before_filter :get_precision
  before_filter :get_activities

  helper :sort
  include SortHelper
  helper :issues
  include ApplicationHelper
  helper :timelog

  SessionKey = 'timesheet_filter'

  verify :method => :delete, :only => :reset, :render => {:nothing => true, :status => :method_not_allowed }

  def index
    #load_filters_from_session
    unless @timesheet
      @timesheet ||= Timesheet.new
    end
    @timesheet.allowed_projects = allowed_projects
    if @timesheet.allowed_projects.empty?
      render :action => 'no_projects'
      return
    end
  end

  def report
    if params && params[:timesheet]
      @timesheet = Timesheet.new( params[:timesheet] )
    else
      redirect_to :action => 'index'
      return
    end
        
    @timesheet.allowed_projects = allowed_projects
    
    if @timesheet.allowed_projects.empty?
      render :action => 'no_projects'
      return
    end

    if !params[:timesheet][:projects].blank?
      @timesheet.projects = @timesheet.allowed_projects.find_all { |project| 
        params[:timesheet][:projects].include?(project.id.to_s)
      }
    else 
      @timesheet.projects = @timesheet.allowed_projects
    end
  
    call_hook(:plugin_timesheet_controller_report_pre_fetch_time_entries, { :timesheet => @timesheet, :params => params })

    #save_filters_to_session(@timesheet)

    @timesheet.fetch_time_entries if @timesheet.detailed == "yes"
    @timesheet.fetch_time_entries_summary unless @timesheet.detailed == "yes"
    # Sums
    @total = { }
    @total_non_billable_hours = { }
    unless @timesheet.sort == :issue
      @timesheet.time_entries.each do |project,logs|
        @total[project] = 0
        @total_non_billable_hours[project] = 0
        if logs[:logs]
          logs[:logs].each do |log|
            @total[project] += log.hours
            @total_non_billable_hours[project] += log.non_billable_hours.to_f unless log.non_billable_hours.blank?
          end
        end
      end
    else
      @timesheet.time_entries.each do |project, project_data|
        @total[project] = 0
        @total_non_billable_hours[project] = 0
        if project_data[:issues]
          project_data[:issues].each do |issue, issue_data|
            @total[project] += issue_data.collect(&:hours).sum
          end
        end
      end
    end
    @grand_total = @total.collect{|k,v| v}.inject{|sum,n| sum + n}
    @grand_total_non_billable_hours = @total_non_billable_hours.collect{|k,v| v}.inject{|sum,n| sum + n}
    
    
    respond_to do |format|
      format.html { render :action => 'details', :layout => false if request.xhr? }
      format.csv  { send_data @timesheet.to_csv, :filename => 'timesheet.csv', :type => "text/csv" } 
    end
  end
  
  def context_menu
    @time_entries = TimeEntry.find(:all, :conditions => ['id IN (?)', params[:ids]])
    render :layout => false
  end

  def reset
    clear_filters_from_session
    redirect_to :action => 'index'
  end
  
  def getprojects
    custom_field_id = CustomField.find_by_name("Project Type").id
    project_type = params[:project_type]
    project_status = params[:project_status]
    cond = ARCondition.new
    cond << ["status =?",project_status] unless project_status == "Both"
    if User.current.admin?
      if project_type == "Both"
        projects = Project.timesheet_order_by_name.find(:all,:conditions => cond.conditions,:order => "name ASC")
      else
        cond << ["custom_values.custom_field_id=?  && custom_values.value=?",custom_field_id,project_type]
        projects = Project.timesheet_order_by_name.find(:all,:joins => :custom_values,:conditions => cond.conditions,:order => "name ASC")
      end
    elsif Setting.plugin_timesheet_plugin['project_status'] == 'all'
      if project_type == "Both"
        projects = Project.timesheet_order_by_name.timesheet_with_membership(User.current).find(:all,:conditions => cond.conditions,:order => "name ASC")
      else
        cond << ["custom_values.custom_field_id=?  && custom_values.value=?",custom_field_id,project_type]
        projects = Project.timesheet_order_by_name.timesheet_with_membership(User.current).find(:all,:joins => :custom_values,:conditions => cond.conditions,:order => "name ASC")
      end
    else
      cond << Project.visible_condition(User.current)
      if project_type == "Both"
        projects = Project.timesheet_order_by_name.find(:all,:conditions => cond.conditions,:order => "name ASC")
      else
        cond << ["custom_values.custom_field_id=?  && custom_values.value=?",custom_field_id,project_type]
        projects = Project.timesheet_order_by_name.find(:all,:joins => :custom_values,:conditions => cond.conditions,:order => "name ASC")
      end
    end
    projStr =""
    projects.each do |project|
      projStr << project.id.to_s() + ',' + project.name + "\n" 
    end
    respond_to do |format|
      format.text  { render :text => projStr }
    end
  end

  private
  def get_list_size
    @list_size = Setting.plugin_timesheet_plugin['list_size'].to_i
  end

  def get_precision
    precision = Setting.plugin_timesheet_plugin['precision']
    
    if precision.blank?
      # Set precision to a high number
      @precision = 10
    else
      @precision = precision.to_i
    end
  end

  def get_activities
    @activities = TimeEntryActivity.all(:conditions => 'parent_id IS NULL',:order => "name ASC")
  end
  
  def allowed_projects
    if User.current.admin?
      Project.timesheet_order_by_name
    elsif Setting.plugin_timesheet_plugin['project_status'] == 'all'
      Project.timesheet_order_by_name.timesheet_with_membership(User.current)
    else
      Project.timesheet_order_by_name.all(:conditions => Project.visible_condition(User.current))
    end
  end

  def clear_filters_from_session
    session[SessionKey] = nil
  end

  def load_filters_from_session
    if session[SessionKey]
      @timesheet = Timesheet.new(session[SessionKey])
      # Default to free period
      @timesheet.period_type = Timesheet::ValidPeriodType[:free_period]
    end

    if session[SessionKey] && session[SessionKey]['projects']
      @timesheet.projects = allowed_projects.find_all { |project| 
        session[SessionKey]['projects'].include?(project.id.to_s)
      }
    end
  end

  def save_filters_to_session(timesheet)
    if params[:timesheet]
      # Check that the params will fit in the session before saving
      # prevents an ActionController::Session::CookieStore::CookieOverflow
      encoded = Base64.encode64(Marshal.dump(params[:timesheet]))
      if encoded.size < 2.kilobytes # Only use 2K of the cookie
        session[SessionKey] = params[:timesheet]
      end
    end

    if timesheet
      session[SessionKey] ||= {}
      session[SessionKey]['date_from'] = timesheet.date_from
      session[SessionKey]['date_to'] = timesheet.date_to
    end
  end
end
