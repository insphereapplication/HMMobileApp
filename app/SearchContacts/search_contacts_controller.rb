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
    puts "SEARCH CALLBACK"
    puts @params.inspect
    status = @params["status"] 
    if (status and status == "complete")
      WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}))
    end
  end   
  
  def search
    Settings.record_activity
    puts "+"*80
    puts @params.inspect
    #puts SearchContacts.results
    
    if @params['show_results'] == 'true' && (results = SearchContacts.results)

      @last_search_terms = SearchContacts.last_search_terms
      puts @last_search_terms.inspect

      @parsed_search_results = results
      puts "PARSED RESULTS"
      puts @parsed_search_results.inspect
    end
    render :action => :search, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def show_search_contact
    puts "-+"*50
    contact = SearchContacts.find_by_id(@params['id'])
    puts contact
    render :action => :show_AC, :back => 'callback:', :layout => 'layout_jquerymobile'
  end
  
  def show_search_index
    render :action => :search, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
end