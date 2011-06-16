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
  
  def show_AC
    render :action => :show_AC, :controller => :Contact, :layout => 'layout_jquerymobile'
  end
  
  def search
    Settings.record_activity    
    if @params['show_results'] == 'true' && (results = SearchContacts.results)
      @last_search_terms = SearchContacts.last_search_terms
      @parsed_search_results = results
    end
    render :action => :search, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def show_search_contact
    contact = SearchContacts.find_by_id(@params['id'])
    puts contact
    render :action => :show_AC, :back => 'callback:', :layout => 'layout_jquerymobile'
  end
  
  def show_search_index
    @last_search_terms = SearchContacts.last_search_terms
    @parsed_search_results = SearchContacts.results
    WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}))
  end
  
end