ActionController::Routing::Routes.draw do |map|
  map.resources :timesheets, :collection => {:query => :post}
end
