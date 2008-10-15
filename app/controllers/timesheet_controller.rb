# Sample plugin controller
class TimesheetController < ApplicationController
  unloadable

  layout 'base'
  before_filter :get_list_size

  helper :sort
  include SortHelper
  helper :issues

  def index
    @today = Date.today.to_s

    @timesheet = Timesheet.new
    @timesheet.allowed_projects = allowed_projects
    @activities = Enumeration::get_values('ACTI')
    
    case request.method
    when :post
      @timesheet.date_from = params[:timesheet][:date_from]
      @timesheet.date_to = params[:timesheet][:date_to]
      
      if !params[:timesheet][:projects].blank?
        @timesheet.projects = Project.find(:all,
                                           :conditions => ['id IN (?)', params[:timesheet][:projects].collect {|p| p.to_i }],
                                           :order => 'name ASC')
      else 
        @timesheet.projects =  Project.find(:all, :order => 'name ASC')
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
      
      @entries = { }
      @timesheet.projects.each do |project|
        logs = project.time_entries.find(:all,
                                         :conditions => ['spent_on >= (?) AND spent_on <= (?) AND activity_id IN (?) AND user_id IN (?)',
                                                         @timesheet.date_from, @timesheet.date_to, @timesheet.activities, @timesheet.users ],
                                         :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                         :order => "spent_on ASC")
        # Append the parent project name
        if project.parent.nil?
          @entries[project.name] = logs unless logs.empty?
        else
          @entries[project.parent.name + ' / ' + project.name] = logs unless logs.empty?          
        end
      end

      # Sums
      @total = { }
      @entries.each do |project,logs|
        project_total = 0
        logs.each do |log|
          project_total += log.hours
        end
        @total[project] = project_total
      end
      
      @grand_total = @total.collect{|k,v| v}.inject{|sum,n| sum + n}


      send_csv and return if 'csv' == params[:export]
      render :action => 'details', :layout => false if request.xhr?
    when :get
      # nothing
      @timesheet.projects = { }
      @from,@to = @today,@today
      @entries = []
    end
  end


private
  def get_list_size
    @list_size = Setting.plugin_timesheet_plugin['list_size'].to_i
  end
  
  def allowed_projects
    if User.current.admin?
      return Project.find(:all, :order => 'name ASC')
    else
      return User.current.projects.find(:all, :order => 'name ASC')
    end
  end
end
