require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'

class ActivityController < Rho::RhoController
  include BrowserHelper

  def index
    render :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end

  def get_new_activities(color, activities)
    @color = color
    @page = activities
    render :action => :activity_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def past_due_activities
    data = []
    data = ["a", "b", "c"] if (@params['page'] == '0')
    data = ["d", "e"] if (@params['page'] == '1')
    get_new_activities('red', data)
  end
  
  def completed_activities
    data = []
    data = ["a", "b", "c"] if (@params['page'] == '0')
    data = ["d", "e"] if (@params['page'] == '1')
    get_new_activities('grey', data)
  end

  # GET /Appt/{1}
  def show_appt
    @appt = Activity.find_activity(@params['id'])
    if @appt
      Settings.record_activity
      render :action => :show_appt, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      redirect :Controller => :Opportunity, :action => :index, :back => 'callback:'
    end
  end
  
  # EDIT /Appt/{1}
  def edit_appt
    @appt = Activity.find_activity(@params['id'])
    if @appt
      Settings.record_activity
      render :action => :edit_appt, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      redirect :Controller => :Opportunity, :action => :index, :back => 'callback:'
    end
  end
  
  # GET /callback/{1}
  def show_callback
    @callback = Activity.find_activity(@params['id'])

    if @callback
      @notes = @callback.notes
      Settings.record_activity
      render :action => :show_callback, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      redirect :Controller => :Opportunity, :action => :index, :back => 'callback:'
    end
  end
  
  # EDIT /callback/{1}
  def edit_callback
    @callback = Activity.find_activity(@params['id'])
    if @callback
      Settings.record_activity
      render :action => :edit_callback, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      redirect :Controller => :Opportunity, :action => :index, :back => 'callback:'
    end
  end
  
  def get_duration(time1, time2)
    duration = (Time.parse(time2) - Time.parse(time1))/60
  end
  
  #CR: remove puts statements before committing
  #CR: use inline 'if's carefully. Here there should be an if clause and an 'else' to handle negative paths. What happens if we don't have an appointment?
  #CR: Wrap all database operations in transactions -- Note here that if the first update fails, the second update is now inaccurate.
  def update_appt
    puts "APPOINTMENT UPDATE: #{@params.inspect}"
    Settings.record_activity
    @appointment = Activity.find_activity(@params['id'])
    @appointment.update_attributes({
      :scheduledstart => DateUtil.date_build(@params['appointment_datetime']),
      :scheduledend => DateUtil.end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
      :location => @params['location'],
      :description => @params['description'],
      :cssi_location => @params['cssi_location']  
    }) if @appointment
    
    @appointment.opportunity.update_attributes({
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }) if @appointment
    
    SyncEngine.dosync
    redirect :action => :show_appt, :back => 'callback:',
              :id => @appointment.object,
              :query =>{:opportunity => @params['opportunity'], :origin => @params['origin']}
  end
  
  #CR: careful with the inline 'if's; remove crufty old output; needs a transaction
  def update_callback
    puts "CALLBACK UPDATE: #{@params.inspect}"
    @callback = Activity.find_activity(@params['id'])
    Settings.record_activity
    if @callback
      @callback.update_attributes({
          :scheduledend => DateUtil.date_build(@params['callback_datetime']),
          :phonenumber => @params['phone_number'] 
      })
      @callback.opportunity.update_attributes({
        :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      })
      
      if @params['phoneList'] == 'ad-hoc'
        @callback.update_attributes({:cssi_phonetype => "Ad Hoc"})
      end      
    end
    SyncEngine.dosync
    redirect :action => :show_callback, :back => 'callback:',
              :id => @callback.object,
              :query =>{:opportunity => @params['opportunity'], :origin => @params['origin']}
  end
  
  def update_won_status
      Settings.record_activity
      db = ::Rho::RHO.get_src_db('Opportunity')
      db.start_transaction
      begin
        opportunity = Opportunity.find(@params['opportunity_id'])
        opportunity.create_note(@params['notes'])
        opportunity.complete_most_recent_open_call
        opportunity.update_attributes({
          :statecode => 'Won', 
          :statuscode => 'Sale',
          :cssi_statusdetail => "",
          :actual_end => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
          :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
          :status_update_timestamp => Time.now.utc.to_s
        })

        finished_win_status(opportunity, @params['origin'])

        db.commit
      rescue Exception => e
        puts "Exception in update won status, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
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
				                                :notes => @params['notes'],
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
                                :notes => @params['notes'],
                                :appointments => @params['appointments']})
                                )
    end
  end

  def udpate_lost_status
    if @params['button_id'] == "Ok"
      Settings.record_activity
      db = ::Rho::RHO.get_src_db('Opportunity')
      db.start_transaction
      begin
        opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
        opportunity.create_note(@params['notes'])
        opportunity.complete_most_recent_open_call
        opportunity.update_attributes({
          :statecode => 'Lost',
          :statuscode => @params['status_code'],
          :cssi_statusdetail => "",
          :competitorid => @params['competitorid'] || "",
          :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
          :status_update_timestamp => Time.now.utc.to_s
        })
      
        opportunity.record_phone_call_made_now
        appointmentids = get_appointment_ids(@params['appointments'])
        
        finished_loss_status(opportunity, @params['origin'], appointmentids)
        db.commit
      rescue Exception => e
        puts "Exception in update lost status, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
      end
    else
      WebView.navigate(url_for :controller => :Opportunity, :action => :status_update, :id => @params['opportunity_id'], :query => {:origin => @params['origin']})
    end
  end
  
  def confirm_lost_other_status
    unless @params['status_code'].blank?
      puts "STATUS CODE IS #{@params['status_code']}"
      WebView.navigate(url_for :action => :update_lost_other_status, 
              :query => {:opportunity_id => @params['opportunity_id'], 
                          :status_code => @params['status_code'],
                          :competitorid => @params['competitorid'] || "",
                          :origin => @params['origin'],
                          :appointments => @params['appointments']
                        })
    else
      puts "VALIDATION FAILED -- PLEASE CHOOSE A LOST REASON"
      Alert.show_popup "Please choose a lost reason."
    end
  end
  
  
  def update_lost_other_status
        Settings.record_activity
        db = ::Rho::RHO.get_src_db('Opportunity')
        db.start_transaction
        begin
          opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
          opportunity.complete_most_recent_open_call
          opportunity.update_attributes({
            :statecode => 'Lost',
            :statuscode => @params['status_code'],
            :cssi_statusdetail => "",
            :competitorid => @params['competitorid'] || "",
            :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
            :status_update_timestamp => Time.now.utc.to_s
          })
      
          opportunity.record_phone_call_made_now
      
          finished_loss_status(opportunity, @params['origin'], @params['appointments'])
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
				                                :notes => @params['notes'],
				                                :status_code => @params['status_code']
				                                })
				                   })
  end  
  
  def update_status_no_contact
    puts @params.inspect
    Settings.record_activity
    opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
    opportunity.create_note(@params['notes'])
    
    opp_attrs = {
      :cssi_statusdetail => @params['status_detail'],
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
      :status_update_timestamp => Time.now.utc.to_s
    }
    
    if opportunity.statuscode == 'New Opportunity'
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
  
  def mark_appointment_complete
    complete_appointments([@params['appointments']])
    SyncUtil.start_sync
    redirect :controller => :Opportunity, :action => :show, :back => 'callback:', :id => @params['opportunity_id'], :query => {:origin => @params['origin']}
  end
    
  def update_status_call_back_requested
      opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
      Settings.record_activity
      opp_attrs = {
        :cssi_statusdetail => 'Call Back Requested',
        :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :statuscode => 'Contact Made',
        :status_update_timestamp => Time.now.utc.to_s
      }
    
      db = ::Rho::RHO.get_src_db('Opportunity')
      db.start_transaction
      begin
      opportunity.update_attributes(opp_attrs)
      opportunity.record_phone_call_made_now('Call Back Requested')
    
      # create the requested callback
      phone_call = Activity.create_new({
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
      
      if @params['phoneList'] == 'ad-hoc'
        phone_call.update_attributes({:cssi_phonetype => "Ad Hoc"})
      end
        
      finished_update_status(opportunity, @params['origin'], @params['appointments'])
      db.commit
    rescue Exception => e
      puts "Exception in update status call back requested, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end
  end
  
  def update_status_appointment_set
    unless @params['appointment_datetime'].blank?
      opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
      Settings.record_activity
      contact = opportunity.contact
    
      opp_attrs = {
        :cssi_statusdetail => 'Appointment Set',
        :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :status_update_timestamp => Time.now.utc.to_s
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
        Activity.create_new({
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
    else
        Alert.show_popup "Please choose an appointment date and time."
        WebView.refresh
      end
  end
  
  private
  
  def get_appointment_ids(appointment_params)
    ids = appointment_params.gsub(/[\[\]"\s]/, '')
    ids.split(",") if ids
  end
  
  def finished_update_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncUtil.start_sync
    redirect :controller => :Opportunity, :action => :show, :back => 'callback:', :id => opportunity.object, :query => {:origin => origin}
  end
  
  def finished_win_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncUtil.start_sync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object, :back => 'callback:', :query => {:origin => origin}
  end

  def finished_loss_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncUtil.start_sync
    puts @params.inspect
    model = ['SearchContacts', 'contact'].include?(@params['origin']) ? :Contact : :Opportunity
    WebView.navigate(url_for(:controller => model, :action => :index, :back => 'callback:', :query => {:origin => origin})) 
  end
  
  def complete_appointments(appointmentids)
    Settings.record_activity
    if appointmentids
      appointmentids.each do |id|
        appointment = Activity.find(id, :conditions => {:type => 'Appointment'})
        appointment.complete if appointment
      end
    end
  end

end
