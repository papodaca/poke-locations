#!/usr/bin/env ruby

require "faraday"
require "faraday/follow_redirects"
require "nokogiri"
require "json"
require "pry"
require "cgi"

API_KEY = EMV["GOOGLE_API_KEY"]

POKE_CENTER = "https://support.pokemoncenter.com/"
LOCATIONS_URL = "#{POKE_CENTER}/hc/en-us/sections/13360842288916-Pok%C3%A9mon-Automated-Retail-Vending-Machines"

$faraday = Faraday.new do |faraday|
  faraday.response :follow_redirects
  faraday.adapter Faraday.default_adapter
end

def get_location_urls
  puts "getting #{LOCATIONS_URL}"
  res = $faraday.get(LOCATIONS_URL)
  doc = Nokogiri::HTML.parse(res.body)
  links = doc.css("a.article-list-link")
  location_pages = []
  links.each do |link|
    location_pages << "#{POKE_CENTER}#{link["href"]}" unless link.text.include?("FAQ")
  end
  location_pages
end

def url_encode(string)
  CGI.escape(string)
end

def get_location_from_address_google(address, city)
  combind_address = "#{address}, #{city}"
  puts "googling #{address}, #{city}"
  res = $faraday.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{url_encode(combind_address)}&key=#{API_KEY}")
  data = JSON.parse(res.body)
  results = data["results"].first
  geo = results.dig("geometry", "location")
  [geo["lat"], geo["lng"]]
rescue
  get_location_from_address(address, city)
end

def get_location_from_address(address, city_state, rr = false)
  url = "http://nominatim.openstreetmap.org/search?q=#{"#{address} #{city_state}".gsub(/\s/, "+")}&format=json"
  puts "getting #{url}"
  res = $faraday.get(url)
  places = JSON.parse(res.body)
  return get_location_from_address(address, "", true) if places.length == 0 && !rr
  [places.first["lat"].to_f, places.first["lon"].to_f] if places.length > 0
rescue
  nil
end

locations_urls = get_location_urls
locations = []

locations_urls.each_with_index do |location_url, index|
  next if location_url.nil?
  locations = []
  puts "getting #{location_url}"
  res = $faraday.get(location_url)
  doc = Nokogiri::HTML.parse(res.body)
  rows = doc.css("table tbody tr")
  rows.each do |row|
    elements = row.css("td")
    name = elements[0].text.strip
    id = elements[1].text.strip
    address = elements[2].text.strip
    city_state = elements[3].text.strip
    locations << {
      n: name,
      l: get_location_from_address_google(address, city_state),
      d: "#{address}, #{city_state}"
    }
  end
  File.write("assets/places_#{index}.json", JSON.dump(locations))
end
