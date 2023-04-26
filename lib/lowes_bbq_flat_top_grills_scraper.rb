require 'open-uri'
require 'nokogiri'

class LowesBBQFlatTopGrillsScraper
  LOWES_URL = 'https://www.lowes.com/pl/Flat-top-grills-Grills-Grills-outdoor-cooking-Outdoors/3421102455376'

  def self.scrape
    html = open(LOWES_URL)
    doc = Nokogiri::HTML(html)
    
    items = doc.css('div.prd-price.spld-prd-promo').map do |item|
      {
        title: item.parent.css('div.prd-description-holder a').text,
        price: item.css('span.prd-price-range span.spld-prd-$').text
      }
    end
    
    items.select { |item| item[:price].include?('$') }
  end
end
