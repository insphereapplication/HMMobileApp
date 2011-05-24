require 'rho'
require 'rho/rhocontroller'
require 'rho/rhoerror'
require 'helpers/browser_helper'
require 'rho/rhotabbar'

class SettingsController < Rho::RhoController
  include BrowserHelper
  
  def index
    $tab = 2
    @msg = @params['msg']
    render :controller => :Setting, :back => 'callback:', :action => :index, :layout => 'layout_jquerymobile'
  end
  
  def can_skip_login?
    Settings.has_verified_credentials? and Settings.initial_sync_completed?
  end
  
  def init
    if can_skip_login?
      #login & sync in background
      SyncEngine.login(Settings.login, Settings.password,  '/app/Settings/retry_login_callback')
      #go to opportunity index page
      goto_opportunity_init_notify
    else
      #go to login screen
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
  
  def connection_status
    System.has_network ? 'Online' : 'Offline'
  end
  
  def get_connection_status
    @connection_status = connection_status
    render :action => :get_connection_status, :back => 'callback:', :layout => false
  end
  
  def detailed_logging_enabled?
    RhoConf.get_property_by_name('MinSeverity') == '1'
  end
  
  def login
    @msg = @params['msg']
    override_auto_login = @params['override_auto_login']
    # if the user has stored successful login credentials, attempt to auto-login with them
    if Settings.has_verified_credentials? and override_auto_login.to_s != 'true'
      update_login_wait_progress("Logging in with cached credentials")
      SyncEngine.login(Settings.login, Settings.password, "/app/Settings/login_callback")
      @working = true # if @working is true, page will show spinner
    end
    
    Rho::NativeTabbar.remove
    @menu = { "Log" => :log }
    render :action => :login, :back => '/app/Settings/login', :layout => 'layout_jquerymobile'
  end
  
  def goto_login(msg=nil)
    WebView.navigate ( url_for :action => :login, :query => {:msg => msg} )
  end
  
  def goto_login_override_auto(msg=nil)
    WebView.navigate ( url_for :action => :login, :query => {:msg => msg, :override_auto_login => true} )
  end
  
  def retry_login
    # if the user has stored successful login credentials, attempt to auto-login with them
    if Settings.has_verified_credentials?
      SyncEngine.login(Settings.login, Settings.password,  '/app/Settings/retry_login_callback')
    else
      goto_login
    end
  end

  def login_callback
    errCode = @params['error_code'].to_i
    httpErrCode = @params['error_message'].split[0]

    if errCode == 0
      
      #setup the sync event handlers for the application init sequence
      set_sync_type('init')
      
      Settings.credentials_verified = true
      SyncEngine.set_pollinterval(Constants::DEFAULT_POLL_INTERVAL)
      SyncEngine.dosync
      update_login_wait_progress("Login successful, starting sync...")
    elsif errCode == Rho::RhoError::ERR_NETWORK && can_skip_login?
      #DO NOT send connectivity errors to exceptional, causes infinite loop at the moment (leave ':send_to_exceptional => false' alone)
      log_error("Verified credentials, but no network.","",{:send_to_exceptional => false})
      #we've got cached, verified credentials, so proceed with the usual initialization process
      SyncEngine.set_pollinterval(Constants::DEFAULT_POLL_INTERVAL)
      goto_opportunity_init_notify
    else
      Settings.clear_credentials
      SyncEngine.set_pollinterval(0)
      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
      
      if httpErrCode == "403" # User is not authorized to use the mobile device, so we need to purge the local database
        @msg ||= "Sorry! The Insphere InSIte Mobile application is only available for download for authorized pilot users.  More to come regarding the Insphere InSite Mobile Program and roll-out schedule in July."
        Rhom::Rhom.database_fullclient_reset_and_logout
      else
        @msg ||= "The user name or password you entered is not valid"    
      end
      
      goto_login(@msg)
    end
  end
  
  def retry_login_callback
    errCode = @params['error_code'].to_i
    httpErrCode = @params['error_message'].split[0]
    
    if errCode == 0
      SyncEngine.set_pollinterval(Constants::DEFAULT_POLL_INTERVAL)
      SyncEngine.dosync
    elsif errCode == Rho::RhoError::ERR_NETWORK && can_skip_login?
      #DO NOT send connectivity errors to exceptional, causes infinite loop at the moment (leave ':send_to_exceptional => false' alone)
      log_error("Verified credentials, but no network.","",{:send_to_exceptional => false})
      #at this point, we've got cached, verified credentials but we can't connect to RhoSync. 
      #don't throw an error, but reinstate poll interval so that we continue to check for connectivity
      SyncEngine.set_pollinterval(Constants::DEFAULT_POLL_INTERVAL)   
    else
      Settings.clear_credentials
      SyncEngine.set_pollinterval(0)
      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
      
      if httpErrCode == "403" # User is not authorized to use the mobile device, so we need to purge the local database
        @msg ||= "Sorry! The Insphere InSite Mobile application is only available for download for authorized pilot users.  More to come regarding the Insphere InSite Mobile Program and roll-out schedule in July."
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
        SyncEngine.login(Settings.login, Settings.password, (url_for :action => :login_callback) )
        update_login_wait_progress("Logging in...")
      rescue Rho::RhoError => e
        Settings.clear_credentials
        @msg = e.message
        render :action => :login, :back => 'callback:', :layout => 'layout_jquerymobile'
      end
    else
      Settings.clear_credentials
      @msg = Rho::RhoError.err_message(Rho::RhoError::ERR_UNATHORIZED) unless @msg && @msg.length > 0
      render :action => :login, :back => 'callback:', :layout => 'layout_jquerymobile'
    end
  end
  
  def do_logout
    Settings.clear_credentials
    SyncEngine.set_pollinterval(0)
    Settings.flush_instance
    
    Rho::NativeTabbar.remove
    @msg = "You have been logged out."
    goto_login(@msg)
  end
  
  def reset
    render :action => :reset, :back => 'callback:'
  end
  
  def about
    render :action => :about, :back => 'callback:'
  end
  
  def do_reset
    Rhom::Rhom.database_fullclient_reset_and_logout
    Settings.flush_instance
    SyncEngine.set_pollinterval(0)
    @msg = "Database has been reset."
    redirect :action => :index, :back => 'callback:', :query => {:msg => @msg}
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
    SyncEngine.dosync
    @msg =  "Sync has been triggered."
    redirect :action => :index, :back => 'callback:', :query => {:msg => @msg}
  end
  
  def on_dismiss_notify_popup
    if @params['button_id'] == 'View'
      Opportunity.set_notification(
        url_for(:controller => :Opportunity, :action => :sync_notify),
        "sync_complete=true"
      )
      SyncEngine.dosync
    end
  end
  
  def push_notify
    Alert.vibrate(2000)

    Alert.show_popup({
      :message => "You have new Opportunities", 
      :title => 'New Opportunities', 
      :buttons => ["Cancel", "View"],
      :callback => url_for(:action => :on_dismiss_notify_popup) 
    })
    if System::get_property('platform') == 'ANDROID'
      "rho_push"
    else
      ""
    end
  end
  
  # this is the message returned from RhoSync when Rhodes is sending a token for a session that no longer exists (like after a Redis reset) 
  SESSION_ERROR_MSG = "undefined method `user_id' for nil:NilClass"
  
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
      if sourcename == 'AppInfo'
        check_force_upgrade
      end   
      @on_sync_complete.call
    elsif status == "ok"
      if sourcename == 'AppInfo'
        check_force_upgrade
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
          SyncEngine.on_sync_create_error( @params['source_name'], @params['server_errors']['create-error'], :recreate)
        else
          #notify the user here?
          #the create data given to the proxy was bad and will not succeed if tried again; delete the create
          SyncEngine.on_sync_create_error( @params['source_name'], @params['server_errors']['create-error'], :delete)
        end
      end
      
      if @params['server_errors'] && @params['server_errors']['update-error']
        log_error("Update error", @params.inspect)
        unless is_bad_request_data
          SyncEngine.on_sync_update_error( @params['source_name'], @params['server_errors']['update-error'], :retry)
        else
          #notify the user here?
          #we need to roll back the change that was made here, but the Rhodes API doesn't provide a mechanism to do this
        end
      end

      @msg = rho_error.message unless @msg and @msg.length > 0   
      
      if (@params['error_message'].downcase == 'unknown client') or rho_error.unknown_client?(@params['error_message'])
        log_error("Error: Unknown client", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        
        SyncEngine.set_pollinterval(0)
        SyncEngine.stop_sync
        
        full_reset_logout_keep_credentials
        
        goto_login("Unknown client, logging in again.")
      elsif err_code == Rho::RhoError::ERR_NETWORK
        #leave ':send_to_exceptional => false' alone until infinite loop issue is fixed for clients without a network connection
        log_error("Network connectivity lost", Rho::RhoError.err_message(err_code) + " #{@params.inspect}", {:send_to_exceptional => false})
        
        #stop current sync, otherwise do nothing for connectivity lapse
        SyncEngine.stop_sync
        
        #send them back to login because initial sync did not complete
        @on_sync_error.call({:error_source => 'connection'})
      elsif [Rho::RhoError::ERR_CLIENTISNOTLOGGEDIN,Rho::RhoError::ERR_UNATHORIZED].include?(err_code)      
        log_error("RhoSync error: client is not logged in / unauthorized", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        SyncEngine.set_pollinterval(0)
        SyncEngine.stop_sync
        retry_login
      elsif err_code == Rho::RhoError::ERR_REMOTESERVER && @params['error_message'] == SESSION_ERROR_MSG
        # Rhodes is sending the server a token for a non-existent session. Time to start over.
        log_error("RhoSync error: unknown session", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        
        SyncEngine.set_pollinterval(0)
        SyncEngine.stop_sync
                
        full_reset_logout
        
        goto_login("Unknown session, please log in again.")
      elsif err_code == Rho::RhoError::ERR_CUSTOMSYNCSERVER && !@params['server_errors'].to_s[/401 Unauthorized/].nil?
        #proxy returned a 401, need to re-login
        log_error("Error: 401 Unauthorized from proxy", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        SyncEngine.set_pollinterval(0)
        SyncEngine.stop_sync
        retry_login
      elsif err_code == Rho::RhoError::ERR_CUSTOMSYNCSERVER && !@params['server_errors'].to_s[/403 Forbidden/].nil?
        #proxy returned a 403, need to purge the database and log the user out
        log_error("Error: 403 Forbidden from proxy", Rho::RhoError.err_message(err_code) + " #{@params.inspect}")
        SyncEngine.set_pollinterval(0)
        SyncEngine.stop_sync
        
        full_reset_logout
        
        msg = "Sorry! The Insphere InSite Mobile application is only available for download for authorized pilot users.  More to come regarding the Insphere InSite Mobile Program and roll-out schedule in July."
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
    WebView.execute_js('update_wait_progress("'+text+'");')
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
    WebView.navigate ( url_for :action => :index )
  end

  def goto_opportunity_init_notify
    WebView.navigate ( url_for :controller => :Opportunity, :action => :init_notify)
  end
  
  def setup_sync_handlers
    if Settings.is_init_sync?
      set_init_sync_handlers
    else
      set_background_sync_handlers
    end
  end
  
  def set_sync_type(type)
    # show_popup("Setting sync type to #{type}", "")
    Settings.sync_type = type
    setup_sync_handlers
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
  
  def init_on_sync_error(*args)
    raise ArgumentError, "Hash must be given as the first argument" unless args[0].is_a?(Hash)    
    
    error_source = args[0][:error_source]
    
    if Settings.initial_sync_completed?
      #if it's a connection based error, 
      if error_source == 'connection'
        #swallow this error, let the user through
        #navigate to opportunity init_notify controller action
        goto_opportunity_init_notify
      end
    else
      #TODO: determine if database reset is needed here
      #we haven't successfully synced before, so navigate back to the login screen (but keep the credentials)
      SyncEngine.stop_sync
      goto_login_override_auto("Sync error. Please try logging in again.")
    end
  end
  
  def init_on_sync_complete(*args)
    #change sync handlers back to default
    set_sync_type('background')
    
    Settings.initial_sync_complete = true
    
    #navigate to opportunity init_notify controller action
    goto_opportunity_init_notify
  end
  
  def init_on_sync_in_progress(*args)
    percent = (@params["cumulative_count"].to_f/@params["total_count"].to_f * 100).to_i
    update_login_sync_progress(@params['source_name'], percent)
  end
  
  def init_on_sync_ok(*args)
    update_login_sync_progress(@params['source_name'], 100)
  end
  
  def needs_upgrade?(min_version, current_version) # returns true if current_version is less than min_version
    # comparison is lexicographical, as in it reads from left to right and only proceeds to the 
    # next sub-version if a given sub-version in min_version and current_version is equal
    min_version_split = min_version.split(".")
    current_version_split = current_version.split(".")
    
    puts "****Version check: min version = #{min_version_split}, current version = #{current_version_split}****"
    
    # compare sub-versions from left to right
    # if current_version has fewer version numbers than min_version, assume '0' for missing version numbers to the right 
    (0...min_version_split.count).each do |i|
      if min_version_split[i] > (current_version_split[i] || '0')
        # current_version must be older, no need to continue checking
        return true
      elsif min_version_split[i] < (current_version_split[i] || '0')
        # current_version must be newer, no need to continue checking
        return false
      end
    end
    
    # given versions are equal
    return false
  end
  

  def check_force_upgrade
    min_required_version = AppInfo.instance[0].min_required_version
    apple_upgrade_url = AppInfo.instance[0].apple_upgrade_url
    android_upgrade_url = AppInfo.instance[0].android_upgrade_url
    app_version = Rho::RhoConfig.app_version
    
    puts "*** Client should be running at least version #{min_required_version} ***"
    puts "*** Client is running #{app_version} ***"
    puts "*** Apple Upgrade URL is #{apple_upgrade_url} ***"
    puts "*** Android Upgrade URL is #{android_upgrade_url} ***"

    puts '*** Version check -- AppInfo: ' + min_required_version + ' Curr ' + app_version + '***'
      
    if needs_upgrade?(min_required_version, app_version) 
      puts "*** Client needs to upgrade ***"
      SyncEngine.stop_sync
      SyncEngine.set_pollinterval(0)
      Alert.show_popup(
      {
        :message => "Please upgrade to version #{min_required_version}",
        :title => 'Update Required!',
        :buttons => ["OK"],
        :callback => url_for( :action => :on_dismiss_popup )
      } )
      
      # take the user back to the login screen, don't let them skip it in the future
      # the roundabout way of preventing the skip is to say that the initial sync has not yet occurred
      Settings.initial_sync_complete = false
      goto_login_override_auto
    else
      puts "*** Client does not need to upgrade *** "
    end
  end
  
  def on_dismiss_popup
    id = @params[:button_id]
    title = @params[:button_title]
    index = @params[:button_index]
    
    platform = System.get_property('platform')
    
    if platform == 'APPLE'
      upgrade_url = AppInfo.instance[0].apple_upgrade_url
    elsif platform == 'ANDROID'
      upgrade_url = AppInfo.instance[0].android_upgrade_url
    end
    
    puts "*** Upgrade url = #{upgrade_url} ***"
    
    System.open_url( upgrade_url )
    System.exit
  end
  
  def close_app
    System.exit
  end

end
