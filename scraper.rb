require 'uk_planning_scraper'
require 'scraperwiki'

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
