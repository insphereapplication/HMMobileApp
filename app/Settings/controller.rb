require 'rho'
require 'rho/rhocontroller'
require 'rho/rhoerror'
require 'helpers/browser_helper'
require 'rho/rhotabbar'
require 'helpers/crypto'
require 'Contact/contact_controller'
require 'Activity/activity_controller'


class SettingsController < Rho::RhoController
  $prompted_for_upgrade = false
  include BrowserHelper
 

  ERR_403_MESSAGE = "Sorry! You are not eligible to use the mobile app. Please contact support at hmmobile@healthmarkets.com"

  def index
    $tab = 3
    @msg = @params['msg']
    render :action => :index, :back => 'callback:', :layout => 'layout'
  end
  
  def can_skip_login?
    Settings.has_verified_credentials? and Settings.initial_sync_completed?
  end
  
  def init
    if can_skip_login?
      #login & sync in background
      puts "using background login"
      Rho::RhoConnectClient.login(Settings.login, Settings.password,  '/app/Settings/background_login_callback')
      #go to opportunity index page
      goto_opportunity_init_notify
    else
      #go to login screen
        puts "In can_skip_login false"
      goto_login
    end
  end

  def local_changes?
    (Opportunity.changed? || Contact.changed?)
  end
  
  def sync_state
    if local_changes?
      "Yes"
    else
      "No"
    end
  end
  
  def get_connection_status
    puts "^^^^^^^^^^^^^^^ Calling get connection status ^^^^^^^^^^^^^^^^^^^"
    if AppApplication.activated?
      connection_status = DeviceCapabilities.connection_status
      sync_status = DeviceCapabilities.sync_status
      @result = "#{connection_status},#{sync_status}"
      #Do not remove rendor below even though it is just returning results above.  It currently keeps android back button return to same page instead of back a page
      render :action => :get_connection_status, :back => 'callback:', :layout => false
    else  
      puts "????????????????????????????? Get connection status is call from the background  ?????????????????????????????"
      if System::get_property('platform') == 'ANDROID' 
        puts "????????????????????????????? Get connection status is call from the background with a sync interval  ?????????????????????????????"
        #log_error("Application Restarted in background", "Get connection status is call from the background with a sync interval")
      end
    end  
    
  end
  
  def detailed_logging_enabled?
    RhoConf.get_property_by_name('MinSeverity') == '1'
  end
  
  def login
    @msg = @params['msg']
	puts "In Login with message #{@msg}"
    override_auto_login = @params['override_auto_login']
    # if the user has stored successful login credentials, attempt to auto-login with them
    if Settings.has_verified_credentials? and override_auto_login.to_s != 'true'
      update_login_wait_progress("Logging in with cached credentials")
      Rho::RhoConnectClient.login(Settings.login, Settings.password, "/app/Settings/login_callback")
      @working = true # if @working is true, page will show spinner
    end
    
	puts "Need to re log in"
    Rho::NativeTabbar.remove
    @menu = { "Log" => :log }
	# If the user must log in 
	Rho::RhoConnectClient.pollInterval = 0
    render :action => :login, :back => '/app/Settings/login', :layout => 'layout'
  end
  
  def goto_login(msg=nil)
    WebView.navigate(url_for(:action => :login, :query => {:msg => msg} ))
  end
  
  def goto_login_override_auto(msg=nil)
   WebView.navigate(url_for(:action => :login, :query => {:msg => msg, :override_auto_login => true}) )
  end
  
  def background_login
    # if the user has stored successful login credentials, attempt to auto-login with them
    if Settings.has_verified_credentials?
	  puts "Logging in with saved credentials"
      Rho::RhoConnectClient.login(Settings.login, Settings.password,  '/app/Settings/background_login_callback')
    else
      goto_login
    end
  end

  def login_callback
    puts "In login_callback"
    errCode = @params['error_code'].to_i
    httpErrCode = @params['error_message'].split[0]
    if errCode == 0
      Settings.credentials_verified = true
      Rho::RhoConnectClient.pollInterval = Constants::DEFAULT_POLL_INTERVAL
      #setup the sync event handlers for the application init sequence, start sync
      SyncUtil.start_sync('init')
      update_login_wait_progress("Login successful, starting sync...")
    elsif errCode == Rho::RhoError::ERR_NETWORK && can_skip_login?
      #DO NOT send connectivity errors to exceptional, causes infinite loop at the moment (leave ':send_to_exceptional => false' alone)
      log_error("Verified credentials, but no network.","",{:send_to_exceptional => false})
      #we've got cached, verified credentials, so proceed with the usual initialization process
	  puts "^^^^^goto_opportunity_init_notify from login_callback with rho ERR_NEtwork / skip login "
      Rho::RhoConnectClient.pollInterval = Constants::DEFAULT_POLL_INTERVAL
      goto_opportunity_init_notify
    else
      Settings.clear_credentials
      Rho::RhoConnectClient.pollInterval = 0
      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
      
      if httpErrCode == "403" # User is not authorized to use the mobile device, so we need to purge the local database
        @msg ||= ERR_403_MESSAGE
        Rhom::Rhom.database_fullclient_reset_and_logout
      elsif errCode == Rho::RhoError::ERR_NETWORK
        @msg ||= "Can't connect to the network. Please try again."
      else
        @msg ||= "The user name or password you entered is not valid"    
      end
      
      goto_login(@msg)
    end
  end
  
  def background_login_callback
    puts "In background_login_callback"
    errCode = @params['error_code'].to_i
    httpErrCode = @params['error_message'].split[0]
    
    if errCode == 0
      Rho::RhoConnectClient.pollInterval = Constants::DEFAULT_POLL_INTERVAL
      #perform a sync in the background
      SyncUtil.start_sync
    elsif errCode == Rho::RhoError::ERR_NETWORK && can_skip_login?
      #DO NOT send connectivity errors to exceptional, causes infinite loop at the moment (leave ':send_to_exceptional => false' alone)
      log_error("Verified credentials, but no network.","",{:send_to_exceptional => false})
      #at this point, we've got cached, verified credentials but we can't connect to RhoSync. 
      #don't throw an error, but reinstate poll interval so that we continue to check for connectivity
       Rho::RhoConnectClient.pollInterval = Constants::DEFAULT_POLL_INTERVAL  
    else
      Settings.clear_credentials
      Rho::RhoConnectClient.pollInterval = 0
      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
      
      if httpErrCode == "403" # User is not authorized to use the mobile device, so we need to purge the local database
        @msg ||= ERR_403_MESSAGE
        Rhom::Rhom.database_fullclient_reset_and_logout
      else
        @msg ||= "The user name or password you entered is not valid"    
      end
        
      goto_login(@msg)
    end
  end

  def do_login
    Settings.login = @params['login'].downcase unless @params['login'].blank?
    Settings.password = @params['password'] unless @params['password'].blank?
    
    if Settings.login and Settings.password
      begin
        Rho::RhoConnectClient.login(Settings.login, Settings.password, (url_for :action => :login_callback) )
        update_login_wait_progress("Logging in...")
        Settings.pin_last_activity_time = Time.new
        Settings.pin_confirmed=false
      rescue Rho::RhoError => e
        Settings.clear_credentials
        @msg = e.message
      end
    else
      Settings.clear_credentials
      @msg = Rho::RhoError.err_message(Rho::RhoError::ERR_UNATHORIZED) unless @msg && @msg.length > 0   
    end
    render :action => :login, :back => 'callback:', :layout => 'layout'
  end
  
  def do_logout
    Settings.clear_credentials
    Rho::RhoConnectClient.pollInterval = 0
    Settings.last_integrated_lead = ''
    Settings.last_assigned_lead = ''
    Settings.flush_instance
    
    #Reset the first render flags to true for activity and contact pages
    ContactController.reset_first_render
    ActivityController.reset_first_render

    
    Rho::NativeTabbar.remove
    redirect :action => :login, :query => {:msg => "You have been logged out."}
  end
  
  def backgroundsync
    @msg = @params['msg']
    render :action => :backgroundsync, :back => 'callback:', :layout => 'layout'
  end
  
  def set_background_sync_time
		entered_time = @params['backgroundsynctime']
		if entered_time != AppInfo.instance.get_background_sync_time
			AppInfo.instance.set_background_sync_time(entered_time)
		end	 
		
		redirect :action => :index, :back => 'callback:', :query => {:msg => @msg}		
  end
  
  def pin
    @msg = @params['msg']
    render :action => :pin, :back => 'callback:', :layout => 'layout'
  end
  
  
  
  def validate_pin
    enter_pin = @params['enter_pin']
    verify_pin = @params['verify_pin']
    password = @params['pin_password']
     
      if enter_pin and verify_pin and password
        if ( enter_pin == verify_pin )
          if ( password == Settings.password )
            @msg = nil
            AppInfo.instance.set_pin(enter_pin)
            Settings.pin = verify_pin
            Settings.pin_confirmed = false
            @msg =  "Your PIN has been reset."
            
            if !(@params['contact'].blank?)
              redirect :controller => :Contact, :action => :show, :id => @params['contact'], :query => {:origin => @params['origin'], :opportunity => @params['opportunity']}
              return
            elsif !(@params['activity'].blank?)
              redirect :controller => :Activity, :action => :show, :id => @params['activity'], :query => {:origin => @params['origin'], :activity => @params['activity']}
              return  
            else
              redirect :action => :index, :back => 'callback:', :query => {:msg => @msg}
              return
            end
          else
            @msg = 'The password you entered is not valid.'
          end
        else
          @msg = 'Please enter matching PINs'
        end
      end
    WebView.navigate(url_for(:action => :pin, :back => 'callback:', :layout => 'layout', :query => {:msg => @msg, :origin => @params['origin'], :contact => @params['contact'], :opportunity => @params['opportunity'], :activity => @params['activity']} ))  if @msg and @msg.length > 0
  end # validate_pin
  
  def validate_pin_callback
    redirect :action => :index
  end
  
  def verify_pin
    if @params['PIN'] == AppInfo.instance.policy_pin
      puts @params.inspect
      Settings.pin_last_activity_time = Time.new
      Settings.pin_confirmed = true
      render :action => :index, :query => {:origin => @params['origin']}
    else
      Alert.show_popup({
        :message => "Invalid PIN Entered", 
        :title => 'Invalid PIN', 
        :buttons => ["OK"]
      })
      @pinverified="false"
      render :action => :index, :query => {:origin => @params['origin']}
    end    
  end
  
  def pin_is_current?(last_activity)
    if Time.new - last_activity < 120
      return true
    else
      return false
    end
  end
  
  def reset
    render :action => :reset, :back => 'callback:'
  end
  
  def about
    render :action => :about, :back => 'callback:'
  end
  
  def model_limit_counts
    render :action => :model_limit_counts, :back => 'callback:'
  end
  
  def do_reset
    Rhom::Rhom.database_fullclient_reset_and_logout
    Settings.flush_instance
    Rho::RhoConnectClient.pollInterval = 0
    redirect :action => :login, :back => 'callback:', :query => {:msg => "Database has been reset."}
  end
  
  def full_reset_logout_keep_device_id
    Rhom::Rhom.database_full_reset_and_logout
    # clear out cached settings
    Settings.flush_instance
  end
  
  def full_reset_logout
    Rhom::Rhom.database_fullclient_reset_and_logout
    # clear out cached settings
    Settings.flush_instance
  end
  
  def full_reset_logout_keep_credentials
    # backup credential cache before DB reset
    login_backup = Settings.login
    password_backup = Settings.password
    credentials_verified_backup = Settings.credentials_verified
            
    full_reset_logout
    
    # restore credential cache after DB reset
    Settings.login = login_backup
    Settings.password = password_backup
    Settings.credentials_verified = credentials_verified_backup
  end
  
  def do_sync
    SyncUtil.start_sync('background')
    @msg =  "Sync has been triggered."
    redirect :action => :index, :back => 'callback:', :query => {:msg => @msg}
  end
  
  def push_notify
    #setup callbacks to use new opportunity workflow, start sync
    puts "Starting push_notify, new_opportunity_sync_pending = #{Settings.new_opportunity_sync_pending}, is_syncing = #{Rho::RhoConnectClient.isSyncing()}"
    unless Settings.new_opportunity_sync_pending
      puts "No pending syncs of type new_opportunity"
      Settings.new_opportunity_sync_pending = true
      unless Rho::RhoConnectClient.isSyncing()
        puts "Sync engine isn't currently syncing, starting new_opportunity sync"
        Settings.new_opportunity_sync_pending = false
        SyncUtil.start_sync('new_opportunity')
      else
        puts "A sync is in progress, pending new_opportunity sync will be executed once the current sync completes."

      end
      puts "Done"
    else
      puts "New opportunity sync is already pending"
    end
    puts "new opp sync pending in push notify: " + Settings.new_opportunity_sync_pending.to_s
    Opportunity.local_changed = true
    @@delay_refresh = false
    if System::get_property('platform') == 'ANDROID'
       Rho::Notification.showPopup({'message' => @params['alert'], 'buttons' =>['OK']})
     else
       ""
     end
  
  end
  
  def set_last_integrated_lead
    Opportunity.latest_integrated_lead.each do |opportunity|
      Settings.last_integrated_lead = opportunity.createdon
    end
  end
  
  def set_last_assigned_lead
    last_opportunity = Opportunity.latest_assigned_lead
    Settings.last_assigned_lead = last_opportunity.cssi_assigneddate if last_opportunity
    last_opportunity
  end
  
  def update_last_synced_time
    Settings.last_synced = Time.now
  end
  
  def handle_new_integrated_leads
    if new_assigned_leads?
      set_last_integrated_lead
      reassigned_leads_alert
    else
      former_last_lead = Settings.last_integrated_lead
      set_last_integrated_lead
      current_last_lead = Settings.last_integrated_lead
      if (former_last_lead.blank? && !current_last_lead.blank? && created_last_hour(current_last_lead)) || (!former_last_lead.blank? && !current_last_lead.blank? && Time.parse(current_last_lead)  > Time.parse(former_last_lead))
        puts "NEW LEAD CREATED AT #{current_last_lead}"
        new_leads_alert
      end
    end
  end
  
  def new_assigned_leads?
    former_assigned_lead = Settings.last_assigned_lead
    @current_assigned_lead = set_last_assigned_lead
    if former_assigned_lead.blank? && @current_assigned_lead.blank?
      false
    elsif former_assigned_lead.blank? && @current_assigned_lead
      (created_today?) && (reassigned_lead?)
    else   
      @current_assigned_lead && (created_today?)  && (Time.parse(@current_assigned_lead.cssi_assigneddate) > Time.parse(former_assigned_lead)) && (reassigned_lead?)
    end
  end
  
  def created_last_hour(create_date)
    if (create_date)
      hours = (Time.now - Time.parse(create_date))/3600
      hours < 1
    end
  end

  
  def created_today?
    if (@current_assigned_lead.createdon)
      hours = (Time.now - Time.parse(@current_assigned_lead.createdon))/3600
      hours <= 24
    end
  end
  
  def reassigned_lead?
    !(@current_assigned_lead.cssi_assetownerid == @current_assigned_lead.ownerid)
  end
  
  def new_leads_alert 
    if Settings.has_verified_credentials?
      Alert.show_popup({
        :title => 'View New Leads?',
        :message => "New lead(s) have been synced.\nWould you like to view them?", 
        :buttons => ["Cancel", "View"],
        :callback => url_for(:action => :on_dismiss_new_opportunity_popup, :back => 'callback:') 
      })
    end
  end
  
  def model_limit_alert 
    if Settings.has_verified_credentials?
      Alert.show_popup({
        :title => 'Limits Alert',
        :message => "The number of Opportunity, Contact, Policies, Activities or Notes is approaching the max amount allowed on HMMobile?", 
        :buttons => ["Cancel", "View"],
        :callback => url_for(:action => :on_model_limit_popup, :back => 'callback:') 
      })
    end
  end
  
  def reassigned_leads_alert
    if Settings.has_verified_credentials?
      Alert.show_popup({
        :title => 'Reassigned Opportunities',
        :message => "You have been assigned opportunities.\nWould you like to view them?", 
        :buttons => ["Cancel", "View"],
        :callback => url_for(:action => :on_dismiss_new_opportunity_popup, :back => 'callback:') 
      })
    end
  end
  
  #sync_notify gets called whenever any sync is in progress, completed, or returns an error
  #this is registered in the initialize method in application.rb
  def sync_notify
    #     ERR_NONE = 0
    #     ERR_NETWORK = 1
    #     ERR_REMOTESERVER = 2
    #     ERR_RUNTIME = 3
    #     ERR_UNEXPECTEDSERVERRESPONSE = 4
    #     ERR_DIFFDOMAINSINSYNCSRC = 5
    #     ERR_NOSERVERRESPONSE = 6
    #     ERR_CLIENTISNOTLOGGEDIN = 7
    #     ERR_CUSTOMSYNCSERVER = 8
    #     ERR_UNATHORIZED = 9
    #     ERR_CANCELBYUSER = 10
    #     ERR_SYNCVERSION = 11
    #     ERR_GEOLOCATION = 12
    
    setup_sync_handlers
    
    
    sourcename = @params['source_name'] ? @params['source_name'] : ""
  
    status = @params['status'] ? @params['status'] : ""
    
    if status == "complete"
      update_last_synced_time
            
      if Settings.new_opportunity_sync_pending
        puts "Sync complete, starting pending new_opportunity sync."
        SyncUtil.start_sync('new_opportunity')
        Settings.new_opportunity_sync_pending = false
      end
      
      # store device info
      DeviceInfo.check_device_information
      if model_limits_warning?
        model_limit_alert
      end
	  
      @on_sync_complete.call
      

      #if latest integrated lead createdon is greater than before sync, display popup alert
      # handle_new_integrated_leads
    elsif status == "ok"
	  count = sourcename == 'Opportunity' ?  Opportunity.open_opportunities_count : @params['total_count']
      puts "#{sourcename} count is: #{count}"
	  if sourcename == 'AppInfo'
        check_for_upgrade
      elsif model_limits_exceeded?(sourcename, count)
        # model limit exceeded, stop synchronization
        return
      end
      
      if sourcename == 'Opportunity'
        handle_new_integrated_leads if AppApplication.activated?
      end
      
      if @params['source_name'] && @params['cumulative_count'] && @params['cumulative_count'].to_i > 0
        klass = Object.const_get(@params['source_name'])
        klass.local_changed=true if klass && klass.respond_to?(:local_changed=)
      end
      
      @on_sync_ok.call
    elsif status == "in_progress"
      @on_sync_in_progress.call
    elsif status == "error"
      err_code = @params['error_code'].to_i
      rho_error = Rho::RhoError.new(err_code)
      
      is_bad_request_data = (err_code == Rho::RhoError::ERR_CUSTOMSYNCSERVER) && !@params['server_errors'].to_s[/406 Not Acceptable/].nil?
      
      if @params['server_errors'] && @params['server_errors']['create-error']
        log_error("Create error", @params.inspect)
        unless is_bad_request_data  
          Rho::RhoConnectClient.on_sync_create_error( @params['source_name'], @params['server_errors']['create-error'], :recreate)
        else
          #notify the user here?
          #the create data given to the proxy was bad and will not succeed if tried again; delete the create
          Rho::RhoConnectClient.on_sync_create_error( @params['source_name'], @params['server_errors']['create-error'], :delete)
        end
      end
      
      if @params['server_errors'] && @params['server_errors']['update-error']
        log_error("Update error", @params.inspect)
        unless is_bad_request_data
          Rho::RhoConnectClient.on_sync_update_error( @params['source_name'], @params['server_errors']['update-error'], :retry)
        else
          #notify the user here?
          Rho::RhoConnectClient.on_sync_update_error( @params['source_name'], @params['server_errors']['update-error'], :rollback, @params['server_errors']['update-rollback'])
        end
      end

      @msg = rho_error.message unless @msg and @msg.length > 0
      
      # RhoSync 2.1.5 has fixes that will cause rho_error.unknown_client? to return true in the proper scenarios.
      is_unknown_client_error = rho_error.unknown_client?(@params['error_message']) 
      
      # Legacy support for RhoSync versions before 2.1.5
      is_unknown_client_error ||= (err_code == Rho::RhoError::ERR_REMOTESERVER && @params['error_message'] == "undefined method `user_id' for nil:NilClass")
      
      # Rhosync is not aware of this client's ID. Reset and force the user to the login screen.
      if is_unknown_client_error
        log_error("Error: Unknown client", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        
        Rho::RhoConnectClient.pollInterval = 0
        Rho::RhoConnectClient.stopSync()

        full_reset_logout
        
        goto_login("Unknown client, please log in again.")
      elsif err_code == Rho::RhoError::ERR_NETWORK
        #leave ':send_to_exceptional => false' alone until infinite loop issue is fixed for clients without a network connection
        log_error("Network connectivity lost", Rho::RhoError.err_message(err_code) + " #{@params.inspect}", {:send_to_exceptional => false})
        
        #stop current sync, otherwise do nothing for connectivity lapse
        Rho::RhoConnectClient.stopSync()
        
        #send them back to login because initial sync did not complete
        puts "!!!!!! Rho::RhoError::ERR_NETWORK???  !!!!!!!"
        @on_sync_error.call({:error_source => 'connection'})
      elsif [Rho::RhoError::ERR_CLIENTISNOTLOGGEDIN,Rho::RhoError::ERR_UNATHORIZED].include?(err_code)      
        log_error("RhoSync error: client is not logged in / unauthorized", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        Rho::RhoConnectClient.pollInterval = 0
        Rho::RhoConnectClient.stopSync()
        background_login
      elsif err_code == Rho::RhoError::ERR_CUSTOMSYNCSERVER && !@params['server_errors'].to_s[/401 Unauthorized/].nil?
        #proxy returned a 401, need to re-login
        log_error("Error: 401 Unauthorized from proxy", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        Rho::RhoConnectClient.pollInterval = 0
        Rho::RhoConnectClient.stopSync()
        
        Settings.initial_sync_complete = false
        Settings.password = ''
        goto_login("Your username/password is no longer valid. Please log in again.")
      elsif err_code == Rho::RhoError::ERR_CUSTOMSYNCSERVER && !@params['server_errors'].to_s[/403 Forbidden/].nil?
        #proxy returned a 403, need to purge the database and log the user out
        log_error("Error: 403 Forbidden from proxy", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        Rho::RhoConnectClient.pollInterval = 0
        Rho::RhoConnectClient.stopSync()
        
        full_reset_logout
        
        msg = ERR_403_MESSAGE
        goto_login(msg)
      elsif is_bad_request_data
        log_error("Bad request data","Bad request data, client sent invalid data to CRM proxy, proxy returned 406. Error params: #{@params.inspect}")
      else
        log_error("Unhandled error in sync_notify: #{err_code}", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        @on_sync_error.call({:error_source => 'unknown', :error_code => err_code})
      end
    end
  end
  
  def update_login_wait_progress(text)
    WebView.executeJavascript('update_wait_progress("'+text+'");')
  end
  
  def update_login_sync_progress(model, percent)
    text = "Synchronizing:<br/>#{model} #{percent.to_s}%"
    update_login_wait_progress(text)
  end
  
  def log_error(title, message, params={})
    unless params[:send_to_exceptional] == false
      ExceptionUtil.log_exception_to_server(Exception.new("Error in SyncNotify for user '#{Settings.login}': #{title} -- #{message}"))
    end
    
    puts "Error: #{title} --- #{message}"
    
    #uncomment the following lines to show popups when errors are logged
    unless params[:show_popup] == false
      # show_popup(title, message)
    end
  end
  
  def show_popup(title, message)
    Alert.show_popup({
      :title => title,
      :message => message,
      :buttons => ["OK"]
    })
  end
  
  def show_log
    Rho::RhoConfig.show_log
     redirect :action => :about, :back => 'callback:'
  end
  
  def send_log
    Rho::RhoConfig.send_log
    show_popup( "Log File Sent", "Time: #{Time.now.to_s}\nClient id #{Rhom::Rhom::client_id}" )
    
    redirect :action => :about, :back => 'callback:'
  end
  
  def clear_log
    Rho::RhoConfig.clean_log
    redirect :action => :about
  end
  
  def toggle_log_level
    new_log_level = detailed_logging_enabled? ? '3' : '1'
    RhoConf.set_property_by_name('MinSeverity', new_log_level)
    
    log_level_message = "Detailed logging #{new_log_level == '3' ? 'disabled' : 'enabled'}."

    redirect :action => :about, :back => 'callback:'
  end
  
  def save_log_config
    RhoConf.set_property_by_name('MinSeverity', @params['minSeverity'])
    RhoConf.set_property_by_name('MaxLogFileSize', @params['logFileSize'])
    
    minSeverity = RhoConf.get_property_by_name('MinSeverity')
    logFileSize = RhoConf.get_property_by_name('MaxLogFileSize')
    
    @msg = "Log config changes have been saved."
    redirect :action => :index, :back => 'callback:', :query => {:msg => @msg}  
  end
  
  def test_exception
    raise "bang"
  rescue Exception => e
    ExceptionUtil.log_exception_to_server(e)
    WebView.navigate( url_for(:action => :index ))
  end

  def goto_opportunity_init_notify
    puts "%%%% In goto_opportunity_init_notify"
    WebView.navigate( url_for( :controller => :Opportunity, :action => :init_notify))
  end
  
  def setup_sync_handlers
    if Settings.is_init_sync?
      set_init_sync_handlers
    elsif Settings.is_new_opportunity_sync?
      set_new_opportunity_sync_handlers
    else
      set_background_sync_handlers
    end
  end
  
  def set_background_sync_handlers
    @on_sync_error = lambda {|*args|}
    @on_sync_complete = lambda {|*args|}
    @on_sync_in_progress = lambda {|*args|}
    @on_sync_ok = lambda {|*args|}
  end
  
  def set_init_sync_handlers
    @on_sync_error = lambda {|*args| init_on_sync_error(*args)}
    @on_sync_complete = lambda {|*args| init_on_sync_complete(*args)}
    @on_sync_in_progress = lambda {|*args| init_on_sync_in_progress(*args)}
    @on_sync_ok = lambda {|*args| init_on_sync_ok(*args)}
  end
  
  def set_new_opportunity_sync_handlers
    @on_sync_error = lambda {|*args|}
    @on_sync_complete = lambda {|*args| new_opportunity_on_sync_complete(*args)}
    @on_sync_in_progress = lambda {|*args|}
    @on_sync_ok = lambda {|*args| new_opportunity_on_sync_ok(*args)}
  end
  
  def init_on_sync_error(*args)
    raise ArgumentError, "Hash must be given as the first argument" unless args[0].is_a?(Hash)    
    
    error_source = args[0][:error_source]
    
    if Settings.initial_sync_completed?
      #if it's a connection based error, 
      if error_source == 'connection'
        #swallow this error, let the user through
        #navigate to opportunity init_notify controller 
        goto_opportunity_init_notify
      end
    else
      #TODO: determine if database reset is needed here
      #we haven't successfully synced before, so navigate back to the login screen (but keep the credentials)
      Rho::RhoConnectClient.stopSync()
      goto_login_override_auto("Sync error. Please try logging in again.")
    end
  end
  
  def init_on_sync_complete(*args)
    #change sync handlers back to default
    SyncUtil.set_sync_type('background')
    
    Settings.initial_sync_complete = true
    
    #navigate to opportunity init_notify controller action
	puts "^^^^^goto_opportunity_init_notify from  init_on_sync_complete"
    goto_opportunity_init_notify
  end
  
  def init_on_sync_in_progress(*args)
    percent = 0
    if @params["total_count]"].to_f > 0.0
      percent = (@params["cumulative_count"].to_f/@params["total_count"].to_f * 100).to_i
    end
    update_login_sync_progress(@params['source_name'], percent)
  end
  
  def init_on_sync_ok(*args)
    update_login_sync_progress(@params['source_name'], 100)
  end
  
  def new_opportunity_on_sync_ok(*args) 
    # if @params['source_name'] == 'Opportunity' && Settings.has_verified_credentials?
    # 
    #   Alert.show_popup({
    #     :title => 'View New Leads?',
    #     :message => "New lead(s) have been synced.\nWould you like to view them?", 
    #     :buttons => ["Cancel", "View"],
    #     :callback => url_for(:action => :on_dismiss_new_opportunity_popup, :back => 'callback:') 
    #   })
    # end
  end
  
  def new_opportunity_on_sync_complete(*args)
    #change sync handlers back to background
    SyncUtil.set_sync_type('background')
  end
  
  def on_dismiss_new_opportunity_popup
    if @params['button_id'] == 'View'
      Rho::NativeTabbar.switch_tab(Constants::TAB_INDEX['Opportunities']) 
      WebView.navigate(url_for(:controller => :Opportunity, :action => :index), Constants::TAB_INDEX['Opportunities'])
    end
  end
  
def on_model_limit_popup
  if @params['button_id'] == 'View'
    Rho::NativeTabbar.switch_tab(Constants::TAB_INDEX['Tools']) 
    WebView.navigate( 
      url_for(:controller => :Settings, :action => :model_limit_counts, :layout => 'layout'), Constants::TAB_INDEX['Tools'])
  end
end
  
  def parse_version_number(version)
    version.split(".").map{ |x| x.to_i }
  end
  
  def needs_upgrade?(min_version, current_version) # returns true if current_version is less than min_version
    # comparison is lexicographical, as in it reads from left to right and only proceeds to the 
    # next sub-version if a given sub-version in min_version and current_version is equal
    unless min_version.nil?
      min_version_split = parse_version_number(min_version)
      current_version_split = parse_version_number(current_version)
    
      puts "****Version check: min version = #{min_version_split}, current version = #{current_version_split}****"
    
      # compare sub-versions from left to right
      # if current_version has fewer version numbers than min_version, assume '0' for missing version numbers to the right 
      (0...min_version_split.count).each do |i|
        if min_version_split[i] > (current_version_split[i] || 0)
          # current_version must be older, no need to continue checking
          return true
        elsif min_version_split[i] < (current_version_split[i] || 0)
          # current_version must be newer, no need to continue checking
          return false
        end
      end
    end
    
    # given versions are equal
    return false
  end

  def quick_quote
    Settings.record_activity
    redirect :action => :index, :back => 'callback:', :layout => 'layout'
    quote_url=Rho::RhoConfig.quick_quote_url
    System.open_url("#{quote_url}")
  end
  
  def resource_center
        Settings.record_activity
        if Settings.pin_confirmed == true
          resource_url=Rho::RhoConfig.resource_center_url
          resource_target=Rho::RhoConfig.resource_center_target
          ctime = Time.new.utc
          ctime_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{ctime}Delimit"))
          user_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.login}Delimit"))
          pwd_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.password}Delimit"))
            
          resource_params_enc = "UserName=#{user_enc}&pwd=#{pwd_enc}&valid=#{ctime_enc}&ReturnURL=#{resource_target}"
        
          puts "Resource URL parameters are: ****#{resource_params_enc}****"
          puts "Current UTC is:  #{ctime}"

          rc_url ="#{resource_url}?#{resource_params_enc}"
       
          redirect :action => :index, :back => 'callback:', :layout => 'layout'
        
          System.open_url("#{resource_url}?#{resource_params_enc}")
          
      else
          redirect :action => :index, :back => 'callback:', :layout => 'layout'
      end
      
  end
  
  def lead_amp
        Settings.record_activity
        if Settings.pin_confirmed == true
          resource_url=Rho::RhoConfig.resource_center_url
          lead_amp_target=Rho::RhoConfig.lead_amp_target
          ctime = Time.new.utc
          ctime_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{ctime}Delimit"))
          user_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.login}Delimit"))
          pwd_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.password}Delimit"))
            
          resource_params_enc = "UserName=#{user_enc}&pwd=#{pwd_enc}&valid=#{ctime_enc}&ReturnURL=#{lead_amp_target}"
        
          puts "Resource URL parameters are: ****#{resource_params_enc}****"
          puts "Current UTC is:  #{ctime}"

          rc_url ="#{resource_url}?#{resource_params_enc}"
       
          redirect :action => :index, :back => 'callback:', :layout => 'layout'
        
          System.open_url("#{resource_url}?#{resource_params_enc}")
          
      else
          redirect :action => :index, :back => 'callback:', :layout => 'layout'
      end
      
  end
  
  
  def medicare_soa
        Settings.record_activity
        if Settings.pin_confirmed == true
          insphere_url = Rho::RhoConfig.insphere_url
          medicare_soa_target = Rho::RhoConfig.medicare_soa_target

          rc_url ="#{insphere_url}?#{medicare_soa_target}"
       
          redirect :action => :index, :back => 'callback:', :layout => 'layout'
        
          System.open_url("#{insphere_url}#{medicare_soa_target}")
          
      else
          redirect :action => :index, :back => 'callback:', :layout => 'layout'
      end
      
  end
  
  def quoting_tool
        Settings.record_activity
        quoting_tool_url = Rho::RhoConfig.quoting_tool_url
        quoting_tool_target = Rho::RhoConfig.quoting_tool_target
        ctime = Time.new.utc
        ctime_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{ctime}Delimit"))
        user_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.login}Delimit"))
        pwd_enc = Rho::RhoSupport.url_encode(Crypto.encryptBase64("Delimit#{Settings.password}Delimit"))
                
        quoting_tool_params_enc = "UserName=#{user_enc}&pwd=#{pwd_enc}&valid=#{ctime_enc}"
     
        redirect :action => :index, :back => 'callback:', :layout => 'layout'
      
        System.open_url("#{quoting_tool_url}#{quoting_tool_target}?#{quoting_tool_params_enc}")
          
      
  end
  

  def check_for_upgrade
    latest_version = AppInfo.instance.latest_version
    min_required_version = AppInfo.instance.min_required_version
    app_version = Rho::RhoConfig.app_version
    
    puts "*** Client should be running at least version #{min_required_version} ***"
    puts "*** Client is running #{app_version} ***"
    puts "*** Latest version is #{latest_version.inspect} ***"

    puts '*** Version check -- AppInfo: ' + min_required_version + ' Curr ' + app_version + '***'
      
    # First, check if we need to force the client to upgrade
    if needs_upgrade?(min_required_version, app_version) 
      puts "*** Client needs to upgrade ***"
      RhoConnectClient.stopSync()
      RhoConnectClient.pollInterval = 0
      Alert.show_popup(
      {
        :message => "Please upgrade to version #{min_required_version}",
        :title => 'Update Required!',
        :buttons => ["OK"],
        :callback => url_for( :action => :on_dismiss_popup, :query => {:upgrade_type => 'force'} )
      } )
      
      # take the user back to the login screen, don't let them skip it in the future
      # the roundabout way of preventing the skip is to say that the initial sync has not yet occurred
      Settings.initial_sync_complete = false
      goto_login_override_auto
    elsif !latest_version.nil? && needs_upgrade?( latest_version, app_version ) && $prompted_for_upgrade == false
      $prompted_for_upgrade = true
      Alert.show_popup(
      {
        :message => "A new version (#{latest_version}) is available. Would you like to upgrade now?",
        :title => 'Update Available!',
        :buttons => ["Yes", "No"],
        :callback => url_for( :action => :on_dismiss_popup, :query => {:upgrade_type => 'soft'} )
      } )
    else
      puts "*** Client does not need to upgrade *** "
    end
  end

  def on_dismiss_popup
    id = @params['button_id']
    title = @params['button_title']
    index = @params['button_index']
    upgrade_type = @params['upgrade_type']
    
    platform = System.get_property('platform')
    
    # upgrade_type options are currently 'force' and 'soft'; code below will have to change if we add other options
    if platform == 'APPLE'
      upgrade_url = @params['upgrade_type'] == 'force' ? AppInfo.instance.apple_upgrade_url : AppInfo.instance.apple_soft_upgrade_url
    elsif platform == 'ANDROID'
      upgrade_url = @params['upgrade_type'] == 'force' ? AppInfo.instance.android_upgrade_url : AppInfo.instance.android_soft_upgrade_url
    end
    
    if ( id == 'OK' || id == 'Yes' ) # OK for force upgrade, Yes for optional upgrade
      System.open_url( upgrade_url )
    end
  end
  
  def close_app
    System.exit
  end

  def launch_upgrade_site 
    System.open_url(@params['upgrade_url'])
    render :action => :index, :back => 'callback:', :layout => 'layout'
  end

  def model_limits_exceeded?(model_name, total_count)
    puts "*** Checking limits for #{model_name} with #{total_count} total rows ***"
    result = false
    max_count = AppInfo.instance.get_model_limits[model_name] if AppInfo.instance
    if max_count && (total_count.to_i > max_count.to_i)
      puts "*** Limit #{max_count} exceeded for #{model_name} ***"
      RhoConnectClient.pollInterval = 0
      RhoConnectClient.stopSync()
      Settings.initial_sync_complete = false
      goto_login_override_auto("The maximum number of #{model_name} records that can be synced to HM Mobile is #{max_count}. Currently you have #{total_count} record(s). Please reduce this number using the Activity Center and try again. If you have questions, please contact us at hmmobile@healthmarkets.com")
      result = true
    end
    result
  end
