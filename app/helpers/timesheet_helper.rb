module TimesheetHelper
  def showing_users(users)
    l(:timesheet_showing_users) + users.collect(&:name).join(', ')
  end
end
