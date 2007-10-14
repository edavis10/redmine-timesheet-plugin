# Sample plugin controller
class TimesheetController < ApplicationController
  layout 'base'
  before_filter :find_project, :authorize

  helper :sort
  include SortHelper
  helper :issues

  def index
    @today = Date.today.to_s

    case request.method
    when :post

      @from = params[:date][:from]
      @to = params[:date][:to]

      @projects = Project.find(:all);
      @entries = { }
      @projects.each do |project|
        logs = project.time_entries.find(:all,
                                         :conditions => ['spent_on >= (?) AND spent_on <= (?)',@from,@to],
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

      @owner_id = logged_in_user ? logged_in_user.id : 0

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
