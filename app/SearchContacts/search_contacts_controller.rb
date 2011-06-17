require 'helpers/browser_helper'

class SearchContactsController < Rho::RhoController
  include BrowserHelper
  
  def search_contacts
    @last_search_terms = { 
      :first_name => @params['first_name'],
      :last_name => @params['last_name']
    }
    SearchContacts.search({
      :from => 'search',
      :search_params => @last_search_terms,
      :callback => url_for(:action => :search_callback),
      :callback_param => ""
    })
  end
  
  def search_callback
    status = @params["status"] 
    if (status and status == "complete")
      WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}))
    end
  end   
    
  # this method is called when you navigate to the search page
  def search
    Settings.record_activity    
    puts "+"*80 << "Search!!!"    
    if @params['show_results'] == 'true' && (results = SearchContacts.results)
      @last_search_terms = SearchContacts.last_search_terms
      @parsed_search_results = flag_contacts_on_device(results)
    end
    render :action => :search, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  # this method is called when control returns to this page from the show_AC.erb page
  def show_search_index    
    WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}))
  end
  
  def flag_contacts_on_device(contacts_hash=nil)
    puts "#"*50 << "Flagging contacts on device"
    
    searched_contact_ids = []
    contacts_hash.each do |contact|
      searched_contact_ids << contact[0]
    end
    
    puts "#"*50 << "Searching for contacts on device"
    puts searched_contact_ids
    contacts_already_on = Contact.find_contacts_on_device(searched_contact_ids)
    puts contacts_already_on
    contacts_already_on.each do |contact_id|
      puts contact_id.inspect
    end
    puts "#"*30 << "Contacts on device:"
    puts contacts_already_on.inspect
    
    contacts_hash
  end    
    
  
end