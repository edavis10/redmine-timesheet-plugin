require 'test_helper'

class ConfigurationTest < ActionController::IntegrationTest
  def setup
    @user = User.generate!(:password => 'test', :password_confirmation => 'test', :admin => true)
  end

  should "add a plugin configuration panel" do
    login_as(@user.login, 'test')
    visit_home
    click_link 'Administration'
    assert_response :success

    click_link 'Plugins'
    assert_response :success

    click_link 'Configure'
    assert_response :success
  end

  should "be able to configure the list size" do
    login_as(@user.login, 'test')
    visit_configuration_panel

    fill_in "List size", :with => '10'
    click_button 'Apply'

    assert_equal '10', plugin_configuration['list_size']
  end

  should "be able to configure the number precision" do
    login_as(@user.login, 'test')
    visit_configuration_panel

    fill_in "Number precision", :with => '10'
    click_button 'Apply'

    assert_equal '10', plugin_configuration['precision']
  end

  should "be able to configure the project status" do
    login_as(@user.login, 'test')
    visit_configuration_panel

    select "All (active and archived)", :from => 'settings_project_status'
    click_button 'Apply'

    assert_equal 'all', plugin_configuration['project_status']
  end

  should "be able to configure what types of users are shown" do
    login_as(@user.login, 'test')
    visit_configuration_panel

    select "All", :from => 'settings_user_status'
    click_button 'Apply'

    assert_equal 'all', plugin_configuration['user_status']
  end
end
