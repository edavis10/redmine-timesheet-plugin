ActionController::Routing::Routes.draw do |map|
  map.connect 'timesheet/report.:format', :controller => 'timesheet', :action => 'report'
  map.connect 'timesheet/reset', :controller => 'timesheet', :action => 'reset', :conditions => { :method => :delete }
end
