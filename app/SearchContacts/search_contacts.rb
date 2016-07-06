class SearchContacts
  include Rhom::PropertyBag
  include ChangedFlag
  include SQLHelper
  
  #enable :sync
  set :schema_version, '1.0'
  #set :sync_priority, 20  
    
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
  
  def self.search_crm(search_params)  
    crm_url = Rho::RhoConfig.crm_url
    user = Settings.login
    pw = Settings.password
    attributes = ''
    add_comma = false;
    if search_params
      attributes = "&attributes={"
      search_params.each { |key, value| 
         puts "\"#{key}\":\"#{value}\""
         attributes = attributes + "," if add_comma
         attributes = attributes + "\"#{key}\":\"#{value}\""
         add_comma = true
         }
       attributes = attributes + "}"   
      puts "attributes:  #{attributes}" 
    end
    result = Rho::AsyncHttp.post(
      :url => "#{crm_url}/contact/search",
      :body => "username=#{user}&password=#{pw}&#{attributes}"
    )
  

    # removing the ownerid as is used to translate to user in rhosync.   This above is directly calling CRM mobile proxy instead of going through rhosync
    
    body = Rho::JSON.parse(result["body"])
   
    res = body.map do |value|
       value.reject!{|k,v|  ['ownerid'].include?(k) }
       value
     end
     
    res = res.reduce({}){|sum, value| sum[value["contactid"]] = value if value; sum }
  
    SearchContacts.create({:object => Time.now.to_i, 	:results => res.to_json, :terms => search_params.to_json})
  
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