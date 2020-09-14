class AddStartTimeEndTime < ActiveRecord::Migration[6.0]
  def change
    add_column :presences, :start_time, :string
    add_column :presences, :end_time, :string

    presences = Presence.all
    presences.each do |presence|
      presence.start_time = "#{presence.start_hour}:00"
      presence.end_time = "#{presence.end_hour}:00"
      presence.save
    end

    remove_column :presences, :start_hour, :integer
    remove_column :presences, :end_hour, :integer
  end
end
