module TimesheetPlugin
  module Patches
    module ProjectPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          # Prefix our named_scopes to prevent collusion
          named_scope :timesheet_order_by_name, :order => 'name ASC'
          named_scope :timesheet_with_membership, lambda {|user|
            # Similar to Project.visible_by but without the STATUS check
            if user && user.memberships.any?

              # Principal#members gets all projects, but #memberships will only
              # get the active ones
              if Setting.plugin_timesheet_plugin['project_status'] == 'all'
                project_ids = user.members.collect{|m| m.project_id}
              else
                project_ids = user.memberships.collect{|m| m.project_id}
              end
              
              {
                :conditions => [
                                "#{Project.table_name}.is_public = :true or #{Project.table_name}.id IN (:project_ids)",
                                {
                                  :true => true,
                                  :project_ids => project_ids
                                }
                               ]
              }
            else
              {
                :conditions => { :is_public => true }
              }
            end
          }
        end
      end

      module ClassMethods
      end

      module InstanceMethods
      end
    end
  end
end
