# Redmine Timesheet plugin

A plugin to show and filter timelogs across all projects in Redmine.

## Features

* Filtering and sum of timelogs by:
  * Date range
  * Projects
  * Activities
  * Users
* Subtotals by project
* "Run Timesheet" permission to restrict feature to specific users

## Installation and Setup

There are three ways to download it:

1. Download the plugin.  There are three supported ways:
  * Downloading the latest archive file from [Little Stream Software projects][1]
  * Checkout the source from Git

       cd vendor/plugins/ && git clone git://github.com/edavis10/redmine-timesheet-plugin.git timesheet_plugin

  * Install it using Rail's plugin installer

       script/plugin install git://github.com/edavis10/redmine-timesheet-plugin.git

2. Install the plugin as described at [http://www.redmine.org/wiki/redmine/Plugins][2]. (this plugin doesn't require migration).
3. Login to your Redmine install as an Administrator.
4. Enable the "Run Timesheet" permissions for your Roles.
5. Add the "Timesheet module" to the enabled modules for your project.
6. The link to the plugin should appear on that project's navigation.

## Upgrade

### Zip file

1. Download the latest zip file from [Little Stream Software projects][1]
2. Unzip the file to your Redmine into vendor/plugins
3. Restart your Redmine

### Git

1. Open a shell to your Redmine's vendor/plugins/timesheet_plugin folder
2. Update your Git copy with `git pull`
3. Restart your Redmine

## License

This plugin is licensed under the GNU GPL v2.  See LICENSE.txt and GPL.txt for details.

## Project help

If you need help you can contact the maintainer at his email address (See CREDITS.txt) or create an issue in the Bug Tracker.

### Bug tracker

If you would like to report a bug or request a new feature the bug tracker is located at:

   https://projects.littlestreamsoftware.com


[1]: https://projects.littlestreamsoftware.com/projects/list_files/redmine-timesheet
[2]: http://www.redmine.org/wiki/redmine/Plugins
