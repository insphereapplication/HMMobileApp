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
    @page_limit = System.get_property('platform') == "ANDROID" ? 3 : 10
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
    @contacts = Contact.get_filtered_contacts(@params)  
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
  
  def show_edit_do_not_call_icon(allow_call, company_dnc, phone_type)
    if allow_call == 'False' || company_dnc == 'True'
      '<img src="/public/images/dncIcon.png" class="dncIcon" />'
    else
      '<img src="/public/images/dncIcon.png" style="visibility:hidden;" id=' + phone_type + '_icon class="dncIcon"  />'
    end
  end
  
  def show_do_not_call_slider(allow_call,company_dnc,phone_number)
    return allow_call == 'True' && company_dnc == 'False' && !phone_number.blank?
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
    end
  end
  
  def verify_pin
    @contact= Contact.find(@params['id'])
    if @params['PIN'] == Settings.pin
      puts @params.inspect
      Settings.pin_last_activity_time = Time.new
      Settings.pin_confirmed = true
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
    
    @opp = Opportunity.create_for_new_contact(@params['opportunity'], @contact.object)
    
    SyncEngine.dosync
    redirect :action => :show, 
             :back => 'callback:',
             :id => @contact.object,
             :query =>{:origin => @params['origin'], :opportunity => @opp.object}
  end

  # POST /Contact/{1}/update
  def update
    Settings.record_activity
    
    dob_formatted = ''
    
    unless @params['birthdate'].blank?
      # convert date picker date format to DB date format
      dob_picker_time = DateTime.strptime(@params['birthdate'].to_s, DateUtil::BIRTHDATE_PICKER_TIME_FORMAT)
      dob_formatted = dob_picker_time.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      puts "Parsed updated birthdate to #{dob_formatted}"
    end
    
    ['alternate','home','business','mobile'].each do |dnctype|
      dncfield = "allowcalls#{dnctype}phone"
      companydncfield = "cssi_companydnc#{dnctype}phone"
      
      unless @params[dncfield].blank?
        puts "$"*80 + " dncfield = #{@params[dncfield]}"
        if @params[dncfield] == 'False'
          puts "$"*80 + " Changing DNC values for #{dnctype}"
          @params['contact'].merge!({"cssi_#{dncfield}" => 'False', "#{companydncfield}" => 'True'}) if @params['contact']
        end
      end
    end
    
    @params['contact'].merge!({'birthdate' => dob_formatted})
    
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
      WebView.execute_js("hideSpin();")
    end
  end
  
  def show_AC_contact    
    @contact_details = SearchContacts.find_by_id(@params['id'])
    render :action => :show_AC, :back => 'callback:', :id => @params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
  end
  
  #creates a contact on the device that already exists in CRM
  def create_AC_contact
    @devicecontact = Contact.find_contact(@params['contact']['contactid'])
    if @devicecontact
      contact = @devicecontact
    else
      contact = Contact.create_new(@params['contact'])
    end
    puts "CREATING THE NEW OPPORTUNITY FROM AC SEARCH"  
    opp = Opportunity.create_for_new_contact(@params['opportunity'], contact.object)
    SyncEngine.dosync
    redirect :controller => :Contact,
             :action => :show, 
             :id => contact.object,
             :query => { :origin => 'SearchContacts', :back => 'callback:'}
             
  end
  
end
