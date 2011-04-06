require 'rho'
require 'rho/rhocontroller'
require 'rho/rhoerror'
require 'helpers/browser_helper'
require 'rho/rhotabbar'

#if user is logged in, poll interval in seconds
$poll_interval = 60

class SettingsController < Rho::RhoController
  include BrowserHelper
  
  def index
    @msg = @params['msg']
    render :controller => :Setting, :action => :index, :layout => 'layout_jquerymobile'
  end

  def login(callback="/app/Settings/login_callback")
    @msg = @params['msg']
    # if the user has stored successful login credentials, attempt to auto-login with them
    if Settings.has_persisted_credentials?
      SyncEngine.login(Settings.login, Settings.password,  callback)
      @working = true # if @working is true, page will show spinner
    end
    
    Rho::NativeTabbar.remove
    render :action => :login, :back => '/app', :layout => 'layout_jquerymobile'
  end

  def login_callback
    errCode = @params['error_code'].to_i
    if errCode == 0
      
      # set initial sync notification for OpportunityController#init_notify, which will redirect WebView to OpportunityController#index
      Opportunity.set_notification(
        url_for(:controller => :Opportunity, :action => :init_notify),
        "sync_complete=true"
      )
      SyncEngine.set_pollinterval($poll_interval)
      SyncEngine.dosync

    else
      Settings.clear_credentials
      SyncEngine.set_pollinterval(0)
      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
  
      @msg ||= "The user name or password you entered is not valid"    
      WebView.navigate ( url_for :action => :login, :query => {:msg => @msg} )
    end  
  end
  
  def retry_login_callback
    errCode = @params['error_code'].to_i
    if errCode == 0
      SyncEngine.set_pollinterval($poll_interval)
      SyncEngine.dosync
    else
      Settings.clear_credentials
      SyncEngine.set_pollinterval(0)
      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
  
      @msg ||= "The user name or password you entered is not valid"    
      WebView.navigate ( url_for :action => :login, :query => {:msg => @msg} )
    end
  end

  def do_login
    Settings.login = @params['login'].downcase unless @params['login'].blank?
    Settings.password = @params['password'] unless @params['password'].blank?
    
    if Settings.login and Settings.password
      begin
        SyncEngine.login(Settings.login, Settings.password, (url_for :action => :login_callback) )
      rescue Rho::RhoError => e
        Settings.clear_credentials
        @msg = e.message
        render :action => :login, :layout => 'layout_jquerymobile'
      end
    else
      Settings.clear_credentials
      @msg = Rho::RhoError.err_message(Rho::RhoError::ERR_UNATHORIZED) unless @msg && @msg.length > 0
      render :action => :login, :layout => 'layout_jquerymobile'
    end
  end
  
  def do_logout
    Rhom::Rhom.database_full_reset_and_logout
    Settings.clear_credentials
    SyncEngine.set_pollinterval(-1)
    Rho::NativeTabbar.remove
    @msg = "You have been logged out."
    render :action => :login, :layout => 'layout_jquerymobile'
  end
  
  def reset
    render :action => :reset
  end
  
  def do_reset
    Rhom::Rhom.database_fullclient_reset_and_logout
    Settings.clear_credentials
    SyncEngine.set_pollinterval(-1)
    @msg = "Database has been reset."
    redirect :action => :index, :query => {:msg => @msg}
  end
  
  def do_sync
    SyncEngine.dosync
    @msg =  "Sync has been triggered."
    redirect :action => :index, :query => {:msg => @msg}
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
    ""
  end
  
  # this is the message returned from RhoSync when Rhodes is sending a token for a session that no longer exists (like after a Redis reset) 
  SESSION_ERROR_MSG = "undefined method `user_id' for nil:NilClass"
  
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
    status = @params['status'] ? @params['status'] : ""
    
    if status == "complete" or status == "ok"
      if @params['source_name'] && @params['cumulative_count'] && @params['cumulative_count'].to_i > 0
        klass = Object.const_get(@params['source_name'].capitalize)
        klass.local_changed=true if klass && klass.respond_to?(:local_changed=)
      end
    elsif status == "error"
      
      if @params['server_errors'] && @params['server_errors']['create-error']
        SyncEngine.on_sync_create_error( @params['source_name'], @params['server_errors']['create-error'].keys(), :recreate)
      end

      err_code = @params['error_code'].to_i
      rho_error = Rho::RhoError.new(err_code)

      @msg = rho_error.message unless @msg and @msg.length > 0   

      if (@params['error_message'].downcase == 'unknown client') or rho_error.unknown_client?(@params['error_message'])
        Alert.show_popup({
            :message => Rho::RhoError.err_message(err_code) + " #{@params.inspect}", 
            :title => "Unknown client", 
            :buttons => ["OK"]
          })
        Rhom::Rhom.database_fullclient_reset_and_logout
        render :action => :login, :layout => 'layout_jquerymobile'
      elsif err_code == Rho::RhoError::ERR_NETWORK
        # do nothing for connectivity lapse
      elsif [Rho::RhoError::ERR_CLIENTISNOTLOGGEDIN,Rho::RhoError::ERR_UNATHORIZED].include?(err_code)      
        SyncEngine.set_pollinterval(-1)
        SyncEngine.stop_sync
        login("/app/Settings/retry_login_callback")    
      elsif err_code == Rho::RhoError::ERR_REMOTESERVER && @params['error_message'] == SESSION_ERROR_MSG
        # Rhodes is sending the server a token for a non-existent session. Time to start over.
        Rhom::Rhom.database_fullclient_reset_and_logout
        SyncEngine.set_pollinterval(-1)
        SyncEngine.stop_sync
        login("/app/Settings/retry_login_callback")
      elsif err_code == Rho::RhoError::ERR_CUSTOMSYNCSERVER && !@params['server_errors'].to_s[/401 Unauthorized/].nil?
        #proxy returned a 401, need to re-login
        SyncEngine.set_pollinterval(-1)
        SyncEngine.stop_sync
        login("/app/Settings/retry_login_callback")
      else
         Alert.show_popup({
          :message => Rho::RhoError.err_message(err_code) + " #{@params.inspect}", 
          :title => "Error: #{err_code}", 
          :buttons => ["OK"]
        })
      end
    end
  end
  
  def show_log
    Rho::RhoConfig.show_log
  end
  
  def test_exception
    raise "bang"
  rescue Exception => e
    ExceptionUtil.log_exception_to_server(e)
    WebView.navigate ( url_for :action => :index )
  end
  
end
