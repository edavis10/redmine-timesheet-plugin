require File.dirname(__FILE__) + '/../spec_helper'

describe Timesheet do
  it 'should not be an ActiveRecord class' do
    Timesheet.should_not be_a_kind_of(ActiveRecord::Base)
  end
  
  it 'should initialize time_entries to an empty Hash' do 
    timesheet = Timesheet.new
    timesheet.time_entries.should be_a_kind_of(Hash)
    timesheet.time_entries.should be_empty
  end
end

