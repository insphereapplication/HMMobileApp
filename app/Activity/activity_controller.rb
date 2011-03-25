require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'

class ActivityController < Rho::RhoController
  include BrowserHelper
  
  def update_won_status
    opportunity = Opportunity.find(@params['opportunity_id'])
    opportunity.complete_open_call
    opportunity.update_attributes({
      :statecode => 'Won', 
      :actual_end => Time.now.to_s
    })
    finished_update_status(opportunity, @params['origin'])
  end

  def udpate_lost_status
    opportunity = Opportunity.find(@params['opportunity_id'])
    opportunity.complete_open_call
    opportunity.update_attributes({
      :statecode => 'Lost',
      :statuscode => @params['status_code'],
      :cssi_statusdetail => "",
      :competitorid => @params['competitorid'] || ""
    })
    finished_update_status(opportunity, @params['origin'], @params['appointments'])
  end
  
  def update_status_no_contact

    opportunity = Opportunity.find(@params['opportunity_id'])
    
    opp_attrs = {
      :cssi_statusdetail => @params['status_detail'],
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }
    
    if opportunity.is_new?
      opp_attrs.merge!({:statuscode => 'No Contact Made'})
    end
    
    opportunity.update_attributes(opp_attrs)
    opportunity.record_phone_call_made_now
    finished_update_status(opportunity, @params['origin'], @params['appointments'])
  end
  
  def update_status_call_back_requested
    puts "CALLBACK REQUESTED:"
    puts @params.inspect
    opportunity = Opportunity.find(@params['opportunity_id'])
    opp_attrs = {
      :cssi_statusdetail => 'Call Back Requested',
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }
    
    if opportunity.is_new? || opportunity.statuscode == 'No Contact Made'
      opp_attrs.merge!({:statuscode => 'Contact Made'})
    end
    
    opportunity.update_attributes(opp_attrs)
    opportunity.record_phone_call_made_now
    opportunity.create_note(@params['notetext'])
    
    # create the requested callback
    phone_call = PhoneCall.create({
      :scheduledend => DateUtil.date_build(@params['callback_datetime']), 
      :subject => "Phone Call - #{opportunity.contact.full_name}",
      :phonenumber => @params['phone_number'],
      :parent_type => 'Opportunity', 
      :parent_id => opportunity.object,
      :statuscode => 'Open',
      :statecode => 'Open',
      :notetext => @params['note']
    })
    
    finished_update_status(opportunity, @params['origin'], @params['appointments'])
  end
  
  def update_status_appointment_set
    opportunity = Opportunity.find(@params['opportunity_id'])
    contact = opportunity.contact
    
    opp_attrs = {
      :cssi_statusdetail => 'Appointment Set',
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }
    
    if opportunity.is_new? || ['No Contact Made', 'Contact Made'].include?(opportunity.statuscode)
      opp_attrs.merge!({:statuscode => 'Appointment Set'})
    end
    
    opportunity.complete_most_recent_open_call 
    opportunity.update_attributes(opp_attrs)
    opportunity.create_note(@params['notetext'])
    
    # create the requested appointment
    Appointment.create({
        :parent_type => 'opportunity',
        :parent_id => opportunity.object,
        :statecode => "Scheduled",
        :statuscode => "Busy",
        :scheduledstart => DateUtil.date_build(@params['appointment_datetime']),
        :scheduledend => DateUtil.end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
        :location => @params['location'],
        :subject => "#{contact.firstname}, #{contact.lastname} - #{opportunity.createdon}",
        :notetext => @params['notetext']
      }
    )
  
    finished_update_status(opportunity, @params['origin'], @params['appointments'])
  end
  
  private
  
  def finished_update_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object, :query => {:origin => origin}
  end
  
  def complete_appointments(appointmentids)
    if appointmentids
      appointmentids.each do |id|
        appointment = Appointment.find(id)
        appointment.complete if appointment
      end
    end
  end

end
