require 'helpers/browser_helper'
require 'rho/rhoerror'

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
            ExceptionUtil.log_exception_to_server(e, "Search Contacts Error" )
            puts "Rho Error:  #{Rho::RHO.current_exception}"
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
    @page_name = 'Activity Center'
    @isCollapsed = 'false'
    @firstBtnText = 'Back'
    @firstBtnIcon = 'back'
    @firstBtnUrl = url_for :action => :index, :controller => :Contact
    @firstBtnBack = false
    @firstBtnExternal = true
    @secondBtnUrl = nil
    @scriptName = 'searchContacts'
    @pageSize = 50
    @url = '/app/SearchContacts/get_jqm_ac_contacts_page'
    @filterBtnText = 'Search AC'
    @search_terms = get_last_search_terms
    render :action => :filter, :back => 'callback:', :layout => 'layout_jqm_list'
  end
  def get_last_search_terms
    persisted_search_name = ''
    persisted_search_email = ''
    persisted_search_phone = ''
    last_search = SearchContacts.last_search
    if last_search
      persisted_search_name = last_search.search_terms['full_name']
      persisted_search_email = last_search.search_terms['email']
      persisted_search_phone = last_search.search_terms['phone']
    end
    { :full_name => persisted_search_name, :email => persisted_search_email, :phone => persisted_search_phone }
  end
  def get_last_search_results
    items = []
    items_on_device = []
    last_search = SearchContacts.last_search
    if last_search
      items = last_search.search_results
      items_on_device = last_search.find_contacts_on_device
    end
    { :items => items, :on_device => items_on_device }
  end
  def get_jqm_ac_contacts_page
    error = ''
    result = { :items => [], :on_device => [] }
    search_terms = {
      :full_name => @params['name'],
      :email => @params['email'],
      :phone => @params['phone']
    }
    if @params['reset'] == "true"
      result = get_last_search_results
      last_search_terms = get_last_search_terms
      if search_terms[:full_name] != last_search_terms[:full_name] || search_terms[:email] != last_search_terms[:email] || search_terms[:phone] != last_search_terms[:phone]
        # new search, clear previous results
        SearchContacts.clear_all_search_results
        unless System.has_network
          error = 'No internet connection. Please check your connection and try again.'
        else
          begin
            SearchContacts.search_crm(search_terms)
            result = get_last_search_results
          rescue Exception => e
            puts "There was an error attempting to search contacts: #{e.inspect}"
            ExceptionUtil.log_exception_to_server(e, "Search Contacts Error")
            error = 'Unable to retrieve Contacts from Activity Center, please try narrowing your search.'
          end
        end
      end
    end
    render :partial => 'contact', :locals => { :error => error, :result => result, :search_terms => search_terms }
  end

  # this method is called when control returns to this page from the show_AC.erb page
  def show_search_index    
    WebView.navigate(url_for(:action => :search, :controller => :SearchContacts, :query => {:show_results => 'true'}), Constants::TAB_INDEX['Contacts'])
  end
  
end
