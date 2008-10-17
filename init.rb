require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Timesheet plugin for Redmine'

Redmine::Plugin.register :timesheet_plugin do
  name 'Timesheet Plugin'
  author 'Eric Davis of Little Stream Software'
  description 'This is a Timesheet plugin for Redmine to show timelogs for all projects'
  version '0.3.0'
  
  settings :default => {'list_size' => '5'}, :partial => 'settings/timesheet_settings'

  permission :see_project_timesheets, { }, :require => :member

  menu :top_menu, :timesheet, {:controller => 'timesheet', :action => 'index'}, :caption => :timesheet_title
end
