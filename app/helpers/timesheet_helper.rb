module TimesheetHelper
  def showing_users(users)
    l(:timesheet_showing_users) + users.collect(&:name).join(', ')
  end

  def permalink_to_timesheet(timesheet)
    link_to(l(:timesheet_permalink),
            :controller => 'timesheet',
            :action => 'report',
            :timesheet => timesheet.to_param)
  end

  def link_to_csv_export(timesheet)
    link_to('CSV',
            {
              :controller => 'timesheet',
              :action => 'report',
              :format => 'csv',
              :timesheet => timesheet.to_param
            },
            :method => 'post',
            :class => 'icon icon-timesheet')
  end
  
  def toggle_issue_arrows(issue_id)
    js = "toggleTimeEntries('#{issue_id}'); return false;"
    
    return toggle_issue_arrow(issue_id, 'toggle-arrow-closed.gif', js, false) +
      toggle_issue_arrow(issue_id, 'toggle-arrow-open.gif', js, true)
  end
  
  def toggle_issue_arrow(issue_id, image, js, hide=false)
    style = "display:none;" if hide
    style ||= ''

    content_tag(:span,
                link_to_function(image_tag(image, :plugin => "timesheet_plugin"), js),
                :class => "toggle-" + issue_id.to_s,
                :style => style
                )
    
  end
  
  def displayed_time_entries_for_issue(time_entries)
    time_entries.collect(&:hours).sum
  end

  def project_options(timesheet)
    available_projects = timesheet.allowed_projects
    selected_projects = timesheet.projects.collect(&:id)
    selected_projects = available_projects.collect(&:id) if selected_projects.blank?
    
    options_from_collection_for_select(available_projects,
                                       :id,
                                       :name,
                                       selected_projects)
  end

  def activity_options(timesheet, activities)
    options_from_collection_for_select(activities, :id, :name, timesheet.activities)
  end

  def user_options(timesheet)
    available_users = Timesheet.viewable_users.sort { |a,b| a.to_s.downcase <=> b.to_s.downcase }
    selected_users = timesheet.users

    options_from_collection_for_select(available_users,
                                       :id,
                                       :name,
                                       selected_users)

  end
end
