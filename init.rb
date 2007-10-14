# Redmine sample plugin
require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Timesheet plugin for Redmine'

Redmine::Plugin.register :timesheet_plugin do
  name 'Timesheet Plugin'
  author 'Eric Davis of Little Stream Software'
  description 'This is a Timesheet plugin for Redmine to show timelogs for all projects'
  version '0.0.1'

  # This plugin adds a project module
  # It can be enabled/disabled at project level (Project settings -> Modules)
  project_module :timesheet_module do
    # This permission has to be explicitly given
    # It will be listed on the permissions screen
    permission :timesheet_index, {:timesheet => [:index]}, :public => true
    permission :timesheet_results, {:timesheet => [:timelog]}, :public => true
  end

  # A new item is added to the project menu (because Redmine can't add it anywhere else)
  menu :project_menu, "Timesheets", :controller => 'timesheet', :action => 'index'
end
