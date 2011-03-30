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
     Rho::NativeTabbar.switch_tab(0)
     WebView.navigate( 
        url_for(
          :controller => 'Opportunity',
          :action => :index
        )
      )
  end
  
  # this callback is set once in the login_callback method of the Settings controller
  def init_notify
    System.set_push_notification("/app/Settings/push_notify", '')
    
    SyncEngine.set_notification(
      -1, "/app/Settings/sync_notify", 
      "sync_complete=true"
    )
    
    tabbar = [
      { :label => "Opps", :action => '/app/Opportunity', 
        :icon => "/public/images/iphone/tabs/pib_tab_icon.png", :web_bkg_color => 0x7F7F7F }, 
      { :label => "Contacts",  :action => '/app/Contact',  
        :icon => "/public/images/iphone/tabs/activities_tab_icon.png" },
      { :label => "Settings",  :action => '/app/Settings',  
        :icon => "/public/images/iphone/tabs/settings_tab_icon.png", :reload => true },
    ]
    Rho::NativeTabbar.create(tabbar)
    Rho::NativeTabbar.switch_tab(0)
    
    $opportunity_nav_context = []
    
    SyncEngine.set_pollinterval(15)
    
  end
  
  # since this is the default entry point on startup, check here for login
  def index
    if SyncEngine::logged_in == 1
      @todays_new_leads = Opportunity.todays_new_leads
      @previous_days_leads = Opportunity.previous_days_leads
      $opportunity_nav_context = [@todays_new_leads,@previous_days_leads].flatten.map{|opportunity| opportunity.object }
      render :action => :index, :layout => 'layout_JQM_Lite'
    else
      redirect :controller => Settings, :action => :login, :layout => 'layout_JQM_Lite'
    end
  end
  
  def index_follow_up
    @todays_follow_ups = Opportunity.todays_follow_ups
    @past_due_follow_ups = Opportunity.past_due_follow_ups
    @future_follow_ups = Opportunity.future_follow_ups
    @last_activities = Opportunity.with_unscheduled_activities
    
    $opportunity_nav_context = [
      @todays_follow_ups, 
      @past_due_follow_ups, 
      @future_follow_ups
    ].flatten.map{|phone_call| phone_call.opportunity.object }
    
    $opportunity_nav_context.concat(@last_activities.map{|opp| opp.object})
    
    render :action => :index_follow_up, :layout => 'layout_JQM_Lite'
  end
  
  def check_preferred(phone_type, preferred)
    if phone_type == preferred
      %Q{ <span class="ui-icon ui-icon-check ui-icon-shadow"></span> }
    else
      ""
    end
  end
  
  def index_appointments
    @past_due_appointments = Activity.past_due_appointments
    @todays_appointments = Activity.todays_appointments
    @future_appointments = Activity.future_appointments
    
    $opportunity_nav_context = [
      @past_due_appointments,
      @todays_appointments,
      @future_appointments].flatten.map{|appointment| appointment.opportunity.object }
    
    render :action => :index_appointments, :layout => 'layout_JQM_Lite'
  end
  
  # GET /Opportunity/{1}
  def show
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      @notes = @opportunity.notes
      $opportunity_nav_context.orient!(@opportunity.object)
      @contact = @opportunity.contact
      render :action => :show, :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end
  
  def show_previous
    show_opportunity_from_nav('previous!')
  end
  
  def show_next
    show_opportunity_from_nav('next!')
  end
  
  def show_opportunity_from_nav(direction)
    if $opportunity_nav_context.blank?
      opp_id = @params['id']
    else
      opp_id = $opportunity_nav_context.send(direction)
    end
    
    @opportunity = Opportunity.find(opp_id)
    if @opportunity
      @notes = @opportunity.notes
      $opportunity_nav_context.orient!(@opportunity.object)
      @contact = @opportunity.contact
      render :action => :show, :layout => 'layout_jquerymobile', :origin => @params['origin']
    end
  end
  
  def status_update
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :status_update,
              :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end 
  
  def callback_request
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :callback_request,
              :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end
  
  def appointment
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :appointment,
              :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end
  
  def lost_other
    @lost_reasons = Constants::OTHER_LOST_REASONS
    @competitors = Constants::COMPETITORS
    
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :lost_other,
              :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end
  
  # GET /Opportunity/{1}/activity_summary
  def activity_summary
    @opportunity = Opportunity.find(@params['id'])
    @activities = @opportunity.activities
    puts @activities.inspect
    if @opportunity
      render :action => :activity_summary,
              :layout => 'layout_jquerymobile'
    end
  end

  def phone_dialog
    @opportunity = Opportunity.find(@params['id'])
    render :action => :phone_dialog,
            :layout => 'layout_JQM_Lite'
  end
  
  def save
    $saved = 1
    redirect :action => :index
  end
  
  def call_number
    puts "Calling number " + @params['phone_number']
    telephone = @params['phone_number']
    telephone.gsub!(/[^0-9]/, "")
    #redirect to opportunity detail page before launching call
  #   if @params['opportunity']
  #     redirect :action => :show,
  #               :id => @params['opportunity'],
  #               :query =>{:origin => @params['origin']}
  #   else
  #   redirect :action => :index
  # end
  redirect :action => :phone_dialog,
            :id => @params['opportunity'],
            :query =>{:origin => @params['origin']}
    System.open_url('tel:' + telephone)
  end

  def popup
    flag = @params['flag']
    if ['0', '1', '2'].include?(flag)
      ttt = $choosed[flag]
        preset_time = Time.new + 86400 + DateUtil.seconds_until_hour(Time.new)
      DateTimePicker.choose url_for(:action => :callback), @params['title'], preset_time, flag.to_i, Marshal.dump({:flag => flag, :field_key => @params['field_key']})
    end
  end

  def callback
    if @params['status'] == 'ok'
     $saved = nil
     datetime_vars = Marshal.load(@params['opaque'])
      format = case datetime_vars[:flag]
        when "0" then '%m/%d/%Y %I:%M %p'
        when "1" then '%F'
        when "2" then '%T'
        else '%F %T'
      end
      # formatted_result = Time.at(@params['result'].to_i).strftime('%m/%d/%Y %I:%M %p')
      formatted_result = Time.at(@params['result'].to_i).strftime(format)
      $choosed[datetime_vars[:flag]] = formatted_result
      WebView.execute_js('setFieldValue("'+datetime_vars[:field_key]+'","'+formatted_result+'");')
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
    WebView.refresh
      if System::get_property('platform') == 'APPLE'
        System.open_url("maps:q=#{@params['location'].gsub!(/ /,'+').strip!}")
      else
        System.open_url('http://maps.google.com/?q=' + @params['address'])
      end
  end
end