end

  def model_limits_warning?
    result = false
    begin
      if AppApplication.activated?
        last_check_date = AppInfo.instance.get_model_limits_warning_time.blank? ? 8 : DateUtil.days_ago(AppInfo.instance.get_model_limits_warning_time)
        if last_check_date >= 1      
          opportunity_percentage = Opportunity.open_opportunities_count / AppInfo.instance.get_model_limits['Opportunity'].to_f
          contact_percentage = Contact.count / AppInfo.instance.get_model_limits['Contact'].to_f
          activity_percentage = Activity.count / AppInfo.instance.get_model_limits['Activity'].to_f 
          policy_percentage = Policy.count / AppInfo.instance.get_model_limits['Policy'].to_f
          note_percentage =  Note.count / AppInfo.instance.get_model_limits['Note'].to_f
        
          max_percentage = [opportunity_percentage, contact_percentage, activity_percentage,  policy_percentage, note_percentage].max
        
          if (max_percentage > '.02'.to_f && last_check_date >= 1) || (max_percentage > '.01'.to_f && last_check_date > 3) || (max_percentage > '.05'.to_f && last_check_date > 7)
            AppInfo.instance.set_model_limits_warning_time(DateTime.now.strftime(DateUtil::DEFAULT_TIME_FORMAT))
            result = true
          end
        end
      end
    rescue Exception => e
        puts "Unable to determine model limit warning check: #{e}"
    end
    result
  end
