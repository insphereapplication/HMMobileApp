class SearchContacts
  include Rhom::PropertyBag
  include ChangedFlag
  include SQLHelper
  
  enable :sync
  set :schema_version, '1.0'
  set :sync_priority, 20  
      
  # returns the results of the last search. SearchContacts only keeps one "singleton" search object in the db.
  def self.results
    search = find(:all).sort{ |a, b| a.object <=> b.object }.last
    return Rho::JSON.parse(search.results) unless search.blank?
  end
  
  #returns the hash of contact details that the input id points to
  def self.find_by_id(id)
    results[id]
  end
  
  def self.last_search_terms
    search = find(:all).sort{ |a, b| a.object <=> b.object }.last
    return Rho::JSON.parse(search.terms) unless search.blank?
  end
  
  def self.clear_all_search_results
    puts "Deleting previous search results"
    SearchContacts.delete_all
  end
  
end