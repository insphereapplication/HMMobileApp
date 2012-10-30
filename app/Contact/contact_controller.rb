require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'
require 'time'
require 'rho/rhotabbar'

class ContactController < Rho::RhoController
  include BrowserHelper
  include SQLHelper

  @@first_render = true


  #GET /Contact
  #def index
  #  $tab = 1
  #  Settings.record_activity
  #  @page_limit = System.get_property('platform') == "ANDROID" ? 1 : 1
  #  @persisted_search_terms = Settings.get_persisted_filter_values(Constants::PERSISTED_CONTACT_FILTER_PREFIX, Constants::CONTACT_FILTERS)['search_terms']
  #  render :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'
  #end

  def index
    $tab = 1
    Settings.record_activity
    persisted_filter_values = Settings.get_persisted_filter_values(Constants::PERSISTED_CONTACT_FILTER_PREFIX, Constants::CONTACT_FILTERS)
    @persisted_search_terms = persisted_filter_values['search_terms']
    @page_name = 'Contacts'
    @firstBtnUrl = url_for :action => :new, :query => {:origin => 'contact'}
    @secondBtnText = 'Search AC'
    @secondBtnIcon = ''
    @secondBtnUrl = url_for :action=>:search, :controller => 'SearchContacts', :query => {:origin => 'contact'}
    @scriptName = 'contacts';
    @pageSize = 25;
    @items = Contact.get_filtered_contacts(0, 'all', @persisted_search_terms, 25)
    @itemTemplate = 'contact'
    render :action => :filter, :back => 'callback:', :layout => 'layout_jqm_list'
  end
  def gen_jqm_options(options, selected_value)
    options.map{|option|
      selected_text = (option[:value] == selected_value) ? ' selected="true"' : ''
      "<option value=\"#{option[:value]}\"#{selected_text}>#{option[:label]}</option>"
    }.join("\n")
  end
  def contact_filter_jqm_options
    options = [
      {:value => 'all', :label => 'All'},
      {:value => 'active-policies', :label => 'Active Policies'},
      {:value => 'pending-policies', :label => 'Pending Policies'},
      {:value => 'open-opps', :label => 'Open Opportunities'},
      {:value => 'won-opps', :label => 'Won Opportunities'}
    ]
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_CONTACT_FILTER_PREFIX}filter"]
    persisted_selection = 'all' if persisted_selection.blank?
    gen_jqm_options(options, persisted_selection)
  end
  def get_jqm_contacts_page
    persisted_filter_values = Settings.get_persisted_filter_values(Constants::PERSISTED_CONTACT_FILTER_PREFIX, Constants::CONTACT_FILTERS)
    @persisted_search_terms = persisted_filter_values['search_terms']
    @items = Contact.get_filtered_contacts(@params['page'], 'all', @persisted_search_terms, @params['pageSize'])
    render :partial => 'contact', :locals => { :items => @items, :search => @persisted_search_terms }
  end

  def show_all_contacts
    #puts "^^*^^ Contact.local_changed #{Contact.local_changed?}"
    #puts "^^*^^ Contact first render #{@@first_render}"
    if Contact.local_changed? || @@first_render
      Contact.local_changed = false
      @@first_render = false
      WebView.navigate(url_for(:controller => :Contact, :action => :index), Constants::TAB_INDEX['Contacts'])

    end
  end
  
  def self.reset_first_render
    @@first_render = true
  end
   
  
  def self.is_first_render?
    rendered = !!@rendered
    @rendered = true
    !rendered
  end
  
  def get_contacts_page
    Settings.record_activity
    
    Settings.update_persisted_filter_values(Constants::PERSISTED_CONTACT_FILTER_PREFIX, Constants::CONTACT_FILTERS.map{|filter| filter[:name]}, @params)
    
    persisted_filter_values = Settings.get_persisted_filter_values(Constants::PERSISTED_CONTACT_FILTER_PREFIX, Constants::CONTACT_FILTERS)
    
    @contacts = Contact.get_filtered_contacts(@params['page'], persisted_filter_values['filter'], persisted_filter_values['search_terms'])  
    @grouped_contacts = @contacts.sort { |a,b| a.last_first.downcase <=> b.last_first.downcase }.group_by{|c| c.last_first.downcase.chars.first}
    
    @contact_load_size = @contacts.size
    puts "Did we reach last?   size: #{@contacts.size}"
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
      'data-icon="donotcall"'
    else
      'data-icon="false"'
    end    
  end
  
  def show_edit_do_not_call_icon(allow_call, company_dnc, phone_type, phone_number)
    if (allow_call == 'False' || company_dnc == 'True') && !phone_number.blank?
      '<img src="/public/images/dncIcon_black_smaller.png" style="vertical-align:bottom;" />'
    else
      '<img id="' + phone_type + '" />'
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
    if @params['PIN'] == AppInfo.instance.policy_pin
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
    # capitalize names
    cp = @params['contact']
    if @contact.cssi_spousename.blank? && @contact.cssi_spouselastname.blank?
      # first time update, capitalize
      cp['cssi_spousename'] = cp['cssi_spousename'].capitalize_words if cp['cssi_spousename']
      cp['cssi_spouselastname'] = cp['cssi_spouselastname'].capitalize_words if cp['cssi_spouselastname']
    end
    @contact.update_attributes(cp) if @contact
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
  
  def new_contact_task
      Settings.record_activity
      @contact = Contact.find_contact(@params['id'])
      render :action => :new_contact_task, :back => 'callback:', :layout => 'layout_jquerymobile', :query => {:origin => @params['origin'], :opportunity => @params['opportunity']}
  end
  
  def new_contact_phonecall
      Settings.record_activity
      @contact = Contact.find_contact(@params['id'])
      render :action => :new_contact_phonecall, :back => 'callback:', :layout => 'layout_jquerymobile', :query => {:origin => @params['origin'], :opportunity => @params['opportunity']}
  end
  
  def finished_contact_activity(contact, origin, opportunity)
    SyncUtil.start_sync
    WebView.navigate(url_for(:action => :show, :id => contact.object, :back => 'callback:', :query => {:origin => origin, :opportunity => opportunity}, :layout => 'layout_JQM_lite'))
  end
  
  def create_new_contact_task
     contact = Contact.find_contact(@params['id'])
     db = ::Rho::RHO.get_src_db('Activity')
     db.start_transaction
     begin
       task = Activity.create_new({
         :scheduledend => DateUtil.date_build(@params['task_datetime']), 
         :subject => "#{@params['task_subject']}",
         :description => @params['task_description'],
         :parent_type => 'Contact', 
         :parent_id => contact.object,
         :parent_contact_id => contact.object,
         :statecode => 'Open',
         :type => 'Task',
         :prioritycode => @params['task_priority_checkbox'] ? 'High' : 'Normal',
         :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
       })
       db.commit
       finished_contact_activity(contact, @params['origin'], @params['opportunity'])
    rescue Exception => e
       puts "Exception in create new Task, rolling back: #{e.inspect} -- #{@params.inspect}"
       db.rollback
    end
  end
  
  def create_new_appointment
     contact = Contact.find_contact(@params['id'])
     db = ::Rho::RHO.get_src_db('Activity')
     db.start_transaction
     begin
       task = Activity.create_new({
         :parent_type => 'Contact', 
         :parent_id => contact.object,
         :parent_contact_id => contact.object,
         :scheduledstart => DateUtil.date_build(@params['appointment_datetime']), 
         :scheduledend => DateUtil.end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
         :subject => "#{@params['appointment_subject']}",
         :cssi_location => @params['cssi_location'],
         :location => @params['location'],
         :description => @params['appointment_description'],
         :statuscode => "Busy",
         :statecode => "Scheduled",
         :type => 'Appointment',
         :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
       })
       puts "!~!~!~!~!~!~!~!~!~ PARAMS FOR CREATE APPT ARE #{@params.inspect}"
       db.commit
       finished_contact_activity(contact, @params['origin'], @params['opportunity'])
    rescue Exception => e
       puts "Exception in create new appointment, rolling back: #{e.inspect} -- #{@params.inspect}"
       db.rollback
    end
  end

  def create_contact_phonecall
    Settings.record_activity
    @contact = Contact.find_contact(@params['id'])
    db = ::Rho::RHO.get_src_db('Activity')
    db.start_transaction
    begin
      phone_call = Activity.create_new({
        :scheduledstart => DateUtil.date_build(@params['callback_datetime']), 
        :subject => "#{@params['phonecall_subject']}",
        :prioritycode => @params['callback_priority_checkbox'] ? 'High' : 'Normal',
        :scheduleddurationminutes => Rho::RhoConfig.phonecall_duration_default_minutes.to_i,
        :scheduledend => DateUtil.end_date_time(@params['callback_datetime'], Rho::RhoConfig.phonecall_duration_default_minutes.to_i),
        :cssi_phonetype => @params['phone_type_selected'],
        :phonenumber => @params['phone_number'],
        :statuscode => 'Open',
        :statecode => 'Open',
        :type => 'PhoneCall',
        :parent_type => 'Contact', 
        :parent_id => @contact.object,
        :parent_contact_id => @contact.object,
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      })
   
      db.commit
      
    rescue Exception => e
      puts "Exception in create new Task, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end

    finished_contact_activity(@contact, @params['origin'], @params['opportunity'])
  end

  def new_contact_appointment
    Settings.record_activity
    @contact = Contact.find_contact(@params['id'])
    render :action => :new_contact_appointment, :back => 'callback:', :layout => 'layout_jquerymobile', :query => {:origin => @params['origin'], :opportunity => @params['opportunity']}
  end
end
