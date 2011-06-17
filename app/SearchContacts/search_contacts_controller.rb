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
    if @params['show_results'] == 'true' && (results = SearchContacts.results)
      @last_search_terms = SearchContacts.last_search_terms
      @search_results = results
      @contacts_already_on_device = find_contacts_on_device(results)
    end
    render :action => :search, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  # this method is called when control returns to this page from the show_AC.erb page
  def show_search_index    
    WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}))
  end
  
  def find_contacts_on_device(contacts_hash=nil)

    search_result_contact_ids = []
    contacts_hash.each do |contact|
      search_result_contact_ids << contact[0]
    end
        
    ids_found_on_device = []
    Contact.find_contacts_on_device(search_result_contact_ids).each do |contact|
      ids_found_on_device << contact.contactid
    end

    ids_found_on_device
  end    
    
  
end