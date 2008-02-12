# Redmine Timesheet plugin

This is a plugin to show timelogs across all projects in a Redmine install.

## Features

* Filtering of timelogs
  * Date range
  * Project
  * Activities
* "Run Timesheet" permission to restrict feature to specific users

## Install

1. Follow the Redmine plugin installation steps at: http://www.redmine.org/wiki/redmine/Plugins  Make sure to install Engines 2 if you use Rails 2.0.
2. Login to your Redmine install as an Administrator
3. Enable the "Run Timesheet" permissions for your Roles
4. Add the "Timesheet module" to the enabled modules for your project [1]
5. The link to the plugin should appear on that project's navigation

[1] Currently Redmine only supports attaching plugins to the project menus.  Eventully this plugin should attach to the main menu and not have to be assigned to a project.  http://www.redmine.org/issues/show/631

## License

This plugin is licensed under the GNU GPL v2.  See LICENSE.txt and GPL.txt for details.

## Project help

If you need help you can contact the maintainer at his email address (See CREDITS.txt) or create an issue in the Bug Tracker.

### Bug tracker

If you would like to report a bug or request a new feature the bug tracker is located at:

   https://projects.littlestreamsoftware.com

