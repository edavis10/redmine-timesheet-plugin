ActionController::Routing::Routes.draw do |map|
  map.connect 'timesheet/index', :controller => 'timesheet', :action => 'index'
  map.connect 'timesheet/context_menu', :controller => 'timesheet', :action => 'context_menu'
  map.connect 'timesheet/report.:format', :controller => 'timesheet', :action => 'report'
  map.connect 'timesheet/reset', :controller => 'timesheet', :action => 'reset', :conditions => { :method => :delete }
end
