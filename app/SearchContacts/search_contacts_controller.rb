
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
    puts "%"*80
    puts @params.inspect
    search = SearchContacts.find(:all).first
    puts Rho::JSON.parse(search.results).inspect
  end
end