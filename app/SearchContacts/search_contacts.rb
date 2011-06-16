class SearchContacts
  include Rhom::PropertyBag
  include ChangedFlag
  include SQLHelper
  
  enable :sync
  set :schema_version, '1.0'
  set :sync_priority, 20  
      
  # returns the results of the last search. SearchContacts only keeps one "singleton" search object in the db.
  def self.results
    res = find(:all).first.results
    puts "$"*80
    puts res.inspect
    res
  end
  
end