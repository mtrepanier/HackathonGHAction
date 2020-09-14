class Presence < ApplicationRecord
  validates :name, :arena, :question1, :question2, :question3, :question4, :start_time, :end_time, :presence => {:message => "est requis." }
  validates_format_of :phone_number,
  :with => /\(?[0-9]{3}\)?-[0-9]{3}-[0-9]{4}/,
  :message => "- Le numéro de téléphone doit être du format 555-555-5555."

  self.per_page = 50
end
