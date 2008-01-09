# Sample plugin controller
class TimesheetController < ApplicationController
  unloadable

  layout 'base'
  before_filter :find_project, :authorize

  helper :sort
  include SortHelper
  helper :issues

  def index
    @today = Date.today.to_s

    @activities = Enumeration::get_values('ACTI')

    case request.method
    when :post

      @timesheet = Timesheet.new
      @timesheet.date_from = params[:timesheet][:date_from]
      @timesheet.date_to = params[:timesheet][:date_to]
      @timesheet.project_id = params[:timesheet][:project_id]

      if @timesheet.project_id == ""
        @projects = Project.find(:all);
      else
        @projects = [Project.find(@timesheet.project_id)]
      end

      activities = params[:activities] || @activities
      @entries = { }
      @projects.each do |project|
        logs = project.time_entries.find(:all,
                                         :conditions => ['spent_on >= (?) AND spent_on <= (?) AND activity_id IN (?) ',
                                                         @timesheet.date_from, @timesheet.date_to, activities],
                                         :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                         :order => "spent_on ASC")
        @entries[project.name] = logs unless logs.empty?
      end

      # Sums
      @total = 0
      @entries.each do |project,logs|
        logs.each do |log|
          @total += log.hours
        end
     end

      send_csv and return if 'csv' == params[:export]
      render :action => 'details', :layout => false if request.xhr?
    when :get
      # nothing
      @from,@to = @today,@today
      @entries = []
    end
  end


private
  def find_project
    @project=Project.find(params[:id])
  end
end
