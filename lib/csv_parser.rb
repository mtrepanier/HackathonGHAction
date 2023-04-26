require 'csv'

class CsvParser
  def self.parse(file_path)
    csv_text = File.read(file_path)
    csv = CSV.parse(csv_text, headers: true)
    csv.map(&:to_h)
  end
end