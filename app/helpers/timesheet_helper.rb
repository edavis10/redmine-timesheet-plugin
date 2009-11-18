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
end
