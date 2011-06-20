class SearchContacts
  include Rhom::PropertyBag
  include ChangedFlag
  include SQLHelper
  
  enable :sync
  set :schema_version, '1.0'
  set :sync_priority, 20  
    
  #returns the hash of contact details that the input id points to
  def self.find_by_id(contactid)
    last_search.search_results.select{|c| c[0] == contactid }.first[1]
  end
  
  def self.clear_all_search_results
    SearchContacts.delete_all
  end
  
  # returns thd last search. SearchContacts only keeps one "singleton" search object in the db.
  def self.last_search
    find(:all).sort{ |a, b| a.object <=> b.object }.last
  end
  
  def search_terms
    Rho::JSON.parse(terms)
  end
  
  def search_results
    Rho::JSON.parse(results).sort do |a,b|
      comp = (a[1]['lastname'].downcase <=> b[1]['lastname'].downcase)
      comp.zero? ? (a[1]['firstname'] <=> b[1]['firstname'] ) : comp
    end
  end
  
  def contact_ids
    search_results.map {|contact| contact[0]}
  end
  
  def find_contacts_on_device
    Contact.find_contacts_on_device(contact_ids)
   end
end