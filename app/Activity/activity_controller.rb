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

  def finished_update_status(opportunity, origin)
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object, :query => {:origin => origin}
  end

  def udpate_lost_status
    opportunity = Opportunity.find(@params['opportunity_id'])
    opportunity.complete_open_call
    opportunity.update_attributes({
      :statecode => 'Lost',
      :statuscode => @params['status_code'],
      :cssi_statusdetail => 'Lost',
      :competitorid => @params['competitorid'] || ""
    })
    finished_update_status(opportunity, @params['origin'])
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
    finished_update_status(opportunity, @params['origin'])
  end
  
  def update_status_call_back_requested
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
    
    create_note(@params['notetext'], opportunity)
    
    finished_update_status(opportunity, @params['origin'])
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
    
    create_note(@params['notetext'], opportunity)
    
    finished_update_status(opportunity, @params['origin'])
  end
  
  private
  
  def create_note(note_text, opportunity)
    unless note_text.blank?
      Note.create({
        :notetext => @params['notetext'], 
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :parent_id => opportunity.object,
        :parent_type => 'opportunity' 
      })
    end
  end
  
  def finished_update_status(opportunity, origin)
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object, :query => {:origin => origin}
  end

end
