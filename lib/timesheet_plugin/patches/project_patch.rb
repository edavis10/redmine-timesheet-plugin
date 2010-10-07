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
        end
      end

      module ClassMethods
      end

      module InstanceMethods
      end
    end
  end
end
