require 'helpers/browser_helper'

class SearchContactsController < Rho::RhoController
  include BrowserHelper
  
  def search_contacts
    ### At a given time, you can only have one set of search results in the database.
    ### When a new Contact Search is initiated, it deletes the old search data and replaces it with the results of the new search

    #TODO: remove last search activity
    begin
      SearchContacts.clear_all_search_results
    
      unless System.has_network
        WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true', :msg => 'No internet connection. Please check your connection and try again.'}), Constants::TAB_INDEX['Contacts'])
      else
    
        # perform new search    
        @last_search_terms = { 
          :first_name => @params['first_name'],
          :last_name => @params['last_name'],
          :full_name => @params['full_name'],
          :email => @params['email'],
          :phone => @params['phone']
        }
        # SearchContacts.search({
        #    :from => 'search',
        #    :search_params => @last_search_terms,
        #    :callback => url_for(:action => :search_callback),
        #    :callback_param => ""
        #  })
      
        SearchContacts.search_crm(@last_search_terms)        
        WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}), Constants::TAB_INDEX['Contacts'])
      end
     rescue Exception => e
            puts "There was an error attempting to search contacts rolling back: #{e.inspect}"
            WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true', :msg => 'Unable to retrieve Contacts from Activity Center,  please try narrowing your search'}), Constants::TAB_INDEX['Contacts'])
     end
  end
  
  def search_callback
    status = @params["status"] 
    if (status and status == "complete")
      WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}), Constants::TAB_INDEX['Contacts'])
    end
  end   
    
  # this method is called when you navigate to the search page
  def search
    Settings.record_activity    
    if @params['show_results'] == 'true' && (@last_search = SearchContacts.last_search)
      @contacts_already_on_device = @last_search.find_contacts_on_device
    end
    render :action => :search, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  # this method is called when control returns to this page from the show_AC.erb page
  def show_search_index    
    WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}), Constants::TAB_INDEX['Contacts'])
  end
  
end