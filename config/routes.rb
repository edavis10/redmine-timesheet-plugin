ActionController::Routing::Routes.draw do |map|
  map.connect 'timesheets/report.:format', :controller => 'timesheets', :action => 'report'
  map.connect 'timesheets/reset', :controller => 'timesheets', :action => 'reset', :conditions => { :method => :delete }
end
