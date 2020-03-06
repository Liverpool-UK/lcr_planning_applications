require 'sqlite3'

desc "Try to find postcodes in the address data"

task :find_postcodes do
  if ENV['db']
    db = SQLite3::Database.new ENV['db']
    db.execute("select address from data") do |address|
      #puts address.inspect
      address = address[0]
      if ENV['prefixes']
        # TODO We can limit our postcode searches to a subset of all of them
      else
        # Just look for things that look like a UK postcode
        if /[[:alpha:]]+\d+\s\d+[[:alpha:]][[:alpha:]]/.match(address)
          puts /[[:alpha:]]+\d+\s\d+[[:alpha:]][[:alpha:]]/.match(address)[0]
        else
          #puts "No match for '"+address+"'"
        end
      end
    end
  else
    puts "No database specified.  Run 'rake find_postcodes db=name-of-your-database.db'" 
  end
end
