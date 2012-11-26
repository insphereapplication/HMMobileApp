require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'

class ActivityController < Rho::RhoController
  include BrowserHelper

  @@first_render = true

  def index
    Settings.record_activity
    Activity.complete_activities(@params['selected-activity']) if @params['selected-activity']
    selected = Settings.filter_values["activity_type"]
    selected = 'All' if selected.blank?
    @type_filter = gen_jqm_options([
        {:value => 'All', :label => 'All'},
        {:value => 'Task', :label => 'Task'},
        {:value => 'Appointment', :label => 'Appointment'},
        {:value => 'PhoneCall', :label => 'Phone Call'}
    ], selected)
    selected = Settings.filter_values["activity_status"]
    selected = 'Today' if selected.blank?
    @status_filter = gen_jqm_options([
        {:value => 'Today', :label => 'Today'},
        {:value => 'Next7Days', :label => 'Next 7 Days'},
        {:value => 'NoDate', :label => 'No Date'}
    ], selected)
    selected = Settings.filter_values["activity_priority"]
    selected = 'All' if selected.blank?
    @priority_filter = gen_jqm_options([
        {:value => 'All', :label => 'All'},
        {:value => 'Normal', :label => 'Normal'},
        {:value => 'High', :label => 'High'}
    ], selected)
    @page_name = 'Activities'
    @isCollapsed = 'true'
    @firstBtnText = 'Create'
    @firstBtnIcon = 'plus'
    @firstBtnUrl = url_for :action => :new_task
    @firstBtnBack = false
    @firstBtnExternal = false
    @secondBtnText = 'Complete'
    @secondBtnIcon = 'check'
    @secondBtnUrl = 'javascript:completeSelectedActivities()'
    @secondBtnExternal = false
    @scriptName = 'activities'
    @pageSize = 30
    @url = '/app/Activity/get_jqm_activities_page'
    @filterBtnText = 'Filter'
    render :action => :filter, :back => 'callback:', :layout => 'layout_jqm_list'
  end
  def complete_activities_alert
    Alert.show_popup "Please choose activities to complete."
  end
  def gen_jqm_options(options, selected_value)
    options.map{|option|
      selected_text = (option[:value] == selected_value) ? ' selected="true"' : ''
      "<option value=\"#{option[:value]}\"#{selected_text}>#{option[:label]}</option>"
    }.join("\n")
  end
  def activity_row_parameters(activity)
    parent_contact = activity.parent_contact
    if (parent_contact)
      left_text = parent_contact.full_name.blank? ? "&nbsp;" : parent_contact.full_name
    else
      parent_policy = activity.policy
      left_text = parent_policy.nil? || parent_policy.cssi_primaryinsured.blank? ? "&nbsp;" : parent_policy.cssi_primaryinsured
    end
    scheduled_time = activity.scheduled_time
    right_text = scheduled_time.blank? ? "&nbsp;" : to_datetime_noyear(scheduled_time)
    is_priority = !activity.prioritycode.blank? && activity.prioritycode == 'High'
    details = url_for(:action => :show, :id => activity.object)
    href = nil
    is_phone = activity.type == 'PhoneCall'
    if (activity.open? && (activity.type=='Appointment' || activity.type=='PhoneCall'))
      opp = activity.opportunity
      details = url_for(:action => :opportunity_details, :id => opp.object) if opp && !opp.closed?
    end
    isApple = System::get_property('platform') == 'APPLE'
    if (is_phone)
      href = activity.phonenumber.blank? ? "#" : "tel:#{activity.phonenumber}"
    elsif (activity.type == 'Appointment')
      href = activity.location.blank? ? "#" :
              isApple ? "maps:q=#{Rho::RhoSupport.url_encode(activity.location)}" :
                      "http://maps.google.com/?rho_open_target=_blank&q=#{Rho::RhoSupport.url_encode(activity.location)}"
    end
    {
      :id => activity.object,
      :show_detail_url => details,
      :completed => activity.statecode == 'Completed',
      :show_icon => is_priority,
      :top_text => activity.subject.blank? ? "&nbsp;" : activity.subject,
      :bottom_left_text => left_text,
      :bottom_right_text => right_text,
      :href_text => href,
      :show_phone => is_phone,
      :check_top => isApple ? "25" : "15",
      :check_left => isApple ? "7" : "2",
      :check_width => "25"
    }
  end
  def get_jqm_activities_page
    Settings.record_activity
    Settings.update_persisted_filter_values('activity_', ['type', 'status', 'priority'], @params) if @params['status']
    @type = Settings.filter_values["activity_type"]
    @type = 'All' if @type.blank?
    @status = Settings.filter_values["activity_status"]
    @status = 'Open' if @status.blank?
    @priority = Settings.filter_values["activity_priority"]
    @priority = 'All' if @priority.blank?
    page = @params['page'].to_i
    page_size = @params['pageSize'].to_i
    if @params['reset'] == 'true'
      if @status == "Today" || @status == "Next7Days"
        prms = [
          { :divider => "Past Due" },
          [Activity, :past_due_activities],
          { :divider => "No Date" },
          [Activity, :no_date_activities],
          { :divider => "Today" },
          [Activity, :today_activities]
        ]
        prms.concat([
          { :divider => "Next 7 Days" },
          [Activity, :future_activities]
        ]) if @status == "Next7Days"
      else
        prms = [
          { :divider => "No Date" },
          [Activity, :no_date_activities]
        ]
      end
      @@data_loader = ApplicationHelper::HierarchyDataLoader.new(prms, 0, 3)
    end
    @grouped_items = @@data_loader.load_data([page, @type, @priority, page_size])
    render :partial => 'activity', :locals => { :items => @grouped_items }
  end

  def show_all_activities
    #puts "^^*^^ Activity.local_changed #{Activity.local_changed?}"
    #puts "^^*^^ Activity first render #{@@first_render}"
    if Activity.local_changed? || @@first_render
      Activity.local_changed = false
      @@first_render = false
      WebView.navigate(url_for(:controller => :Activity, :action => :index), Constants::TAB_INDEX['Activities'])
    end
  end
  
  def self.reset_first_render
    @@first_render = true
  end
  

  def show
    @activity = Activity.find_activity(@params['id'])
    if @activity
      @parent_contact = @activity.parent_contact
      @opportunity = @activity.opportunity
      @policy = @activity.policy
      @contact_info = ""
      if @parent_contact
        @contact_info = "#{@parent_contact.gendercode}" unless @parent_contact.gendercode.blank?
        if !@parent_contact.age.blank?
          @contact_info = @contact_info + " " unless @contact_info.blank?
          @contact_info = @contact_info + "#{@parent_contact.age}"
        end
        if !@parent_contact.address1_city.blank?
          @contact_info = @contact_info + " - " unless @contact_info.blank?
          @contact_info = @contact_info + "#{@parent_contact.address1_city}"
        end
        if !@parent_contact.cssi_state1id.blank?
          @contact_info = @contact_info + ", " unless @contact_info.blank?
          @contact_info = @contact_info + "#{@parent_contact.cssi_state1id}"
        end
      end
      render :action => :show, :back => 'callback:', :layout => 'layout_jquerymobile'
    else
      show_all_activities
    end
  end

  def get_new_activities(color, activities)
    @color = color
    @page = activities
    render :action => :activity_page, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end

  def past_due_activities
    get_new_activities('red', Activity.past_due_activities(@params['page'].to_i, @params['type'], @params['priority']))
  end

  def no_date_activities
    get_new_activities('green', Activity.no_date_activities(@params['page'].to_i, @params['type'], @params['priority']))
  end

  def today_activities
    get_new_activities('orange', Activity.today_activities(@params['page'].to_i, @params['type'], @params['priority']))
  end

  def future_activities
    get_new_activities('yellow', Activity.future_activities(@params['page'].to_i, @params['type'], @params['priority']))
  end

  def opportunity_details
    Rho::NativeTabbar.switch_tab(0)
    redirect :action => :index
    WebView.navigate(url_for(:controller => :Opportunity, :action => :show, :id => @params['id']), 0)
 
  end

  # GET /Contact/activity_summary
  def contact_activity_summary
    Settings.record_activity
    @contact = Contact.find_contact(@params['id'])      
    if @contact
      @activity_list = @contact.activity_list
      render :action => :activity_summary, :id => @contact.object, :back => 'callback:',
             :layout => 'layout_jquerymobile',
             :origin => @params['origin'],
             :opportunity => @params['opportunity']
    end
  end

  def new_phonecall
    render :action => :new_phonecall, :layout => 'layout_jquerymobile'
  end
  
  def new_task
    render :action => :new_task, :layout => 'layout_jquerymobile'
  end

  def new_appointment
    render :action => :new_appointment, :layout => 'layout_jquerymobile'
  end

  # GET /Appt/{1}
  def show_appt
    @appt = Activity.find_activity(@params['id'])
    if @appt
      Settings.record_activity
      render :action => :show_appt, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))    
    end
  end

  def edit
    @activity = Activity.find_activity(@params['id'])
    @activity_contact = @activity.parent_contact if @activity
    @opportunity = @activity.opportunity if @activity
    @activity_title = @activity_contact.full_name if @activity_contact
    @activity_title += " - #{to_date(@opportunity.createdon)}" if @activity_contact && @opportunity
    puts "Activity edit page origin: #{@params['origin']} , id: #{@params['id']}"
    if @activity
     edit_action = "edit_#{@activity.type}".downcase 
      @cancelAction = case edit_action
      when 'edit_phonecall'
        :show_callback
      when 'edit_appointment'
        :show_appt
      else
        :show_task
      end
      @cancelAction = :show if Rho::NativeTabbar.get_current_tab == 2
      Settings.record_activity
      puts "The edit action is #{edit_action.to_sym}"
     render :action => edit_action.to_sym, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']
    else
      if @params['origin'] == 'appointments'
        WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))
      else
        WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))
        Rho::NativeTabbar.switch_tab(Constants::TAB_INDEX['Activities'])
        WebView.navigate(url_for(:controller => :Activity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'), Constants::TAB_INDEX['Activities'])
      end  
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
       WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'))   
     end
  end
   
  def get_duration(time1, time2)
    duration = (Time.parse(time2) - Time.parse(time1))/60
  end
  
  #CR: remove puts statements before committing
  #CR: use inline 'if's carefully. Here there should be an if clause and an 'else' to handle negative paths. What happens if we don't have an appointment?
  #CR: Wrap all database operations in transactions -- Note here that if the first update fails, the second update is now inaccurate.
  def update_appt
    Settings.record_activity
    @appointment = Activity.find_activity(@params['id'])
    @opportunity = @appointment.opportunity
    @appointment.update_attributes({
      :scheduledstart => DateUtil.date_build(@params['appointment_datetime']),
      :scheduledend => DateUtil.end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
      :location => @params['location'],
      :description => @params['description'],
      :cssi_location => @params['cssi_location']  
    }) 
    @appointment.update_attributes({
      :subject => @params['appointment_subject']
    }) unless @params['appointment_subject'].blank?
    @opportunity.update_attributes({
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }) if @opportunity
    SyncUtil.start_sync
    act = :show_appt
    act = :show if Rho::NativeTabbar.get_current_tab == 2
    redirect :action => act, :back => 'callback:',
              :id => @appointment.object,
              :query =>{:opportunity => @params['opportunity'], :origin => @params['origin']}
  end
  
  #CR: careful with the inline 'if's; remove crufty old output; needs a transaction
  def update_callback
    @callback = Activity.find_activity(@params['id'])
    @opportunity = @callback.opportunity
    duration = @callback.scheduleddurationminutes ? @callback.scheduleddurationminutes : Rho::RhoConfig.phonecall_duration_default_minutes.to_i
    Settings.record_activity
    @callback.update_attributes({
        :scheduledstart=> DateUtil.date_build(@params['callback_datetime']),
        :scheduleddurationminutes => duration,
        :scheduledend => DateUtil.end_date_time(@params['callback_datetime'], duration),
        :prioritycode => @params['callback_priority_checkbox'] ? 'High' : 'Normal',
        :phonenumber => @params['phone_number']
    })
    @callback.update_attributes({
        :cssi_phonetype => @params['phone_type_selected']
    }) unless @params['phone_type_selected'].blank?
    @callback.update_attributes({
        :subject => @params['phonecall_subject']
      }) unless @params['phonecall_subject'].blank?
      
    @opportunity.update_attributes({
      :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }) if @opportunity
    Activity.local_changed = true
    SyncUtil.start_sync
    act = :show_callback
    act = :show if Rho::NativeTabbar.get_current_tab == 2
    redirect :action => act, :back => 'callback:',
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

        appointmentids = get_appointment_ids(@params['appointments'])
        finished_win_status(opportunity, @params['origin'], appointmentids)

        db.commit
        
      rescue Exception => e
        puts "Exception in update won status, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
      end
      
      unless @params['task']['subject'].blank?
        task = create_new_task(@params['task'],opportunity)
      end
      
  end
  
  def create_new_task(task_params, opportunity)
      db = ::Rho::RHO.get_src_db('Activity')
      db.start_transaction
      begin
        task = Activity.create_new({
          :scheduledend => DateUtil.date_build(task_params['due_datetime']), 
          :subject => "#{task_params['subject']}",
          :parent_type => 'Contact', 
          :parent_id => opportunity.contact_id,
          :parent_contact_id => opportunity.contact_id,
          :statecode => 'Open',
          :type => 'Task',
          :prioritycode => task_params['high_priority_checkbox'] ? 'High' : 'Normal',
          :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
        })
        db.commit
     rescue Exception => e
        puts "Exception in create new Task, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
     end
  end
  
  def create_new_full_task
    db = ::Rho::RHO.get_src_db('Activity')
    db.start_transaction
    begin
      task = Activity.create_new({
        :scheduledend => DateUtil.date_build(@params['task_datetime']), 
        :subject => "#{@params['task_subject']}",
        :description => @params['task_description'],
        :statecode => 'Open',
        :type => 'Task',
        :prioritycode => @params['task_priority_checkbox'] ? 'High' : 'Normal',
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      })
      db.commit
      finished_create_activity
   rescue Exception => e
      puts "Exception in create new Task, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
   end
  end
  
  def create_new_contact_task
     contact = Contact.find_contact(@params['id'])
     db = ::Rho::RHO.get_src_db('Activity')
     db.start_transaction
     begin
       task = Activity.create_new({
         :scheduledend => DateUtil.date_build(@params['task_datetime']), 
         :subject => "#{@params['task_subject']}",
         :description => @params['task_description'],
         :parent_type => 'Contact', 
         :parent_id => contact.object,
         :statecode => 'Open',
         :type => 'Task',
         :prioritycode => @params['task_priority_checkbox'] ? 'High' : 'Normal',
         :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
       })
       db.commit
       finished_contact_activity(contact)
    rescue Exception => e
       puts "Exception in create new Task, rolling back: #{e.inspect} -- #{@params.inspect}"
       db.rollback
    end
  end
  
  def create_new_phonecall
    db = ::Rho::RHO.get_src_db('Activity')
    db.start_transaction
    begin
      task = Activity.create_new({
        :scheduledstart => DateUtil.date_build(@params['callback_datetime']), 
        :scheduleddurationminutes => Rho::RhoConfig.phonecall_duration_default_minutes.to_i,
        :scheduledend => DateUtil.end_date_time(@params['callback_datetime'], Rho::RhoConfig.phonecall_duration_default_minutes.to_i),
        :subject => "#{@params['phonecall_subject']}",
        :cssi_phonetype => "Ad Hoc",
        :phonenumber => @params['phonecall_number'],
        :statuscode => 'Open',
        :statecode => 'Open',
        :type => 'PhoneCall',
        :prioritycode => @params['callback_priority_checkbox'] ? 'High' : 'Normal',
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      })
      db.commit
      finished_create_activity
    rescue Exception => e
      puts "Exception in create new Task, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end
  end
  
  def create_new_appointment
    db = ::Rho::RHO.get_src_db('Activity')
    db.start_transaction
    begin
      task = Activity.create_new({
        :scheduledstart => DateUtil.date_build(@params['appointment_datetime']), 
        :scheduledend => DateUtil.end_date_time(@params['appointment_datetime'], @params['appointment_duration']),
        :subject => "#{@params['appointment_subject']}",
        :cssi_location => "Ad Hoc",
        :location => @params['appointment_location'],
        :description => @params['appointment_description'],
        :statuscode => "Busy",
        :statecode => "Scheduled",
        :type => 'Appointment',
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      })
      db.commit
      finished_create_activity
    rescue Exception => ecreate
      puts "Exception in create new appointment, rolling back: #{e.inspect} -- #{@params.inspect}"
      db.rollback
    end
  end

  def update_task
    Settings.record_activity
    @task = Activity.find_activity(@params['id'])
    if @task
      @task.update_attributes({ 
        :subject => @params['task']['subject'],
        :description => @params['task']['description'],
        :prioritycode => @params['task']['high_priority_checkbox'] ? 'High' : 'Normal',
        :scheduledend => DateUtil.date_build(@params['task']['due_datetime']),
      })
    end  
    SyncUtil.start_sync
    redirect :action => :show, :back => 'callback:',
              :id => @task.object,
              :query =>{:origin => @params['origin'], :activity => @task.object}

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
      opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
      db_activity = ::Rho::RHO.get_src_db('Activity')
      db_activity.start_transaction
      begin
        opportunity.complete_most_recent_open_call
        db_activity.commit
      rescue Exception => ea
        puts "Exception in close open phone call for lost status, rolling back: #{ea.inspect} -- #{@params.inspect}"
        db_activity.rollback
      end
      SyncEngine.dosync_source("Activity", false)
      db = ::Rho::RHO.get_src_db('Opportunity')
      db.start_transaction
      begin
        
        opportunity.create_note(@params['notes'])
        opportunity.update_attributes({
          :statecode => 'Lost',
          :statuscode => @params['status_code'],
          :cssi_statusdetail => "",
          :competitorid => @params['competitorid'] || "",
          :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
          :status_update_timestamp => Time.now.utc.to_s
        })
      
        opportunity.record_phone_call_made_now("Lost")
        appointmentids = get_appointment_ids(@params['appointments'])
        
        finished_loss_status(opportunity, @params['origin'], appointmentids)
        db.commit
      rescue Exception => e
        puts "Exception in update lost status, rolling back: #{e.inspect} -- #{@params.inspect}"
        db.rollback
      end
      unless @params['task']['subject'].blank?
        task = create_new_task(@params['task'],opportunity)
      end
    else
      WebView.navigate(url_for :controller => :Opportunity, :action => :status_update, :id => @params['opportunity_id'], :query => {:origin => @params['origin']})
    end
  end
  
  def confirm_lost_other_status
    unless @params['status_code'].blank?

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
        opportunity = Opportunity.find_opportunity(@params['opportunity_id'])
        db_activity = ::Rho::RHO.get_src_db('Activity')
        db_activity.start_transaction
        begin
          opportunity.complete_most_recent_open_call
          db_activity.commit
        rescue Exception => ea
          puts "Exception in close open phone call for lost status, rolling back: #{ea.inspect} -- #{@params.inspect}"
          db_activity.rollback
        end
        SyncEngine.dosync_source("Activity", false)
        db = ::Rho::RHO.get_src_db('Opportunity')
        db.start_transaction
        begin
          opportunity.update_attributes({
            :statecode => 'Lost',
            :statuscode => @params['status_code'],
            :cssi_statusdetail => "",
            :competitorid => @params['competitorid'] || "",
            :cssi_lastactivitydate => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
            :status_update_timestamp => Time.now.utc.to_s
          })
      
          opportunity.record_phone_call_made_now("Lost")
      
          appointmentids = get_appointment_ids(@params['appointments'])
          finished_loss_status(opportunity, @params['origin'], appointmentids)
          db.commit
        rescue Exception => e
          puts "Exception in update lost status, rolling back: #{e.inspect} -- #{@params.inspect}"
          db.rollback
        end
        unless @params['task']['subject'].blank?
          task = create_new_task(@params['task'],opportunity)
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
        :scheduledstart => DateUtil.date_build(@params['callback_datetime']), 
        :scheduleddurationminutes => Rho::RhoConfig.phonecall_duration_default_minutes.to_i,
        :scheduledend => DateUtil.end_date_time(@params['callback_datetime'], Rho::RhoConfig.phonecall_duration_default_minutes.to_i),
        :subject => "Phone Call - #{opportunity.contact.full_name}",
        :cssi_phonetype => @params['phone_type_selected'],
        :phonenumber => @params['phone_number'],
        :parent_type => 'Opportunity', 
        :parent_id => opportunity.object,
        :parent_contact_id => opportunity.contact_id,
        :statuscode => 'Open',
        :statecode => 'Open',
        :type => 'PhoneCall',
        :prioritycode => @params['callback_priority_checkbox'] ? 'High' : 'Normal',
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
      })
      
      appointmentids = get_appointment_ids(@params['appointments'])
      finished_update_status(opportunity, @params['origin'], appointmentids)
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
            :subject => "#{contact.full_name} - #{opportunity.createdon}",
            :description => @params['description'],
            :type => 'Appointment',
            :cssi_location => @params['cssi_location'],
            :parent_contact_id => opportunity.contact_id,
            :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
          }
        )
        
        appointmentids = get_appointment_ids(@params['appointments'])
        finished_update_status(opportunity, @params['origin'], appointmentids)
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
  
  def verify_pin
     if @params['PIN'] == AppInfo.instance.policy_pin
       Settings.pin_last_activity_time = Time.new
       Settings.pin_confirmed = true
       redirect :action => :show, :id => @params['id'], :query => {:origin => @params['origin']}
     else
       Alert.show_popup({
         :message => "Invalid PIN Entered", 
         :title => 'Invalid PIN', 
         :buttons => ["OK"]
       })
       @pinverified="false"
       redirect :action => :show, :id => @params['id'], :query => {:origin => @params['origin']}
     end    
  end
   
  def mark_as_complete
   activity = Activity.find_activity(@params['id'])
   activity.complete if activity
   redirect :action => :index, :back => 'callback:'
  end
  
  private
  
  def get_appointment_ids(appointment_params)
    ids = appointment_params.gsub(/[\[\]"\s]/, '') if appointment_params
    ids.split(",") if ids
  end
  
  def finished_update_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncUtil.start_sync
    redirect :controller => :Opportunity, :action => :show, :back => 'callback:', :id => opportunity.object, :query => {:origin => origin}
  end
  
  def finished_create_activity
    SyncUtil.start_sync
    WebView.navigate(url_for( :action => :index, :back => 'callback:', :layout => 'layout_JQM_lite'))
  end
  
  def finished_win_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncUtil.start_sync
    redirect :controller => :Opportunity, :action => :show, :id => opportunity.object, :back => 'callback:', :query => {:origin => origin}
  end

  def finished_loss_status(opportunity, origin, appointmentids=nil)
    complete_appointments(appointmentids)
    SyncUtil.start_sync
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

  def finished_contact_activity(contact)
    SyncUtil.start_sync
    WebView.navigate(url_for( :controller => :contact, :action => :show, :id => contact.object, :back => 'callback:', :layout => 'layout_JQM_lite'))
  end

end
