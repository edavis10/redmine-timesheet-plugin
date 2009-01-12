require 'redmine'

Redmine::Plugin.register :timesheet_plugin do
  name 'Timesheet Plugin'
  author 'Eric Davis of Little Stream Software'
  description 'This is a Timesheet plugin for Redmine to show timelogs for all projects'
  url 'https://projects.littlestreamsoftware.com/projects/show/redmine-timesheet'
  author_url 'http://www.littlestreamsoftware.com'

  version '0.4.0'
  requires_redmine :version_or_higher => '0.8.0'
  
  settings :default => {'list_size' => '5', 'precision' => '2'}, :partial => 'settings/timesheet_settings'

  permission :see_project_timesheets, { }, :require => :member

  menu :top_menu, :timesheet, {:controller => 'timesheet', :action => 'index'}, :caption => :timesheet_title
end
