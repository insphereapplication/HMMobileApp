require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/application_helper'
require 'date'
require 'time'

class OpportunityController < Rho::RhoController
  include BrowserHelper
  $saved = nil
  $choosed = {}

  def init_notify
    WebView.navigate ( url_for :controller => :Opportunity, :action => :index )
  end
  
  #GET /Opportunity
  def index
    if SyncEngine::logged_in == 1
      @todays_new_leads = Opportunity.todays_new_leads
      @previous_days_leads = Opportunity.previous_days_leads
      Opportunity.clear_cache
      render :action => :index, :layout => 'layout_JQM_Lite'
    else
      redirect :controller => Settings, :action => :login, :layout => 'layout_JQM_Lite'
    end
  end
  
  def index_follow_up
    @todays_follow_ups = Opportunity.todays_follow_ups
    @past_due_follow_ups = Opportunity.past_due_follow_ups
    @future_follow_ups = Opportunity.future_follow_ups
    @last_activities = Opportunity.last_activities
    
    Opportunity.clear_cache
    render :action => :index_follow_up, :layout => 'layout_JQM_Lite'
  end
  
  def index_appointments
    @past_due_appointments = Appointment.past_due_appointments
    @todays_appointments = Appointment.todays_appointments
    @future_appointments = Appointment.future_appointments
    Appointment.clear_cache
    render :action => :index_appointments, :layout => 'layout_JQM_Lite'
  end
  
  def sync_object_notify
    WebView.refresh
  end
  
  # GET /Opportunity/{1}
  def show
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      @next_id = (@opportunity.object.to_i + 1).to_s
      @prev_id = (@opportunity.object.to_i - 1).to_s
      @contact = @opportunity.contact
      render :action => :show,
              :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end

  # GET /Opportunity/new
  def new
    @opportunity = Opportunity.new
    render :action => :new
  end

  # GET /Opportunity/{1}/edit
  def edit
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :edit
    else
      redirect :action => :index
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
    if @opportunity
      render :action => :activity_summary,
              :layout => 'layout_jquerymobile'
    end
  end

  # POST /Opportunity/create
  def create
    @opportunity = Opportunity.create(@params['opportunity'])
    redirect :action => :index
  end

  # POST /Opportunity/{1}/update
  def update
    @opportunity = Opportunity.find(@params['id'])
    @opportunity.update_attributes(@params['opportunity']) if @opportunity
    Opportunity.sync
    redirect :action => :index
  end

  # POST /Opportunity/{1}/delete
  def delete
    @opportunity = Opportunity.find(@params['id'])
    @opportunity.destroy if @opportunity
    redirect :action => :index
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
      puts "phone number is " + @params['phone_number']
      telephone.gsub!(/[^0-9]/, "")
      if @params['opportunity']
        redirect :action => :show,
                  :id => @params['opportunity'],
                  :query =>{:origin => @params['origin']}
      else
      redirect :action => :index
    end
      System.open_url('tel:' + telephone)
    end

    def popup
      flag = @params['flag']
      if ['0', '1', '2'].include?(flag)
        ttt = $choosed[flag]
        if ttt.nil?
          preset_time = Time.new
        else
          preset_time = Time.strptime(ttt, '%m/%d/%Y %I:%M %p')
        end

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
end
