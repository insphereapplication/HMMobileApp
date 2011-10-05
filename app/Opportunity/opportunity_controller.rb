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
    
    
    tabbar = [
      { 
        :label => "Opportunities", 
        :action => '/app/Opportunity', 
        :icon => "/public/images/dollar.png", 
        :web_bkg_color => 0x7F7F7F 
      }, 
      { 
        :label => "Contacts", 
        :action => "callback:#{url_for(:controller => :Contact, :action => :show_all_contacts)}",  
        :icon => "/public/images/contacts.png", 
        :reload => true 
      },
      {
        :label => "Activities",
        :action => "callback:#{url_for(:controller => :Activity, :action => :show_all_activities)}",
        :icon => "/public/images/glyphish-icons/117-todo.png",
        :reload => true
      },
      { 
        :label => "Tools",  
        :action => '/app/Settings',  
        :icon => "/public/images/iphone/tabs/settings_tab_icon.png" 
      }
    ]
    
    # Rho::NativeTabbar.create(tabbar)
    Rho::NativeTabbar.create(:tabs => tabbar, :place_tabs_bottom => true)    
    Rho::NativeTabbar.switch_tab(0)
    
    $new_leads_nav_context = []
    $follow_ups_nav_context = []
    $appointments_nav_context = []
    $first_render = true
    
  end
  
  def refresh_if_changed
    if Opportunity.local_changed?
      WebView.navigate( url_for(:action => :index, :back => 'callback:', :query => {:selected_tab => @params['tab']}) )
    end
  end
  
  def create_note
    puts "*^*^*^*^*^*^*^*^*^*^*^ CREATE_NOTE ^*^*^*^*^*^*^*^*^*^*^*^*^*"
    @opportunity = Opportunity.find(@params['id'])
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
    if SyncEngine::logged_in == 1
      intialize_nav_contexts
      Opportunity.local_changed = false
      @params['selected_tab'] ||= 'new-leads'
      @persisted_scheduled_search = Settings.get_persisted_filter_values(Constants::PERSISTED_SCHEDULED_FILTER_PREFIX, Constants::SCHEDULED_FILTERS)['search']
      set_opportunities_nav_context(@params['selected_tab']);    
      render :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'
    else
      redirect :controller => Settings, :action => :login, :back => 'callback:', :layout => 'layout_JQM_Lite'
    end
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
  
  def get_new_leads(color, text, opportunities, page_number)
    check_for_context_reset('new-leads')
    $new_leads_nav_context += opportunities.map{|opp| opp.object }
    @color = color
    @label = text
    @page = opportunities
    @self_id = StaticEntity.system_user_id
    render :action => :opportunity_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def todays_new_leads
    get_new_leads('red', 'Today', Opportunity.todays_new_leads(@params['page'].to_i), @params['page'])
  end
  
  def previous_days_new_leads
    get_new_leads('orange', 'Previous Days', Opportunity.previous_days_leads(@params['page'].to_i), @params['page'])
  end

  def by_last_activities
    Settings.update_persisted_filter_values(Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX, Constants::FOLLOWUP_FILTERS.map{|filter| filter[:name]}, @params)
    persisted_filter_values = Settings.get_persisted_filter_values(Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX, Constants::FOLLOWUP_FILTERS)
    
    opportunities = Opportunity.by_last_activities(@params['page'].to_i, persisted_filter_values['statusReason'], persisted_filter_values['sortBy'], persisted_filter_values['created'])
    
    check_for_context_reset('follow-ups')
    $follow_ups_nav_context += opportunities.map{|opp| opp.object }
    
    @page = opportunities
    @self_id = StaticEntity.system_user_id
    render :action => :last_activities_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def get_filtered_appointments(color, label, bucket)
    Settings.update_persisted_filter_values(Constants::PERSISTED_SCHEDULED_FILTER_PREFIX, Constants::SCHEDULED_FILTERS.map{|filter| filter[:name]}, @params)
    persisted_filter_values = Settings.get_persisted_filter_values(Constants::PERSISTED_SCHEDULED_FILTER_PREFIX, Constants::SCHEDULED_FILTERS)
    
    appointments = Activity.appointment_list(@params['page'].to_i, persisted_filter_values['filter'], persisted_filter_values['search'], bucket)
    
    check_for_context_reset('appointments')
    $appointments_nav_context += appointments.map{|appointment| appointment.opportunity.object }
    
    @color = color
    @label = label
    @page = appointments
    @self_id = StaticEntity.system_user_id
    
    render :action => :appointments_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def future_scheduled
    get_filtered_appointments('green', 'Future', 'future')
  end

  def todays_scheduled
    get_filtered_appointments('orange', 'Today', 'today')
  end

  def past_due_scheduled    
    get_filtered_appointments('red', 'Past Due', 'past_due')
  end
  
  # GET /Opportunity/{1}
  def show
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    if @opportunity
      @notes = @opportunity.notes
      current_nav_context.orient!(@opportunity.object)
      @contact = @opportunity.contact
      render :action => :show, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
       if @params['origin'] == 'contact'
         WebView.navigate(url_for(:controller => :Contact, :action => :index, :back => 'callback:'))
       else   
         redirect  :action => :index, :back => 'callback:'
       end
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
      render :action => :show, :back => 'callback:', :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      current_nav_context.delete(opp_id)
      if current_nav_context.count >= 1
        show_opportunity_from_nav(direction)
      else
        WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))
      end  
    end
  end
  
  def status_update
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    if @opportunity
      render :action => :status_update, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end 
  
  def note_create
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    if @opportunity
      render :action => :note_create, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
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
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      @opportunity.create_note(@params['notes'])
      render :action => :callback_request, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def app_detail_add
    Settings.record_activity
      @opportunity = Opportunity.find(@params['id'])
      if @opportunity
        render :Controller => :ApplicationDetail, :action => :new, :back => 'callback:', :layout => 'layout_jquerymobile'
      else
        redirect :action => :index, :back => 'callback:'
      end
  end
    
  def app_detail_show
      # @appdetail = Opportunity.find(@params['id'])
      # if @appdetail
        render :Controller => :ApplicationDetail, :action => :show, :back => 'callback:', :layout => 'layout_jquerymobile'
      # else
      #   redirect :action => :index, :back => 'callback:'
      # end
  end
    
  def app_detail_edit
    Settings.record_activity
    @appdetail = Opportunity.find(@params['id'])
    if @appdetail
      render :Controller => :ApplicationDetail, :action => :edit, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
    
  def app_detail_create
    opportunity = Opportunity.find(@params['opportunity_id'])
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
    opportunity = Opportunity.find(@params['opportunity_id'])
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
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      @opportunity.create_note(@params['notes'])
      render :action => :appointment, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def lost_other
    @lost_reasons = Constants::OTHER_LOST_REASONS
    @competitors = Constants::COMPETITORS
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      @opportunity.create_note(@params['notes'])
      render :action => :lost_other, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def won
      @opportunity = Opportunity.find(@params['id'])
      if @opportunity
        @opportunity.create_note(@params['notes'])
        render :action => :mark_as_won, :back => 'callback:', :layout => 'layout_jquerymobile'
      else
        redirect :action => :index, :back => 'callback:'
      end
  end
  
  # GET /Opportunity/{1}/activity_summary
  def activity_summary
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @activity_list = @opportunity.activity_list unless @opportunity.blank?
    if @opportunity
      render :action => :activity_summary, :back => 'callback:',
              :layout => 'layout_jquerymobile',
              :origin => @params['origin']
    else
      WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))    
    end
  end

  def phone_dialog
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @contact = @opportunity.contact unless @opportunity.blank?
    phone_number=''
    if @contact.blank?
      WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))  
    elsif @contact.phone_numbers.size == 1
      @contact.phone_numbers.each do |type, number|
        phone_number = number
      end
      
      redirect :action => :call_number,
              :id => @opportunity.object,
              :query =>{:origin => @params['origin'],
                        :phone_number => phone_number,
                        :redirect_action => :show} 
    else
      render :action => :phone_dialog, :back => 'callback:', :layout => 'layout_JQM_Lite'
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
    System.open_url("tel:#{telephone}")
  end

  def birthpopup
    flag = @params['flag']
    if ['0', '1', '2'].include?(flag)
      ttt = $choosed[flag]
        preset_time = Time.new - 1157000000
      DateTimePicker.choose url_for(:action => :callback, :back => 'callback:'), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
    end
    render :back => 'callback:'
  end
  
  def popup
    flag = @params['flag']
    if ['0', '1', '2'].include?(flag)
      ttt = $choosed[flag]
        preset_time = Time.new + 86400 + DateUtil.seconds_until_hour(Time.new)
      DateTimePicker.choose url_for(:action => :callback, :back => 'callback:'), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
    end
    render :back => 'callback:'
  end

  def edit_popup
     flag = @params['flag']
      if ['0', '1', '2'].include?(flag)
        ttt = $choosed[flag]
          preset_time= Time.parse(@params['preset'])
        DateTimePicker.choose url_for(:action => :callback, :back => 'callback:'), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
      end
      render :back => 'callback:'
  end
    
  def appdatepopup
      flag = @params['flag']
      if ['0', '1', '2'].include?(flag)
        ttt = $choosed[flag]
        if @params['preset'].nil?
          preset_time = Time.new
        else 
          preset_time = Time.parse(@params['preset'])
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
      WebView.execute_js('setFieldValue("'+datetime_vars[:field_key]+'","'+formatted_result+'");')
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
    redirect :action => :show, :id => @params['id'], :layout => 'layout_jquerymobile', :query=>{:origin => @params['origin']}
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
    render :action => :new, :back => 'callback:', :origin => @params['origin'], :layout => 'layout_jquerymobile'
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
    
    SyncEngine.dosync
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
        "<option class=\"ui-btn-text\" #{selected} value=\"#{agent['systemuserid']}\">#{agent['fullname']}</option>"
      }.join("\n")
      render :action => :reassign, :back => 'callback:',
             :layout => 'layout_jquerymobile',
             :origin => @params['origin']
    else
      WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))
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
             :layout => 'layout_jquerymobile',
             :origin => @params['origin']
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
    redirect :action => :index, :back => 'callback:'
  end
end
