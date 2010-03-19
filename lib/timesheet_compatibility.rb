# Wrappers around the Redmine core API changes between versions
module TimesheetCompatibility
  class Enumeration
    # Wrapper around Redmine's API since Enumerations changed in r2472
    # This can be removed once 0.9.0 is stable
    def self.activities
      if Object.const_defined?('TimeEntryActivity')
        return ::TimeEntryActivity.all
      elsif ::Enumeration.respond_to?(:activities)
        return ::Enumeration.activities
      else
        return ::Enumeration::get_values('ACTI')
      end
    end

    # Wrapper for Project Specific Enumerations in Redmine 0.9+
    def self.project_specific_sql
      if ::Enumeration.column_names.include?('parent_id') && ::Enumeration.column_names.include?('project_id')
        "OR (#{::Enumeration.table_name}.parent_id IN (:activities) AND #{::Enumeration.table_name}.project_id IN (:projects))"
      else
        ''
      end
    end
  end
end
