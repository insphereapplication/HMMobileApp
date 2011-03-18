require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'

class ActivityController < Rho::RhoController
  include BrowserHelper
  
  def record_phone_call_made(opportunity)
    phone_call = opportunity.most_recent_open_or_create_new_phone_call
    phone_call.update_attributes({
      :scheduledend => Time.now.to_s, 
      :subject => "Phone Call - #{opportunity.contact.full_name}",
      :statecode => 'Completed', 
      :parent_type => 'Opportunity', 
      :parent_id => opportunity.object
    })
  end
  
  def finished_update_status(opportunity, origin)
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object, :query => {:origin => origin}
  end
  
  def update_status_no_contact
    opp = Opportunity.find(@params['opportunity_id'])
    opp_attrs = {:cssi_statusdetail => @params['status_detail']}
    if opp.is_new?
      opp_attrs.merge!({:statuscode => 'No Contact Made'})
    end
    opp.update_attributes(opp_attrs)
    record_phone_call_made(opp) 
    finished_update_status(opp, @params['origin'])
  end
  
  def update_status_call_back_requested
    opportunity = Opportunity.find(@params['opportunity_id'])
    opp_attrs = {:cssi_statusdetail => 'Call Back Requested'}
    
    if opportunity.is_new? || opportunity.statuscode == 'No Contact Made'
      opp_attrs.merge!({:statuscode => 'Contact Made'})
    end
    
    opportunity.update_attributes(opp_attrs)
    
    record_phone_call_made(opportunity) 
    
    PhoneCall.create({
      :scheduledstart => date_build(@params['callback_datetime']), 
      :subject => "Phone Call - #{opportunity.contact.full_name}",
      :phone_number => @params['phone_number'],
      :parent_type => 'Opportunity', 
      :parent_id => opportunity.object
    })
    finished_update_status(opportunity)
  end
  
  def update_status_appointment_set
    opp = Opportunity.find(@params['opportunity_id'])
    contact = opp.contact
    
    opp_attrs = {:cssi_statusdetail => 'Appointment Set'}
    if opp.is_new? || ['No Contact Made', 'Contact Made'].include?(opp.statuscode)
      opp.statuscode = 'Appointment Set'
    end
    
    if opp.most_recent_open_phone_call
      record_phone_call_made(opp)
    end
    
    opp.update_attributes(opp_attrs)
    
    Appointment.create({
        :parent_type => 'opportunity',
        :parent_id => opp.object,
        :statecode => "Scheduled",
        :statuscode => "Busy",
        :scheduledstart => date_build(@params['appointment_datetime']),
        :scheduledend => end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
        :location => @params['location'],
        :subject => "#{contact.firstname}, #{contact.lastname} - #{opp.createdon}"
      }
    )
      
    finished_update_status(opp)
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
