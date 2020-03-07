require 'uk_planning_scraper'
require 'scraperwiki'
require 'http'
require 'json'

auths = UKPlanningScraper::Authority.tagged('liverpoolcityregion')

params = %w(validated_days decided_days)

auths.each_with_index do |auth, i|
  puts "#{i + 1} of #{auths.size}: Scraping #{auth.name}"
  params.each_with_index do |param, j|
    puts "  Checking for #{param} applications..."
    begin
      apps = auth.send(param, ENV['MORPH_DAYS'].to_i).scrape
      ScraperWiki.save_sqlite([:authority_name, :council_reference], apps)
      puts "  #{auth.name}: #{apps.size} application(s) saved."
    rescue StandardError => e
      puts e
    end
  end
end

# Helper function to look for possible postcodes in a given address
def extract_postcode(address)
  postcode = ""
  if /[[:alpha:]]+\d+\s\d+[[:alpha:]][[:alpha:]]/.match(address)
    postcode = /[[:alpha:]]+\d+\s\d+[[:alpha:]][[:alpha:]]/.match(address)[0]
  end
end

# Make sure there's a 'neighbourhood_postcode' column in the database
# Just process the postcode for the first row in the database
ScraperWiki.select("* from data limit 10").each do |row|
  row['neighbourhood_postcode'] = extract_postcode(row['address'])
  # And make sure we've got the neighbourhood_lat/lon columns too
  row['neighbourhood_latitude'] = '' if row['neighbourhood_latitude'].nil?
  row['neighbourhood_longitude'] = '' if row['neighbourhood_longitude'].nil?
  ScraperWiki.save_sqlite(["authority_name", "council_reference"], [row])
end

# Extract any postcodes from addresses that we can recognise
print "Extracting postcodes"
ScraperWiki.select('* from data where neighbourhood_postcode is null').each do |row|
  putc('.')
  row['neighbourhood_postcode'] = extract_postcode(row['address'])
  ScraperWiki.save_sqlite(["authority_name", "council_reference"], [row])
end
puts

# Now geocode a bunch of applications
# We don't just do all of them, as we don't want to overload postcodes.io
geocode_count = ENV['MORPH_POSTCODE_GEOCODE_COUNT'].to_i || 200
while geocode_count > 0 do
  # Get a bunch of not-yet-geocoded entries
  not_geocoded = ScraperWiki.select('neighbourhood_postcode from data where neighbourhood_latitude is null group by neighbourhood_postcode limit 100')
  postcodes = not_geocoded.collect { |a| a['neighbourhood_postcode'] }
  postcodes.uniq!
  # Call postcodes.io to geocode this batch of postcodes
  geocodes = HTTP.post("https://api.postcodes.io/postcodes", :json => { "postcodes": postcodes })
  if geocodes.status.success?
    results = JSON.parse(geocodes.body)
    results["result"].each do |r|
      unless r["result"].nil?
        print r["result"]
        # Find any applications with this postcode
        ScraperWiki.select('* from data where neighbourhood_latitude is null and neighbourhood_postcode = ?', r["result"]["postcode"]).each do |app|
          # Save the lat/lon
          putc '.'
          app['neighbourhood_latitude'] = r["result"]["latitude"]
          app['neighbourhood_longitude'] = r["result"]["longitude"]
          ScraperWiki.save_sqlite(["authority_name", "council_reference"], [app])
        end
      end
    end
  else
    # Something went wrong with our request, let's give up for now
    puts "Error geocoding postcodes: #{geocodes.code} #{geocodes.body.to_s}"
    geocode_count = 0
  end

  if not_geocoded.size < 100
    # This will have been the last "page" of results
    geocode_count = 0
  else
    # Got more results to check over
    geocode_count -= 100
  end

  # Don't hammer the postcodes.io servers
  sleep 10
end

