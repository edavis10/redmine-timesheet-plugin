class CreateTimesheets < ActiveRecord::Migration
  def self.up
    create_table :timesheets do |t|
      t.string :name
      t.date :date_from
      t.date :date_to
      t.text :filters
      t.references :user
      t.timestamps
    end

    add_index :timesheets, :user_id
    add_index :timesheets, :name
  end

  def self.down
    drop_table :timesheets
  end
end
