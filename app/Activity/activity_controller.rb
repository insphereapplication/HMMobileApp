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
      :competitorid => @params['competitorid'] || ""
    })
    finished_update_status(opportunity, @params['origin'])
  end
  
  def update_status_no_contact
    opportunity = Opportunity.find(@params['opportunity_id'])
    opp_attrs = {:cssi_statusdetail => @params['status_detail']}
    if opportunity.is_new?
      opportunity.merge!({:statuscode => 'No Contact Made'})
    end
    opportunity.update_attributes(opp_attrs)
    opportunity.record_phone_call_made
    finished_update_status(opportunity, @params['origin'])
  end
  
  def update_status_call_back_requested
    opportunity = Opportunity.find(@params['opportunity_id'])
    opp_attrs = {:cssi_statusdetail => 'Call Back Requested'}
    
    if opportunity.is_new? || opportunity.statuscode == 'No Contact Made'
      opp_attrs.merge!({:statuscode => 'Contact Made'})
    end
    
    opportunity.update_attributes(opp_attrs)
    opportunity.record_phone_call_made
    
    # create the requeseted callback
    PhoneCall.create({
      :scheduledstart => DateUtil.date_build(@params['callback_datetime']), 
      :subject => "Phone Call - #{opportunity.contact.full_name}",
      :phone_number => @params['phone_number'],
      :parent_type => 'Opportunity', 
      :parent_id => opportunity.object
    })
    finished_update_status(opportunity, @params['origin'])
  end
  
  def update_status_appointment_set
    opp = Opportunity.find(@params['opportunity_id'])
    contact = opp.contact
    
    opp_attrs = {:cssi_statusdetail => 'Appointment Set'}
    if opp.is_new? || ['No Contact Made', 'Contact Made'].include?(opp.statuscode)
      opp_attrs.merge!({:statuscode => 'Appointment Set'})
    end
    
    opp.complete_open_call 
    opp.update_attributes(opp_attrs)
    
    # create the requested appointment
    Appointment.create({
        :parent_type => 'opportunity',
        :parent_id => opp.object,
        :statecode => "Scheduled",
        :statuscode => "Busy",
        :scheduledstart => DateUtil.date_build(@params['appointment_datetime']),
        :scheduledend => DateUtil.end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
        :location => @params['location'],
        :subject => "#{contact.firstname}, #{contact.lastname} - #{opp.createdon}"
      }
    )
    finished_update_status(opp, @params['origin'])
  end
  
  private
  
  def finished_update_status(opportunity, origin)
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object, :query => {:origin => origin}
  end

end
