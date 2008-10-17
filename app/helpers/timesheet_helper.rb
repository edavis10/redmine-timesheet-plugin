module TimesheetHelper
  def showing_users(users)
    l(:timesheet_showing_users) + users.collect(&:name).join(', ')
  end

  def permalink_to_timesheet(timesheet)
    link_to(l(:timesheet_permalink),
            :controller => 'timesheet',
            :action => 'report',
            :timesheet => { 
              :projects => timesheet.projects.collect(&:id),
              :date_from => timesheet.date_from,
              :date_to => timesheet.date_to,
              :activities => timesheet.activities,
              :users => timesheet.users
            })
  end
end
