class SearchContacts
  include Rhom::PropertyBag
  include ChangedFlag
  include SQLHelper
  
  set :schema_version, '1.0'
  enable :sync
  set :sync_priority, 20  
      
    
  def self.search_my_contacts(params=nil)
    puts "****************************Searching contacts! #{params['first_name']}."
    result = SearchContacts.create(params)
    #SyncEngine.dosync
  end
  
end