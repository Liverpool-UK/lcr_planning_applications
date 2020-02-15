require 'uk_planning_scraper'
require 'scraperwiki'

auths = UKPlanningScraper::Authority.tagged('liverpoolcityregion')

auths.each_with_index do |auth, i|
  begin
    puts "#{i + 1} of #{auths.size}: Scraping #{auth.name}"
    puts "  Checking for validated applications..."
    apps = auth.scrape({ validated_days: ENV['MORPH_DAYS'].to_i })
    ScraperWiki.save_sqlite([:authority_name, :council_reference], apps)
    puts "  #{auth.name}: #{apps.size} application(s) saved."
    puts "  Now getting decided applications..."
    apps = auth.scrape({ decided_days: ENV['MORPH_DAYS'].to_i })
    ScraperWiki.save_sqlite([:authority_name, :council_reference], apps)
    puts "  #{auth.name}: #{apps.size} application(s) saved."
  rescue StandardError => e
    puts e
  end
end
