# Sample plugin controller
class TimesheetController < ApplicationController
  layout 'base'
  before_filter :find_project, :authorize

  helper :sort
  include SortHelper
  helper :issues

  def index
    case request.method
    when :post

      sort_init 'spent_on', 'desc'
      sort_update

      date = Date.civil(params[:filter][:"date(1i)"].to_i,params[:filter][:"date(2i)"].to_i,params[:filter][:"date(3i)"].to_i)

      @projects = Project.find(:all);
      @entries = { }
      @projects.each do |project|
        logs = project.time_entries.find(:all, :conditions => ['spent_on > (?)',date], :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}], :order => sort_clause)
        @entries[project.name] = logs unless logs.empty?
      end

      @owner_id = logged_in_user ? logged_in_user.id : 0

      send_csv and return if 'csv' == params[:export]
      render :action => 'details', :layout => false if request.xhr?
    when :get
      # nothing
    end
  end


private
  def find_project
    @project=Project.find(params[:id])
  end
end
