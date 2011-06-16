
class SearchContactsController < Rho::RhoController
  def search_contacts
    SearchContacts.search({
      :from => 'search',
      :search_params => { 
        :first_name => 'Kay'
      },
      :callback => url_for(:action => :search_callback),
      :callback_param => ""
    })
  end
  
  def search_callback
    status = @params["status"] 
    if (status and status == "ok")
      if results = SearchContacts.results
        parsed = Rho::JSON.parse(results).inspect
      end
    end
  end   
end