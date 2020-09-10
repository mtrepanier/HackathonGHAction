json.extract! presence, :id, :name, :attendant, :phone_number, :arena, :question1, :question2, :question3, :question4, :created_at, :updated_at
json.url presence_url(presence, format: :json)
