require 'test_helper'

class TimesheetRoutingTest < ActionController::IntegrationTest
  context "timesheets" do
    # index
    should_route :get, "/timesheets", :controller => 'timesheets', :action => 'index'

    # new
    should_route :get, "/timesheets/new", :controller => 'timesheets', :action => 'new'

    # create
    should_route :post, "/timesheets", :controller => 'timesheets', :action => 'create'
    
    # show
    should_route :get, "/timesheets/1", :controller => 'timesheets', :action => 'show', :id => '1'
    
    # edit
    should_route :get, "/timesheets/1/edit", :controller => 'timesheets', :action => 'edit', :id => '1'
    
    # update
    should_route :put, "/timesheets/1", :controller => 'timesheets', :action => 'update', :id => '1'
    
    # delete
    should_route :delete, "/timesheets/1", :controller => 'timesheets', :action => 'destroy', :id => '1'

    # query
    should_route :post, "/timesheets/query", :controller => 'timesheets', :action => 'query'
  end
end
