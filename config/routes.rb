ActionController::Routing::Routes.draw do |map|
  map.connect 'timesheet/report.:format', :controller => 'timesheet', :action => 'report'
end
