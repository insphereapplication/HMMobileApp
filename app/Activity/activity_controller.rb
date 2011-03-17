require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'

class ActivityController < Rho::RhoController
  include BrowserHelper
  
  def update_status
    phone_call_attrs = @params['phone_call']
    opportunity = Opportunity.find(@params['opportunity_id'])
    
    #If this is a callback requested status, convert the call start date, time and duration to correct format
    if @params['callback_datetime']
      callback_formatted = date_build(@params['callback_datetime'])
      phone_call_attrs.merge!({:cssi_followupcall => (callback_formatted)})
      puts "~~~ CALL BACK TIME IS ~~~: #{callback_formatted}"
    end
    
    parent_attrs = { 
      :parent_type => 'opportunity', 
      :parent_id => opportunity.opportunityid 
    }
    
    if !opportunity.open_phone_calls.blank?
      phone_call = opportunity.most_recent_open_phone_call
      phone_call.update_attributes(phone_call_attrs.merge(parent_attrs))
    elsif @params['appointment'].blank?
      phone_call = PhoneCall.create(
        parent_attrs.merge(phone_call_attrs).merge(parent_attrs)
      )
    end
    
    if @params['appointment'] 
      Appointment.create(@params['appointment'].merge(parent_attrs).merge({
          :statecode => "Scheduled",
          :statuscode => "Busy",
          :scheduledstart => date_build(@params['appointment_datetime']),
          :scheduledend => end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
          :subject => "#{@params['firstname']}, #{@params['lastname']} - #{@params['createdon']}"
        }))
    end
    
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object
  end

  def date_build(date_string)
    date = (DateTime.strptime(date_string, '%m/%d/%Y %I:%M %p'))
    result = date.strftime('%Y/%m/%d %H:%M')
    result
  end
  
  def end_date_time(date_string, duration)
    date = (DateTime.strptime(date_string, '%m/%d/%Y %I:%M %p'))
    end_date = date + ((duration.to_f)/60/24)
    end_date.strftime('%m/%d/%Y %H:%M')
  end
  
  
  #GET /Activity
  def index
    @activities = Activity.find(:all)
    render
  end

  # GET /Activity/{1}
  def show
    @activity = Activity.find(@params['id'])
    if @activity
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Activity/new
  def new
    @activity = Activity.new
    render :action => :new
  end

  # GET /Activity/{1}/edit
  def edit
    @activity = Activity.find(@params['id'])
    if @activity
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Activity/create
  def create
    @activity = Activity.create(@params['activity'])
    redirect :action => :index
  end

  # POST /Activity/{1}/update
  def update
    @activity = Activity.find(@params['id'])
    @activity.update_attributes(@params['activity']) if @activity
    redirect :action => :index
  end

  # POST /Activity/{1}/delete
  def delete
    @activity = Activity.find(@params['id'])
    @activity.destroy if @activity
    redirect :action => :index
  end
end
