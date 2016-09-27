require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/application_helper'
require 'date'
require 'time'
require 'rho/rhotabbar'

class OpportunityController < Rho::RhoController
  include BrowserHelper
  $saved = nil
  $choosed = {}

  # this callback is set once in the login_callback method of the Settings controller
  def init_notify
	@@delay_refresh = false
  display_label = System.get_property('platform') == 'ANDROID' && System::get_property('os_version').split('.')[0].to_i >= 6
    tabbar = [
      { 
        :label => display_label ? "Opportunities" : "", 
        :action => '/app/Opportunity', 
        :icon => "/public/images/dollar.png", 
        :backgroundColor => 0x7F7F7F
      }, 
      { 
        :label => display_label ? "Contacts" : "", 
        :action => "callback:#{url_for(:controller => :Contact, :action => :show_all_contacts)}",  
        :icon => "/public/images/contacts.png", 
        :reload => true 
      },
      {
        :label => display_label ? "Activities" : "",
        :action => "callback:#{url_for(:controller => :Activity, :action => :show_all_activities)}",
        :icon => "/public/images/glyphish-icons/117-todo.png",
        :reload => true
      },
      { 
        :label => display_label ? "Tools" : "",  
        :action => '/app/Settings',  
        :icon => "/public/images/iphone/tabs/settings_tab_icon.png" 
      }
    ]
    
    # Rho::NativeTabbar.create(tabbar)
	
	params = {"placeTabsBottom" => true}
    Rho::NativeTabbar.create(tabbar, params, 'app/Opportunity/tab_switch_callback')    
	
    Rho::NativeTabbar.switch_tab(0)
    
    $new_leads_nav_context = []
    $follow_ups_nav_context = []
    $appointments_nav_context = []
    
    #Reset the first render flags to true for activity and contact pages
    ContactController.reset_first_render
    ActivityController.reset_first_render
   
  end
  
  def tab_switch_callback
    current_index = @params['tab_index'].to_i
    WebView.executeJavascript("setAppDeactive();", 0) 
    WebView.executeJavascript("setAppDeactive();", 1) 
    WebView.executeJavascript("setAppDeactive();", 2) 
    WebView.executeJavascript("setAppDeactive();", 3) 
    WebView.executeJavascript("setAppActive();",current_index) 
     
    if Opportunity.local_changed? && (current_index == 0)  && @@delay_refresh == false
      WebView.navigate(url_for(:action => :index, :back => 'callback:', :query => {:selected_tab => $current_nav_context}))
    end
    @@delay_refresh = false
  end
  
  def self.delay_opportunity_index_refresh
    @@delay_refresh = true
  end  
  
  def refresh_if_changed
    if Opportunity.local_changed?
      WebView.navigate( url_for(:action => :index, :back => 'callback:', :query => {:selected_tab => @params['tab']}) )
    end
  end
  
  def create_note
    puts "*^*^*^*^*^*^*^*^*^*^*^ CREATE_NOTE ^*^*^*^*^*^*^*^*^*^*^*^*^*"
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @opportunity.create_note(@params['note_text'])
  end
  
  def intialize_nav_contexts
    $new_leads_nav_context = []
    $follow_ups_nav_context = []
    $appointments_nav_context = []
  end
  
  # since this is the default entry point on startup, check here for login
  def index
    $tab = 0
    if Rho::RhoConnectClient.isLoggedIn()
      intialize_nav_contexts
      Opportunity.local_changed = false
      @params['selected_tab'] = @params['selected_tab'].blank? ? 'new-leads' : @params['selected_tab']
      @persisted_scheduled_search = Settings.get_persisted_filter_values(Constants::PERSISTED_SCHEDULED_FILTER_PREFIX, Constants::SCHEDULED_FILTERS)['search']
      $current_nav_context = @params['selected_tab']
      @page_name = 'Opportunities'
      @firstBtnText = 'Create'
      @firstBtnIcon = 'plus'
      @firstBtnUrl = url_for :action => :contact_opp_new, :query => { :origin => @params['selected_tab'] }
      @firstBtnBack = false
      @firstBtnExternal = false
      @secondBtnUrl = nil
      @scriptName = 'opportunities'
      @pageSize = 30
      @url = '/app/Opportunity/get_jqm_leads'
      @filterBtnText = 'Filter'
      render :action => :filters, :back => 'callback:', :layout => 'layout_jqm_opportunity_list'
    else
      redirect :controller => Settings, :action => :login, :back => 'callback:', :layout => 'layout'
    end
  end
  def gen_jqm_options(options, selected_value)
    options.map{|option|
      selected_text = (option[:value] == selected_value) ? ' selected="true"' : ''
      "<option value=\"#{option[:value]}\"#{selected_text}>#{option[:label]}</option>"
    }.join("\n")
  end
  def jqm_followup_status_reason_filter_options  	
  	options = [
      {:value => 'All', :label => 'All'},
      {:value => 'NoContactMade', :label => 'No Contact Made'},
      {:value => 'ContactMade', :label => 'Contact Made'},
      {:value => 'AppointmentSet', :label => 'Appointment Set'},
      {:value => 'DealInProgress', :label => 'Deal in Progress'}
    ]
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}statusReason"]
    persisted_selection = 'All' if persisted_selection.blank?
    gen_jqm_options(options, persisted_selection)
  end
  def jqm_followup_sort_by_filter_options
		options = [
      {:value => 'LastActivityDateAscending', :label => 'Latest Activity Date'},
      {:value => 'LastActivityDateDescending', :label => 'Earliest Activity Date'},
      {:value => 'CreateDateAscending', :label => 'Created Ascending'},
      {:value => 'CreateDateDescending', :label => 'Created Descending'}
    ]
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}sortBy"]
    persisted_selection = 'LastActivityDateAscending' if persisted_selection.blank?
    gen_jqm_options(options, persisted_selection)
  end
  def jqm_followup_created_filter_options
    options = [
      {:value => 'All', :label => 'All'},
      {:value => '1', :label => '1 Day Ago'},
      {:value => '2', :label => '2 Days Ago'},
      {:value => '3', :label => '3 Days Ago'},
      {:value => '4', :label => '4 Days Ago'},
      {:value => '5', :label => '5 Days Ago'}
    ]
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}created"]
    persisted_selection = 'All' if persisted_selection.blank?
    gen_jqm_options(options, persisted_selection)
  end
  def jqm_followup_daily_filter_options
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}isDaily"]
    " checked='checked' " if persisted_selection == 'true'
  end
  def jqm_scheduled_filter_type_options
    options = [
      {:value => 'All', :label => 'All'},
      {:value => 'ScheduledAppointments', :label => 'Appointments'},
      {:value => 'ScheduledCallbacks', :label => 'Callbacks'}
    ]
    persisted_selection = Settings.filter_values['scheduled_filter_type']
    persisted_selection = 'All' if persisted_selection.blank?
    gen_jqm_options(options, persisted_selection)
  end
  def jqm_scheduled_filter_date_options
	options = [
      {:value => 'All', :label => 'All'},
      {:value => 'past_due', :label => 'Past Due'},
      {:value => 'today', :label => 'Today'},
      {:value => 'future', :label => 'Future Date'},
    ]
    persisted_selection = Settings.filter_values['scheduled_filter_date']
    persisted_selection = 'All' if persisted_selection.blank?
    gen_jqm_options(options, persisted_selection)
  end
  def get_jqm_leads
    @self_id = StaticEntity.system_user_id
    rows = []
    origin = 'new-leads'
    f_status = @params['statusReason']
    if f_status
      # follow-ups
      origin = 'follow-ups'
      rows = jqm_get_follow_ups
    else
      f_select = @params['filter_type']
      if f_select
        # scheduled
        origin = 'appointments'
        rows = jqm_get_appointments
      else
        # new leads
        rows = jqm_get_new_leads
      end
    end
    $current_nav_context = origin
    render :partial => 'opportunity', :locals => { :items => rows, :origin => origin, :selected_tab => origin }
  end
  def jqm_get_new_leads
    Settings.record_activity
    if @params['reset'] == 'true'
      @@data_loader = ApplicationHelper::HierarchyDataLoader.new([
          { :divider => 'Today' },
          [Opportunity, :todays_new_leads],
          { :divider => 'Previous Days' },
          [Opportunity, :previous_days_leads]
      ], 0, 1, true)
      $new_leads_nav_context = []
    end
    page = @params['page'].to_i
    page_size = @params['pageSize'].to_i
    @@data_loader.load_data([page, page_size], $new_leads_nav_context)
  end
  def jqm_get_follow_ups
    Settings.record_activity
    Settings.update_persisted_filter_values(Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX, Constants::FOLLOWUP_FILTERS.map{|filter| filter[:name]}, @params)
    persisted_filter_values = Settings.get_persisted_filter_values(Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX, Constants::FOLLOWUP_FILTERS)
    if @params['reset'] == 'true'
      @@data_loader = ApplicationHelper::HierarchyDataLoader.new([
          [Opportunity, :by_last_activities]
      ], 0, 5, true)
      $follow_ups_nav_context = []
    end
    page = @params['page'].to_i
    page_size = @params['pageSize'].to_i
    result = @@data_loader.load_data([page, persisted_filter_values['statusReason'], persisted_filter_values['sortBy'], persisted_filter_values['created'], persisted_filter_values['isDaily'], page_size], $follow_ups_nav_context)
    result
  end
  
  def jqm_get_appointments
    Settings.record_activity
	puts "Appointment Parameters: #{@params}"
    Settings.update_persisted_filter_values(Constants::PERSISTED_SCHEDULED_FILTER_PREFIX, Constants::SCHEDULED_FILTERS.map{|filter| filter[:name]}, @params)
    persisted_filter_values = Settings.get_persisted_filter_values(Constants::PERSISTED_SCHEDULED_FILTER_PREFIX, Constants::SCHEDULED_FILTERS)
    @scheduled_date = persisted_filter_values["filter_date"]
    if @params['reset'] == 'true'  
        if @scheduled_date == "past_due" 
            prms = [{ :divider => 'Past Due' },
                        [Activity, :appointment_list, 'past_due']]
          elsif @scheduled_date == "today"
                prms = [{ :divider => 'Today' },
                        [Activity, :appointment_list, 'today']]
          elsif @scheduled_date == "future"
                prms = [{ :divider => 'Future' },
                          [Activity, :appointment_list, 'future'] ]
          else
           prms = [
                  { :divider => 'Past Due' },
                  [Activity, :appointment_list, 'past_due'],
                  { :divider => 'Today' },
                  [Activity, :appointment_list, 'today'],
                  { :divider => 'Future' },
                  [Activity, :appointment_list, 'future']
                ]
       end
      
      @@data_loader = ApplicationHelper::HierarchyDataLoader.new(prms, 0, 4, false, 3)
      $appointments_nav_context = []
    end
    page = @params['page'].to_i
    page_size = @params['pageSize'].to_i
    result = @@data_loader.load_data([page, persisted_filter_values['filter_type'], persisted_filter_values['filter_date'], '', page_size], $appointments_nav_context)
    $appointments_nav_context.uniq!
    puts "End jqm_get_appointments: #{$appointments_nav_context}"
    result
  end
  
  def set_opportunities_nav_context(context=nil)
    $current_nav_context = @params['context'] || context
    render :back => 'callback:'
  end
  
  def current_nav_context
    case $current_nav_context
      when 'new-leads' then $new_leads_nav_context
      when 'follow-ups' then $follow_ups_nav_context
      when 'appointments' then $appointments_nav_context
    end
  end

  def check_for_context_reset(tab)
    init_tab_load = @params['init_tab_load']
    if init_tab_load == 'true'      
      case tab
      when 'appointments'
        $appointments_nav_context = []
      when 'follow-ups'
        $follow_ups_nav_context = []
      when 'new-leads'
        $new_leads_nav_context = []
      end
    end
  end
  
  
  # GET /Opportunity/{1}
  def show
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @notes = @opportunity.notes if @opportunity
    current_nav_context.orient!(@opportunity.object) if @opportunity
    @contact = @opportunity.contact if @opportunity
    if @opportunity && @contact
      render :action => :show, :back => 'callback:', :layout => 'layout'
    else
      redirect_to_index_page
    end
  end
  
  def show_previous
    show_opportunity_from_nav('previous!')
  end
  
  def show_next
    show_opportunity_from_nav('next!')
  end
  
  def show_opportunity_from_nav(direction)
  
    if current_nav_context.blank?
       opp_id = @params['id']
    else
      opp_id = current_nav_context.send(direction)
    end
    
    @opportunity = Opportunity.find_opportunity(opp_id)
    @contact = @opportunity.contact unless @opportunity.blank?
    
    if @opportunity && @contact
      @notes = @opportunity.notes
      current_nav_context.orient!(@opportunity.object)
      render :action => :show, :back => 'callback:', :layout => 'layout', :origin => @params['origin']
    else
      current_nav_context.delete(opp_id)
      if current_nav_context.count >= 1
        show_opportunity_from_nav(direction)
      else
        WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_jqm_opportunity_list', :query => {:selected_tab => @params['origin']}))
      end  
    end
  end
  
  def status_update
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @contact = @opportunity.contact if @opportunity
    @incomplete_appointments = @opportunity.incomplete_appointments if @opportunity
    if @opportunity && @contact
      render :action => :status_update, :back => 'callback:', :layout => 'layout'
    else
      redirect_to_index_page
    end
  end 
  
  def note_create
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @contact = @opportunity.contact if @opportunity
    if @opportunity && @contact
      render :action => :note_create, :back => 'callback:', :layout => 'layout'
    else
      redirect_to_index_page
    end
  end  

  def contact_opp_new    
     redirect :action => :new,
              :controller => "Contact",
              :query =>{:origin => $current_nav_context}
  end
  
  def callback_request
    Settings.record_activity
    $choosed['0'] = ""
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @contact = @opportunity.contact if @opportunity
    if @opportunity && @contact
      @opportunity.create_note(@params['notes'])
      render :action => :callback_request, :back => 'callback:', :layout => 'layout'
    else
      redirect_to_index_page
    end
  end
  
  def app_detail_add
    Settings.record_activity
      @opportunity = Opportunity.find_opportunity(@params['id'])
      if @opportunity
        render :Controller => :ApplicationDetail, :action => :new, :back => 'callback:', :layout => 'layout'
      else
        redirect :action => :index, :back => 'callback:'
      end
  end
    
  def app_detail_show
      # @appdetail = Opportunity.find(@params['id'])
      # if @appdetail
        render :Controller => :ApplicationDetail, :action => :show, :back => 'callback:', :layout => 'layout'
      # else
      #   redirect :action => :index, :back => 'callback:'
      # end
  end
    
  def app_detail_edit
    Settings.record_activity
    @appdetail = Opportunity.find_opportunity(@params['id'])
    if @appdetail
      render :Controller => :ApplicationDetail, :action => :edit, :back => 'callback:', :layout => 'layout'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
    
  def app_detail_create
    opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
    db = ::Rho::RHO.get_src_db('Opportunity')
    db.start_transaction
      begin
        opportunity.create_note(@params['notetext'])
        finished_note_create(opportunity, @params['origin'])
        db.commit
      rescue Exception => e
        puts "Exception in update status call back requested, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
      end
  end
  
  def app_detail_update
    opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
    db = ::Rho::RHO.get_src_db('Opportunity')
    db.start_transaction
      begin
        opportunity.create_note(@params['notetext'])
        finished_note_create(opportunity, @params['origin'])
        db.commit
      rescue Exception => e
        puts "Exception in update status call back requested, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
      end
  end
  
  def appointment
    $choosed['0'] = ""
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @contact = @opportunity.contact  unless @opportunity.blank?
    if @opportunity && @contact
      @opportunity.create_note(@params['notes'])
      render :action => :appointment, :back => 'callback:', :layout => 'layout'
    else
      redirect_to_index_page
    end
  end
  
  def lost
    @lost_reasons = Constants::OTHER_LOST_REASONS
    @competitors = Constants::COMPETITORS
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @contact = @opportunity.contact  unless @opportunity.blank?
    if @opportunity && @contact
      @opportunity.create_note(@params['notes'])
      render :action => :lost_other, :back => 'callback:', :layout => 'layout'
    else
      redirect_to_index_page
    end
  end
  
  
  
  def won
      @opportunity = Opportunity.find_opportunity(@params['id'])
      @contact = @opportunity.contact  unless @opportunity.blank?
      if @opportunity && @contact
        @opportunity.create_note(@params['notes'])
        render :action => :mark_as_won, :back => 'callback:', :layout => 'layout'
      else
        redirect_to_index_page
      end
  end
  
  # GET /Opportunity/{1}/activity_summary
  def activity_summary
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @activity_list = @opportunity.activity_list unless @opportunity.blank?
    @contact = @opportunity.contact  unless @opportunity.blank?
    if @opportunity && @contact
      render :action => :activity_summary, :back => 'callback:',
              :layout => 'layout',
              :origin => @params['origin']
    else
      redirect_to_index_page
    end
  end

  def phone_dialog
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @contact = @opportunity.contact unless @opportunity.blank?
    phone_number=''
    if @contact.blank?
      WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_jqm_opportunity_list'),Constants::TAB_INDEX['Opportunities'])  
    elsif @contact.phone_numbers.size < 2
      @contact.phone_numbers.each do |type, number|
        phone_number = number
      end
      
      redirect :action => :call_number,
              :id => @opportunity.object,
              :query =>{:origin => @params['origin'],
                        :phone_number => phone_number,
                        :redirect_action => :show} 
    else
      render :action => :phone_dialog, :back => 'callback:', :layout => 'layout'
    end
  end
  
  def save
    $saved = 1
    redirect :action => :index, :back => 'callback:'
  end
  
  def call_number
    puts "calling number: #{@params['phone_number']}"
    telephone = @params['phone_number']
    telephone.gsub!(/[^0-9]/, "")
    
    action = @params['redirect_action']
    
    if action.blank?
      #if redirect_action wasn't given, default based on the opportunity's state
      opportunity = Opportunity.find_opportunity(@params['id'])
      action = opportunity.closed? ? :show : :status_update
    else
      #otherwise convert the given action to a symbol so it will be compatible with redirect
      action = action.to_sym
    end
        
    redirect :action => action, :back => 'callback:',
              :id => @params['id'],
              :query =>{:origin => @params['origin'], :opportunity => @params['opportunity']}
    System.open_url("tel:#{telephone}") if !telephone.blank?
  end

  def birthPopup
    flag = @params['flag']
    if ['0', '1', '2'].include?(flag)
      ttt = $choosed[flag]
        if  @params['preset'].blank?
          preset_time = Time.new - 1157000000
        else
          preset_time= (Time.strptime(@params['preset'], '%m/%d/%Y'))
        end
      DateTimePicker.choose url_for(:action => :callback, :back => 'callback:'), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
    end
    render :back => 'callback:'
  end
  
  def tomorrowPopup
    flag = @params['flag']
    if ['0', '1', '2'].include?(flag)
      ttt = $choosed[flag]
      if  @params['preset'].blank?
        preset_time = Time.new + 86400 + DateUtil.seconds_until_hour(Time.new)
      else
          # Reading java script format "11/13/2012 03:00 PM"
          preset_time = (Time.strptime(@params['preset'], '%m/%d/%Y %I:%M %p')) if flag == '0'
          preset_time = (Time.strptime(@params['preset'], '%m/%d/%Y')) if flag == '1'
      end
      DateTimePicker.choose url_for(:action => :callback, :back => 'callback:'), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
    end
    render :back => 'callback:'
  end



  def callback
    if @params['status'] == 'ok'
     $saved = nil
     datetime_vars = Marshal.load(@params['opaque'])
      format = case datetime_vars[:flag]
        when "0" then '%m/%d/%Y %I:%M %p'
        when "1" then '%m/%d/%Y'
        when "2" then '%T'
        else '%F %T'
      end
      # formatted_result = Time.at(@params['result'].to_i).strftime('%m/%d/%Y %I:%M %p')
      formatted_result = Time.at(@params['result'].to_i).strftime(format)
      $choosed[datetime_vars[:flag]] = formatted_result
      WebView.executeJavascript('setFieldValue("'+datetime_vars[:field_key]+'","'+formatted_result+'"); ')
      $choosed = {} #Need to clear these out so that the fields don't populate with values previously selected.
      $saved = {}
    end
  end
  
  def date_build(date_string, time_value)
    date = (Date.strptime(date_string, '%m/%d/%Y'))
    result = date.strftime('%Y/%m/%d')
    result += " " + time_value[0,5]
    result
  end
  
  def end_date_time(date_value, time_value, duration)
    date = (DateTime.strptime(date_value + " " + time_value, '%m/%d/%Y %H:%M:%S'))
    end_date = date + ((duration.to_f)/60/24)
    end_date 
  end
  
  def quick_quote
    #This will take to term life quick quote
    opportunity = Opportunity.find_opportunity(@params['id'])
    contact = opportunity.contact unless opportunity.blank?
    quote_param =""
    if contact 
      formatted_dob = ''
         
      unless contact.birthdate.blank?
       parsed_dob = (Date.strptime(contact.birthdate, DateUtil::DEFAULT_TIME_FORMAT))
       formatted_dob = parsed_dob.strftime('%m/%d/%Y')
      end

      quote_param = ",dob=#{formatted_dob},gender=#{contact.gendercode}"

      unless contact.cssi_state1id.blank?
        quote_param += ",statecode=#{contact.cssi_state1id}"
      else
        quote_param += ",statecode=#{contact.cssi_state2id}"
      end
    end
    
    quote_url="#{Rho::RhoConfig.quick_quote_url}#{quote_param}"
    redirect :action => :show, :id => @params['id'], :layout => 'layout', :query=>{:origin => @params['origin']}
    System.open_url("#{quote_url}")
  end
  
  def quoting_tool
    #This will take the user to InSite quoting
    opportunity = Opportunity.find_opportunity(@params['id'])
    quoting_tool_url = AppInfo.instance.insite_url 

    
    opportunity_params = "#{opportunity.object}" if @params['id']

    #ctime = Time.new.utc
    #ctime_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{ctime}Delimit"))
    #user_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.login}Delimit"))
    #pwd_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.password}Delimit"))
    #quote_params_enc = "UserName=#{user_enc}&pwd=#{pwd_enc}&valid=#{ctime_enc}&#{opportunity_params}"
    #puts "Resource URL parameters are: ****#{quote_params_enc}****"
    quote_url="#{quoting_tool_url}/#{opportunity_params}"
 
    redirect :action => :index, :back => 'callback:', :layout => 'layout'
    
    System.open_url("#{quote_url}")
    
           
  end
  
  def map
        # WebView.refresh
        WebView.navigate(WebView.current_location)
        if System::get_property('platform') == 'APPLE'
          System.open_url("maps:q=#{@params['location'].strip.gsub(/ /,'+')}")
        else
            System.open_url("http://maps.google.com/?q=#{@params['location'].strip.gsub(/ /,'+')}")
        end
        #WebView.refresh
  end
  
  def new
    Settings.record_activity
    @contact = Contact.find_contact(@params['id'])
    render :action => :new, :back => 'callback:', :origin => @params['origin'], :layout => 'layout'
  end
  
  def create
    @contact = Contact.find_contact(@params['id'])
    @opp = Opportunity.create_new(@params['opportunity'])  
    Settings.record_activity
    @opp.update_attributes( :contact_id =>  @contact.object)
    @opp.update_attributes( :statecode => 'Open')
    @opp.update_attributes( :statuscode => 'New Opportunity')
    @opp.update_attributes( :createdon => Time.now.strftime("%Y-%m-%d %H:%M:%S"))
    @opp.update_attributes( :cssi_statusdetail => 'New')
    @opp.update_attributes( :opportunityratingcode => 'Warm')
    @opp.update_attributes( :cssi_inputsource => 'Manual')
    @opp.update_attributes( :ownerid => StaticEntity.system_user_id)  
    @opp.update_attributes( :cssi_assetownerid => StaticEntity.system_user_id)

    Opportunity.local_changed=true
    
    Rho::RhoConnectClient.doSync
    redirect  :controller => :Contact,
            :action => :show, 
             :back => 'callback:',
             :id => @contact.object,
             :query =>{:origin => @params['origin'], :opportunity => @opp.object}
  end

  def reassign
    Settings.record_activity
    opportunity = Opportunity.find_opportunity(@params['id'])
    if opportunity
      @opportunity_title = ""
      @opportunity_title = "#{opportunity.contact.full_name} - " if opportunity.contact
      @opportunity_title += "#{to_date(opportunity.createdon)}"
      @cancel_action = url_for :action => :show, :id => opportunity.object,
                               :query => {:origin => @params['origin']}
      @form_action = url_for :action => :reassign_confirm, :id => opportunity.object,
                             :query => {:origin => @params['origin']}
      agents = StaticEntity.get_agents
      selected_agent = @params['reassign_to']
      selected_agent = agents[0]['systemuserid'] if selected_agent.blank? && agents.length > 0
      @reassign_agent_options = agents.map {|agent|
        selected = (agent['systemuserid'] == selected_agent) ? 'selected="true"' : ''
        "<option  #{selected} value=\"#{agent['systemuserid']}\">#{agent['fullname']}</option>"
      }.join("\n")
      render :action => :reassign, :back => 'callback:',
             :layout => 'layout',
             :origin => @params['origin']
    else
      redirect_to_index_page  
    end
  
  end

  def reassign_confirm
    Settings.record_activity
    opportunity = Opportunity.find_opportunity(@params['id'])
    agent = StaticEntity.find_agent(@params['reassign_to'])
    if opportunity && agent
      @opportunity_title = ""
      @opportunity_title = "#{opportunity.contact.full_name} - " if opportunity.contact
      @opportunity_title += "#{to_date(opportunity.createdon)}"
      @agent_title = agent['fullname']
      @cancel_action = url_for :action => :reassign, :id => opportunity.object,
                               :query => {:reassign_to => @params['reassign_to'],
                                          :origin => @params['origin']}
      @yes_action = url_for :action => :do_reassign, :id => opportunity.object,
                            :query => {:reassign_to => @params['reassign_to'],
                                       :origin => @params['origin']}
      render :action => :reassign_confirm, :back => 'callback:',
             :layout => 'layout',
             :origin => @params['origin']
    else
      redirect_to_index_page
    end
  end

  def do_reassign
    Settings.record_activity
    opportunity = Opportunity.find_opportunity(@params['id'])
    if opportunity
      opportunity.update_attributes({
        :ownerid => @params['reassign_to']
      })
      SyncUtil.start_sync
    end
    redirect_to_index_page
  end
  
  def redirect_to_index_page
    if @params['origin'] == 'contact'
        WebView.navigate(url_for(:controller => :Contact, :action => :index, :back => 'callback:', :layout => 'layout_jqm_list'),Constants::TAB_INDEX['Contacts'])
    else   
        WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_jqm_opportunity_list'),Constants::TAB_INDEX['Opportunities'])
    end  
  end
  
end
