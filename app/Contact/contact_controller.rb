require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'
require 'time'
require 'rho/rhotabbar'

class ContactController < Rho::RhoController
  include BrowserHelper

  $first_render = true

  #GET /Contact
  def index
    $tab = 1
    Settings.record_activity
    render :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def show_all_contacts
    if Contact.local_changed? || $first_render
      WebView.navigate(url_for :controller => :Contact, :action => :index)
      Contact.local_changed = false
      $first_render = false
    end
  end
  
  def self.is_first_render?
    rendered = !!@rendered
    @rendered = true
    !rendered
  end
  
  def get_contacts_page
    Settings.record_activity
    
    @contacts = lambda {
      case @params['filter']
      when 'all' 
        Contact.all_open(@params['page'].to_i, @params['search_terms'])
      when 'active-policies'
        Contact.with_policies(@params['page'].to_i, 'Active', @params['search_terms'])
      when 'pending-policies'
        Contact.with_policies(@params['page'].to_i, 'Pending', @params['search_terms'])
      when 'open-opps'
        Contact.with_open_opps(@params['page'].to_i, @params['search_terms'])
      when 'won-opps'
        Contact.with_won_opps(@params['page'].to_i, @params['search_terms'])
      end
    }.call
    
    @grouped_contacts = @contacts.sort { |a,b| a.last_first.downcase <=> b.last_first.downcase }.group_by{|c| c.last_first.downcase.chars.first}
    render :action => :contact_page, :back => 'callback:'
  end

  # GET /Contact/{1}
  def show
    Settings.record_activity
    @contact = Contact.find_contact(@params['id'])
    if @contact
      @next_id = (@contact.object.to_i + 1).to_s
      @prev_id = (@contact.object.to_i - 1).to_s
      render :action => :show, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']     
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def filter_contact
      Settings.record_activity
      $search_input1, $search_input2 = @params['search_input'].split(' ', 2)
      $filter = @params['contact_filter']
      WebView.navigate(url_for :controller => :Contact, :action => :index_filter, :query => {:search_input1 => search_in})
  end
  
  def check_preferred_and_donotcall(phone_type, preferred, allow_call, company_dnc)
    Settings.record_activity
    is_preferred = phone_type == preferred

    # Special case where we need 2 icons side by side, and some jQuery/JavaScript tricks are needed
    # We look for the two-icons attribute in the .erb and substitute a formatted HTML string that will show both
    if is_preferred && (allow_call == 'False' || company_dnc == 'True')
      return 'data-icon="check" two-icons=""'
    end
    
    if phone_type == preferred
      'data-icon="check"'
    elsif (allow_call == 'False' || company_dnc == 'True')
      'data-icon="delete"'
    else
      'data-icon="false"'
    end    
  end
  
  def show_edit_do_not_call_icon(allow_call, company_dnc)
    if allow_call == 'False' || company_dnc == 'True'
      '<img src="/public/images/glyphish-icons/28-star.png" height="18" width="18" />'
    end
  end
  
  def do_not_call_button(allow_call,company_dnc,phone_type,phone_number,contact)
    if allow_call == 'True' && company_dnc == 'False'
      %Q{
          <a href="#{url_for(:controller => :Contact, :action => :do_not_call_press, :id => @contact.object, :query => {:origin => @params['origin'], :phone_type => phone_type, :phone_number => phone_number, :contact => contact})}" data-role="button" data-theme="b">DNC</a>
        }
    end 
  end
  
  def do_not_call_press
    Settings.record_activity
    phone_type = @params['phone_type']
    phone_number = @params['phone_number']
    id = @params['id']
    
    message = "This will mark #{phone_number} as do not call."
    Alert.show_popup(
                {
                  :title => "Mark as Do Not Call?",
                  :message => message,
                  :buttons => ["Confirm","Cancel"],
                  :callback => url_for( :action => :do_not_call_press_callback, :query => {:phone_type => phone_type, :id => id, :origin => @params['origin']} )
                })
  end
  
  def do_not_call_press_callback
    Settings.record_activity
    button_id   = @params['button_id']
    id          = @params['id']
    phone_type  = @params['phone_type']
    
    contact = Contact.find_contact(id)
    
    if button_id == 'Confirm' and contact
      case phone_type
        when "Mobile"
          contact.update_attributes( { :cssi_allowcallsmobilephone => 'False', :cssi_companydncmobilephone => 'True' } )
        when "Home"
          contact.update_attributes( { :cssi_allowcallshomephone => 'False', :cssi_companydnchomephone => 'True' } )
        when "Business"
          contact.update_attributes( { :cssi_allowcallsbusinessphone => 'False', :cssi_companydncbusinessphone => 'True' } )
        when "Alternative"
          contact.update_attributes( { :cssi_allowcallsalternatephone => 'False', :cssi_companydncalternatephone => 'True' } )
      end
      
      SyncEngine.dosync
    end
    
    puts "******************** origin = #{@params['origin']}********************"
    
    WebView.navigate( url_for :controller => :Contact, :action => :show, :back => 'callback:', :id => id, :query =>{:origin => @params['origin']}, :layout => 'layout_jquerymobile' )
  end
  
  def select_preferred(phone_type, preferred)
    if phone_type == preferred
      return "selected"
    end
  end
  
  def age(dob)
    begin
      birthdate = Date.parse(dob)
       day_diff = Date.today - birthdate.day
       month_diff = Date.today.month - birthdate.month - (day_diff < 0 ? 1 : 0)
       "Age" + (Date.today.year - birthdate.year - (month_diff < 0 ? 1 : 0)).to_s
    rescue
      puts "Invalid date parameter in age calculation method; no age returned"
    end
  end
  
  def verify_pin
    @contact= Contact.find(@params['id'])
    if @params['PIN'] == Settings.pin
      puts @params.inspect
      Settings.pin_last_activity_time = Time.new
      Settings.pin_confirmed= true
      render :action => :show, :id => @params['id'], :query => {:origin => @params['origin']}
    else
      Alert.show_popup({
        :message => "Invalid PIN Entered", 
        :title => 'Invalid PIN', 
        :buttons => ["OK"]
      })
      @pinverified="false"
      render :action => :show, :id => @params['id'], :query => {:origin => @params['origin']}
    end    
  end
  
  def pin_is_current?(last_activity)
    if Time.new - last_activity < 900
      return true
    else
      return false
    end
  end

  # GET /Contact/new
  def new
    Settings.record_activity
    @contact = Contact.new
    render :action => :new, :back => 'callback:', :layout => 'layout_jquerymobile'
  end

  # GET /Contact/{1}/edit
  def edit
    Settings.record_activity
    @contact = Contact.find_contact(@params['id'])
    if @contact
      render :action => :edit, :back => 'callback:'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end

  # POST /Contact/create
  def create
    @contact = Contact.create_new(@params['contact'])
    @contact.update_attributes(:birthdate => DateUtil.birthdate_build(@contact.birthdate))
    @contact.update_attributes(:cssi_allowcallsalternatephone => "True")
    @contact.update_attributes(:cssi_allowcallshomephone => "True")
    @contact.update_attributes(:cssi_allowcallsbusinessphone => "True")
    @contact.update_attributes(:cssi_allowcallsmobilephone => "True")
    @contact.update_attributes(:cssi_companydncbusinessphone => "False")
    @contact.update_attributes(:cssi_companydncmobilephone => "False")
    @contact.update_attributes(:cssi_companydnchomephone => "False")
    @contact.update_attributes(:cssi_companydncalternatephone => "False")
        
    @opp = Opportunity.create_new(@params['opportunity'])  
    Settings.record_activity
    @opp.update_attributes( :contact_id =>  @contact.object)
    @opp.update_attributes( :statecode => 'Open')
    @opp.update_attributes( :cssi_statusdetail => 'New')
    @opp.update_attributes( :statuscode => 'New Opportunity')
    @opp.update_attributes( :createdon => Time.now.strftime("%Y-%m-%d %H:%M:%S"))

    SyncEngine.dosync
    redirect :action => :show, 
             :back => 'callback:',
             :id => @contact.object,
             :query =>{:origin => @params['origin'], :opportunity => @opp.object}
  end

  # POST /Contact/{1}/update
  def update
    Settings.record_activity
    puts "CONTACT UPDATE: #{@params.inspect}"
    @contact = Contact.find_contact(@params['id'])
    @contact.update_attributes(@params['contact']) if @contact
    SyncUtil.start_sync
    redirect :action => :show, :back => 'callback:',
              :id => @contact.object,
              :query =>{:opportunity => @params['opportunity'], :origin => @params['origin']}
  end

  def spouse_update
    Settings.record_activity
    puts "SPOUSE UPDATE: #{@params.inspect}"
    @contact = Contact.find_contact(@params['id'])
    @contact.update_attributes(@params['contact']) if @contact
    @contact.update_attributes(:cssi_spousebirthdate => DateUtil.birthdate_build(@contact.cssi_spousebirthdate))
    SyncEngine.dosync
    redirect :action => :show, :back => 'callback:',
              :id => @contact.object,
              :query =>{:opportunity => @params['opportunity'], :origin => @params['origin']}
  end

  # POST /Contact/{1}/delete
  def delete
    @contact = Contact.find_contact(@params['id'])
    @contact.destroy if @contact
    redirect :action => :index, :back => 'callback:'
  end

  def map
    WebView.refresh
      if System::get_property('platform') == 'APPLE'
        System.open_url("maps:q=#{@params['address']}")
      else
        System.open_url("http://maps.google.com/?q= #{@params['address'].strip.gsub(/ /,'+')}")
      end
  end
  
  def maptest
      System.open_url("maps:q=5918_capella_park_dr+houston+tx")
  end
  
  def spouse_show
    Settings.record_activity
      @contact = Contact.find_contact(@params['id'])
      render :action => :spouse_show, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin'] 
  end
  
  def spouse_add
    Settings.record_activity
      @contact = Contact.find_contact(@params['id'])
      render :action => :spouse_add, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin'] 
  end
  
  def spouse_edit
    Settings.record_activity
      @contact = Contact.find_contact(@params['id'])
      render :action => :spouse_edit, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin'] 
  end
  
  def confirm_spouse_delete
    Alert.show_popup ({
        :message => "Click OK to Delete this Spouse", 
        :title => "Confirm Delete", 
        :buttons => ["Cancel", "Ok",],
        :callback => url_for(:action => :spouse_delete, 
                                        :query => {
				                                :id => @params['id'],
				                                :origin => @params['origin'], 
				                                :opportunity => @params['opportunity']
				                                })
				                   })
  end
 
  def spouse_delete
    Settings.record_activity
    if @params['button_id'] == "Ok"
      puts "CONTACT DELETE SPOUSE: #{@params.inspect}"
      @contact = Contact.find_contact(@params['id'])
      @contact.update_attributes(:cssi_spousename => "")
      @contact.update_attributes(:cssi_spouselastname => "")
      @contact.update_attributes(:cssi_spousebirthdate => "")
      @contact.update_attributes(:cssi_spouseheightft => "")
      @contact.update_attributes(:cssi_spouseheightin => "")
      @contact.update_attributes(:cssi_spouseweight => "")
      @contact.update_attributes(:cssi_spouseusetobacco => "")
      @contact.update_attributes(:cssi_spousegender => "")
      SyncEngine.dosync
      WebView.navigate(url_for :controller => :Contact, :action => :show, :id => @contact.object, :query => {:origin => @params['origin'], :opportunity => @params['opportunity']})
    else
      WebView.navigate(url_for :controller => :Contact, :action => :spouse_edit, :id => @params['id'], :query => {:origin => @params['origin'], :opportunity => @params['opportunity']})
    end
  end
  
end
