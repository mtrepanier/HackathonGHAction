require 'active_support/core_ext'

class AddStartHourEndHourToPresence < ActiveRecord::Migration[6.0]
  def change
    add_column :presences, :start_hour, :integer
    add_column :presences, :end_hour, :integer
    add_column :presences, :activity_date, :date

    presences = Presence.all
    presences.each do |presence|
      presence.start_hour = presence.created_at.hour
      end_hour = presence.start_hour + 1
      end_hour = 1 if end_hour > 24
      presence.end_hour = end_hour
      presence.activity_date = presence.created_at.to_date
      presence.save
    end
  end
end
