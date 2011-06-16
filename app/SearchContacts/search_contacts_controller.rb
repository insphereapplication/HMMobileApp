require 'helpers/browser_helper'

class SearchContactsController < Rho::RhoController
  include BrowserHelper
  def search_contacts
    SearchContacts.search({
      :from => 'search',
      :search_params => { 
        :first_name => @params['first_name'],
        :last_name => @params['last_name']
      },
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
    puts "&"*80
    puts @params.inspect
    puts SearchContacts.results
    
    if @params['show_results'] == 'true' && (results = SearchContacts.results)
      @parsed_search_results = results
      puts "PARSED RESULTS"
      puts @parsed_search_results.inspect
    end
    render :action => :search, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def show_search_contact
    @contact = Contact.find_contact(@params['id'])
    render :action => :show_AC, :back => 'callback:', :layout => 'layout_jquerymobile'
  end
  
end