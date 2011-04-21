# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require "webrat"

Webrat.configure do |config|
  config.mode = :rails
end

# shoulda
class Test::Unit::TestCase
  def self.should_see_the_timesheet_menu
    should "see the timesheet menu" do
      get '/'

      assert_select '#top-menu a.timesheet'
    end
  end

  def self.should_not_see_the_timesheet_menu
    should "not see the timesheet menu" do
      get '/'

      assert_select '#top-menu a.timesheet', :count => 0
    end
  end
end

def User.add_to_project(user, project, role)
  Member.generate!(:principal => user, :project => project, :roles => [role])
end

module ChiliProjectIntegrationTestHelper
  def login_as(user="existing", password="existing")
    visit "/logout" # Make sure the session is cleared

    visit "/login"
    fill_in 'Login', :with => user
    fill_in 'Password', :with => password
    click_button 'Login'
    assert_response :success
    assert User.current.logged?
  end

  def visit_home
    visit '/'
    assert_response :success
  end

  def visit_project(project)
    visit '/'
    assert_response :success

    click_link 'Projects'
    assert_response :success

    click_link project.name
    assert_response :success
  end

  def visit_issue_page(issue)
    visit '/issues/' + issue.id.to_s
  end

  def visit_issue_bulk_edit_page(issues)
    visit url_for(:controller => 'issues', :action => 'bulk_edit', :ids => issues.collect(&:id))
  end
end

module TimesheetIntegrationTestHelper
  def visit_configuration_panel
    visit_home
    click_link 'Administration'
    assert_response :success

    click_link 'Plugins'
    assert_response :success

    click_link 'Configure'
    assert_response :success
  end
  
end

class ActionController::IntegrationTest
  include ChiliProjectIntegrationTestHelper
  include TimesheetIntegrationTestHelper
end

class ActiveSupport::TestCase
  def assert_forbidden
    assert_response :forbidden
    assert_template 'common/403'
  end

  def configure_plugin(configuration_change={})
    Setting.plugin_timesheet_plugin = {
      'list_size' => '5',
      'precision' => '2',
      'project_status' => 'active',
      'user_status' => 'active'
    }.merge(configuration_change)
  end

  def reconfigure_plugin(configuration_change)
    Setting['plugin_timesheet_plugin'] = Setting['plugin_timesheet_plugin'].merge(configuration_change)
  end

  def plugin_configuration
    Setting.plugin_timesheet_plugin
  end
end
