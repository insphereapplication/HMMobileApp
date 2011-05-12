require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'

class ActivityController < Rho::RhoController
  include BrowserHelper
  
  def update_won_status
    if @params['button_id'] == "Ok"
      db = ::Rho::RHO.get_src_db('Opportunity')
      db.start_transaction
      begin
        opportunity = Opportunity.find(@params['opportunity_id'])
        opportunity.complete_most_recent_open_call
        opportunity.update_attributes({
          :statecode => 'Won', 
          :statuscode => 'Sale',
          :cssi_statusdetail => "",
          :actual_end => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
        })

        appointmentids = get_appointment_ids(@params['appointments'])
        finished_win_loss_status(opportunity, @params['origin'], appointmentids)

        db.commit
      rescue Exception => e
        puts "Exception in update won status, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
      end
    else
      WebView.navigate(url_for :controller => :Opportunity, :action => :status_update, :id => @params['opportunity_id'], :query => {:origin => @params['origin']})
    end
  end
  
  def confirm_win_status
    Alert.show_popup ({
        :message => "Click OK to Confirm this Opportunity as Won", 
        :title => "Confirm Win", 
        :buttons => ["Cancel", "Ok",],
        :callback => url_for(:action => :update_won_status, 
                                        :query => {
				                                :opportunity_id => @params['opportunity_id'],
				                                :origin => @params['origin'],
				                                :appointments => @params['appointments']
				                                })
				                   })
  end
  
  def dismiss_win_popup
    if @params['button_id'] == "Ok"
      WebView.navigate(url_for(:action => :update_won_status,
                                :query => {
                                :opportunity_id => @params['opportunity_id'],
                                :origin => @params['origin'],
                                :appointments => @params['appointments']})
                                )
    end
  end

  def udpate_lost_status
    if @params['button_id'] == "Ok"
        db = ::Rho::RHO.get_src_db('Opportunity')
        db.start_transaction
        begin
          opportunity = Opportunity.find(@params['opportunity_id'])
          opportunity.complete_most_recent_open_call
          opportunity.update_attributes({
            :statecode => 'Lost',
            :statuscode => @params['status_code'],
            :cssi_statusdetail => "",
            :competitorid => @params['competitorid'] || ""
          })
      
          opportunity.record_phone_call_made_now
          appointmentids = get_appointment_ids(@params['appointments'])
          
          finished_win_loss_status(opportunity, @params['origin'], appointmentids)
          db.commit
        rescue Exception => e
          puts "Exception in update lost status, rolling back: #{e.inspect} -- #{@params.inspect}"
          db.rollback
      end
    else
      WebView.navigate(url_for :controller => :Opportunity, :action => :status_update, :id => @params['opportunity_id'], :query => {:origin => @params['origin']})
    end
  end
  
  def update_lost_other_status
        db = ::Rho::RHO.get_src_db('Opportunity')
        db.start_transaction
        begin
          opportunity = Opportunity.find(@params['opportunity_id'])
          opportunity.complete_most_recent_open_call
          opportunity.update_attributes({
            :statecode => 'Lost',
            :statuscode => @params['status_code'],
            :cssi_statusdetail => "",
            :competitorid => @params['competitorid'] || ""
          })
      
          opportunity.record_phone_call_made_now
      
          finished_update_status(opportunity, @params['origin'], @params['appointments'])
          db.commit
        rescue Exception => e
          puts "Exception in update lost status, rolling back: #{e.inspect} -- #{@params.inspect}"
          db.rollback
      end
  end

  def confirm_lost_status
    Alert.show_popup ({
        :message => "Click OK to Confirm this Opportunity as Lost", 
        :title => "Confirm Loss", 
        :buttons => ["Cancel", "Ok",],
        :callback => url_for(:action => :udpate_lost_status, 
                                        :query => {
				                                :opportunity_id => @params['opportunity_id'],
				                                :origin => @params['origin'],
				                                :appointments => @params['appointments'],
				                                :status_code => @params['status_code']
				                                })
				                   })
  end  
  def update_status_no_contact
    puts @params.inspect
    opportunity = Opportunity.find(@params['opportunity_id'])
    
    opp_attrs = {
      :cssi_statusdetail => @params['status_detail'],
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }
    
    if opportunity[:statuscode] == 'New Opportunity'
      opp_attrs.merge!({:statuscode => 'No Contact Made'})
    end
    
    db = ::Rho::RHO.get_src_db('Opportunity')
    db.start_transaction
    begin
      opportunity.update_attributes(opp_attrs)
      opportunity.record_phone_call_made_now(@params['status_detail'])
      finished_update_status(opportunity, @params['origin'], @params['appointments'])
      db.commit
    rescue Exception => e
      puts "Exception in update status no contact, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end
  end
  
  def update_status_call_back_requested
    opportunity = Opportunity.find(@params['opportunity_id'])
    
    opp_attrs = {
      :cssi_statusdetail => 'Call Back Requested',
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
      :statuscode => 'Contact Made'
    }
    
    db = ::Rho::RHO.get_src_db('Opportunity')
    db.start_transaction
    begin
      opportunity.update_attributes(opp_attrs)
      opportunity.record_phone_call_made_now('Call Back Requested')
    
      # create the requested callback
      phone_call = Activity.create({
        :scheduledend => DateUtil.date_build(@params['callback_datetime']), 
        :subject => "Phone Call - #{opportunity.contact.full_name}",
        :phonenumber => @params['phone_number'],
        :parent_type => 'Opportunity', 
        :parent_id => opportunity.object,
        :parent_contact_id => opportunity.contact_id,
        :statuscode => 'Open',
        :statecode => 'Open',
        :type => 'PhoneCall'
      })
    
      phone_call.create_note(@params['notetext'])
    
      finished_update_status(opportunity, @params['origin'], @params['appointments'])
      db.commit
    rescue Exception => e
      puts "Exception in update status call back requested, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end
  end
  
  def update_status_appointment_set
    opportunity = Opportunity.find(@params['opportunity_id'])
    contact = opportunity.contact
    
    opp_attrs = {
      :cssi_statusdetail => 'Appointment Set',
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }
    
    if ['New Opportunity', 'No Contact Made', 'Contact Made'].include?(opportunity.statuscode)
      opp_attrs.merge!({:statuscode => 'Appointment Set'})
    end
    
    db = ::Rho::RHO.get_src_db('Opportunity')
    db.start_transaction
    begin
      opportunity.complete_most_recent_open_call('Appointment Set') 
      opportunity.update_attributes(opp_attrs)
    
      # create the requested appointment
      Activity.create({
          :parent_type => 'Opportunity',
          :parent_id => opportunity.object,
          :statecode => "Scheduled",
          :statuscode => "Busy",
          :scheduledstart => DateUtil.date_build(@params['appointment_datetime']),
          :scheduledend => DateUtil.end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
          :location => @params['location'],
          :subject => "#{contact.firstname}, #{contact.lastname} - #{opportunity.createdon}",
          :description => @params['description'],
          :type => 'Appointment',
          :cssi_location => @params['cssi_location'],
          :parent_contact_id => opportunity.contact_id
        }
      )
  
      finished_update_status(opportunity, @params['origin'], @params['appointments'])
      db.commit
    rescue Exception => e
      puts "Exception in update status appointment set, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end
  end
  
  private
  
  def get_appointment_ids(appointment_params)
    ids = appointment_params.gsub(/[\[\]"\s]/, '')
    ids.split(",") if ids
  end
  
  def finished_update_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncEngine.dosync
    redirect :controller => :Opportunity, :action => :show, :back => 'callback:', :id => opportunity.object, :query => {:origin => origin}
  end
  
  def finished_win_loss_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncEngine.dosync
    WebView.navigate(url_for :controller => :Opportunity, :action => :show, :id => opportunity.object, :query => {:origin => origin})
  end
  
  def complete_appointments(appointmentids)
    if appointmentids
      appointmentids.each do |id|
        appointment = Activity.find(id, :conditions => {:type => 'Appointment'})
        appointment.complete if appointment
      end
    end
  end

end
