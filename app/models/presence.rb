class Presence < ApplicationRecord
  validates :name, :arena, :question1, :question2, :question3, :question4, :presence => {:message => "est requis." }
  validates_format_of :phone_number,
  :with => /\(?[0-9]{3}\)?-[0-9]{3}-[0-9]{4}/,
  :message => "- Le numero de telephone doit etre du format 555-555-5555."
end
