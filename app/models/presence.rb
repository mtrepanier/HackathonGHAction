class Presence < ApplicationRecord
  validates :name, :arena, :phone_number, :question1, :question2, :question3, :question4, :start_time, :end_time, :presence => {:message => "est requis." }

  self.per_page = 50
end
