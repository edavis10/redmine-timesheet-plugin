# Sample plugin controller
class TimesheetController < ApplicationController
  unloadable

  layout 'base'
  before_filter :get_list_size
  before_filter :get_activities

  helper :sort
  include SortHelper
  helper :issues

  def index
    @from = Date.today.to_s
    @to = Date.today.to_s
    @timesheet = Timesheet.new
    @timesheet.allowed_projects = allowed_projects
    
    if @timesheet.allowed_projects.empty?
      render :action => 'no_projects'
      return
    end
  end

  def report
    @timesheet = Timesheet.new
    @timesheet.allowed_projects = allowed_projects
    
    if @timesheet.allowed_projects.empty?
      render :action => 'no_projects'
      return
    end

    @timesheet.date_from = params[:timesheet][:date_from]
    @timesheet.date_to = params[:timesheet][:date_to]
    
    if !params[:timesheet][:projects].blank?
      @timesheet.projects = @timesheet.allowed_projects.find_all { |project| 
        params[:timesheet][:projects].include?(project.id.to_s)
      }
    else 
      @timesheet.projects = @timesheet.allowed_projects
    end

    if !params[:timesheet][:activities].blank?
      @timesheet.activities = params[:timesheet][:activities].collect {|p| p.to_i }
    else 
      @timesheet.activities = @activities.collect(&:id)
    end
    
    if !params[:timesheet][:users].blank?
      @timesheet.users = params[:timesheet][:users].collect {|p| p.to_i }
    else 
      @timesheet.users = User.find(:all).collect(&:id)
    end
    
    @timesheet.fetch_time_entries

    # Sums
    @total = { }
    @timesheet.time_entries.each do |project,logs|
      project_total = 0
      unless logs[:logs].nil?
        logs[:logs].each do |log|
          project_total += log.hours
        end
        @total[project] = project_total
      end
    end
    
    @grand_total = @total.collect{|k,v| v}.inject{|sum,n| sum + n}

    send_csv and return if 'csv' == params[:export]
    render :action => 'details', :layout => false if request.xhr?
  end
  
private
  def get_list_size
    @list_size = Setting.plugin_timesheet_plugin['list_size'].to_i
  end
  
  def get_activities
    @activities = Enumeration::get_values('ACTI')
  end
  
  def allowed_projects
    if User.current.admin?
      return Project.find(:all, :order => 'name ASC')
    else
      return User.current.projects.find(:all, :order => 'name ASC')
    end
  end
end
