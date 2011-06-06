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

  def sync_notify
    if @params['status'] == 'ok' or @params['status'] == 'complete'
      Rho::NativeTabbar.switch_tab(0) 
      WebView.navigate( 
        url_for(
          :controller => 'Opportunity',
          :action => :index
        )
      )
    end
  end
	  
  # this callback is set once in the login_callback method of the Settings controller
  def init_notify
    System.set_push_notification("/app/Settings/push_notify", '')
    
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
  
  def get_new_leads(color, text, opportunities, page_number)
    $new_leads_nav_context += opportunities.map{|opp| opp.opportunityid }
    @color = color
    @label = text
    @page = opportunities
    render :action => :opportunity_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def todays_new_leads
    get_new_leads('red', 'Today', Opportunity.todays_new_leads(@params['page'].to_i), @params['page'])
  end
  
  def previous_days_new_leads
    get_new_leads('orange', 'Previous Days', Opportunity.previous_days_leads(@params['page'].to_i), @params['page'])
  end
  
  def get_follow_ups(color, text, date_proc, phone_calls)
    $follow_ups_nav_context += phone_calls.map{|phone_call| phone_call.opportunity.opportunityid }
    @color = color
    @label = text
    @date_proc = date_proc
    @page = phone_calls
    render :action => :follow_ups_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def get_activities(opportunities)
    $follow_ups_nav_context += opportunities.map{|opp| opp.opportunityid }
    @page = opportunities
    render :action => :last_activities_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end

  def by_last_activities
    opportunities = Opportunity.by_last_activities(@params['page'].to_i)
    get_activities(opportunities)
  end

  def todays_follow_ups
    date_proc = lambda {|phone_call| "Today #{phone_call.scheduledend.hour_string }" if phone_call.scheduledend }
    phone_calls = Activity.todays_follow_ups(@params['page'].to_i)
    get_follow_ups('orange', 'Today', date_proc, phone_calls)
  end

  def future_follow_ups
    date_proc = lambda {|phone_call| "Last Act: -#{DateUtil.days_ago(phone_call.opportunity.cssi_lastactivitydate)}d" unless phone_call.opportunity.cssi_lastactivitydate.blank?}
    phone_calls = Activity.future_follow_ups(@params['page'].to_i)
    get_follow_ups('green', 'Future', date_proc, phone_calls)
  end

  def past_due_follow_ups
    date_proc = lambda {|phone_call| "Due: #{DateUtil.days_from_now(phone_call.scheduledend)}d" }
    phone_calls = Activity.past_due_follow_ups(@params['page'].to_i)
    get_follow_ups('red', 'Past Due', date_proc, phone_calls)
  end

  def get_appointments(color, text, appointments)
    $appointments_nav_context += appointments.map{|appointment| appointment.opportunity.opportunityid }
    @color = color
    @label = text
    @page = appointments
    render :action => :appointments_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def future_appointments
    get_appointments('green', 'Future', Activity.future_appointments(@params['page'].to_i))
  end

  def todays_appointments
    get_appointments('orange', 'Today', Activity.todays_appointments(@params['page'].to_i))
  end

  def past_due_appointments
    get_appointments('red', 'Past Due', Activity.past_due_appointments(@params['page'].to_i))
  end
  
  def check_preferred_and_donotcall(phone_type, contact)
    preferred = contact.preferred_number
    allow_call = 'True'
    company_dnc = 'False'
    
    if preferred == contact.telephone2 # Home
      allow_call = contact.cssi_allowcallshomephone
      company_dnc = contact.cssi_companydnchomephone
    elsif preferred == contact.mobilephone # Mobile
      allow_call = contact.cssi_allowcallsmobilephone
      company_dnc = contact.cssi_companydncmobilephone
    elsif preferred == contact.telephone1 # Business
      allow_call = contact.cssi_allowcallsbusinessphone
      company_dnc = contact.cssi_companydncbusinessphone
    elsif preferred == contact.telephone3 # Alternate
      allow_call = contact.cssi_allowcallsalternatephone
      company_dnc = contact.cssi_companydncalternatephone
    end
    
    is_preferred = phone_type == preferred

    # Special case where we need 2 icons side by side, and some jQuery/JavaScript tricks are needed
    # We look for the two-icons attribute in the .erb and substitute a formatted HTML string that will show both
    if is_preferred && (allow_call == 'False' || company_dnc == 'True')
      return %Q{ <span two-icons class="ui-icon ui-icon-check ui-icon-shadow"></span> }
    end
    
    if phone_type == preferred
      %Q{ <span class="ui-icon ui-icon-check ui-icon-shadow"></span> }
    elsif (allow_call == 'False' || company_dnc == 'True')
      %Q{ <span class="ui-icon ui-icon-delete ui-icon-shadow"></span> }
    else
      ""
    end    
  end
  
  # GET /Opportunity/{1}
  def show
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      @notes = @opportunity.notes
      current_nav_context.orient!(@opportunity.object)
      @contact = @opportunity.contact
      render :action => :show, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
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
    
    @opportunity = Opportunity.find(opp_id)
    
    if @opportunity
      @notes = @opportunity.notes
      current_nav_context.orient!(@opportunity.object)
      @contact = @opportunity.contact
      render :action => :show, :back => 'callback:', :layout => 'layout_jquerymobile', :origin => @params['origin']
    end
  end
  
  def status_update
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :status_update, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end 
  
  def note_create
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :note_create, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end  

  def contact_opp_new    
     redirect :action => :new,
              :controller => "Contact",
              :query =>{:origin => @params['origin']}
  end
  
  def callback_request
    $choosed['0'] = ""
    @opportunity = Opportunity.find(@params['id'])
    @opportunity.create_note(@params['notes'])
    if @opportunity
      render :action => :callback_request, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def app_detail_add
      @opportunity = Opportunity.find(@params['id'])
      if @opportunity
        render :action => :application_details_add, :back => 'callback:', :layout => 'layout_jquerymobile'
      else
        redirect :action => :index, :back => 'callback:'
      end
    end
    
  def app_detail_show
      # @appdetail = Opportunity.find(@params['id'])
      # if @appdetail
        render :action => :application_details_show, :back => 'callback:', :layout => 'layout_jquerymobile'
      # else
      #   redirect :action => :index, :back => 'callback:'
      # end
    end
    
  def app_detail_edit
    @appdetail = Opportunity.find(@params['id'])
    if @appdetail
      render :action => :application_details_edit, :back => 'callback:', :layout => 'layout_jquerymobile'
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
    @opportunity.create_note(@params['notes'])
    
    if @opportunity
      render :action => :appointment, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def lost_other
    @lost_reasons = Constants::OTHER_LOST_REASONS
    @competitors = Constants::COMPETITORS
    
    @opportunity = Opportunity.find(@params['id'])
    @opportunity.create_note(@params['notes'])
    
    if @opportunity
      render :action => :lost_other, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def won
      @opportunity = Opportunity.find(@params['id'])
      if @opportunity
        render :action => :mark_as_won, :back => 'callback:', :layout => 'layout_jquerymobile'
      else
        redirect :action => :index, :back => 'callback:'
      end
    end
  
  
  def contact_opp_new    
    redirect :action => :new,
             :controller => "Contact",
             :query =>{:origin => @params['origin']}
  end
  
  
  # GET /Opportunity/{1}/activity_summary
  def activity_summary
    @opportunity = Opportunity.find(@params['id'])
    @activities = @opportunity.activities
    @activity_list = @opportunity.activity_list
    if @opportunity
      render :action => :activity_summary, :back => 'callback:',
              :layout => 'layout_jquerymobile',
              :origin => @params['origin']
    end
  end

  def phone_dialog
    @opportunity = Opportunity.find(@params['id'])
    render :action => :phone_dialog, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def save
    $saved = 1
    redirect :action => :index, :back => 'callback:'
  end
  
  def call_number
    puts "Calling number " + @params['phone_number']
    telephone = @params['phone_number']
    telephone.gsub!(/[^0-9]/, "")
    redirect :action => :phone_dialog, :back => 'callback:',
              :id => @params['opportunity'],
              :query =>{:origin => @params['origin']}
    System.open_url('tel:' + telephone)
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
          preset_time = Time.new
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
      render :back => 'callback:'
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
end
