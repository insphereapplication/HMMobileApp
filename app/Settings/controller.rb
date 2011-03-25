require 'rho'
require 'rho/rhocontroller'
require 'rho/rhoerror'
require 'helpers/browser_helper'
require 'rho/rhotabbar'

class SettingsController < Rho::RhoController
  include BrowserHelper
  
  def index
    @msg = @params['msg']
    render :controller => :Setting, :action => :index, :layout => 'layout_jquerymobile'
  end

  def login
    @msg = @params['msg']
    # if the user has stored successful login credentials, attempt to auto-login with them
    if Settings.has_persisted_credentials?
      SyncEngine.login(Settings.login, Settings.password,  "/app/Settings/login_callback")
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
   
      set_tabbar 
      SyncEngine.dosync
      #create tabbar
    else
      Settings.clear_credentials

      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
  
      @msg ||= "The user name or password you entered is not valid"    
      WebView.navigate ( url_for :action => :login, :query => {:msg => @msg} )
    end  
  end
  
  
  def set_tabbar
    tabbar = [
      { :label => "Opps", :action => '/app/Opportunity', 
        :icon => "/public/images/iphone/tabs/pib_tab_icon.png", :web_bkg_color => 0x7F7F7F }, 
      { :label => "Contacts",  :action => '/app/Contact',  
        :icon => "/public/images/iphone/tabs/activities_tab_icon.png" },
      { :label => "Settings",  :action => '/app/Settings',  
        :icon => "/public/images/iphone/tabs/settings_tab_icon.png", :reload => true },
    ]
    Rho::NativeTabbar.create(tabbar)
    $tabbar_active = true
    # Rho::NativeTabbar.switch_tab(0)
  end

  def do_login
    
    Settings.login = @params['login'] unless @params['login'].blank?
    Settings.password = @params['password'] unless @params['password'].blank?
    
    if Settings.login and Settings.password
      begin
        SyncEngine.login(Settings.login, Settings.password, (url_for :action => :login_callback) )
        render :action => :wait
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
  
  def logout
    SyncEngine.logout
    Settings.clear_credentials
    @msg = "You have been logged out."
    render :action => :login, :layout => 'layout_jquerymobile'
  end
  
  def reset
    render :action => :reset
  end
  
  def do_reset
    Rhom::Rhom.database_full_reset
    SyncEngine.dosync
    @msg = "Database has been reset."
    redirect :action => :index, :query => {:msg => @msg}
  end
  
  def do_sync
    SyncEngine.dosync
    @msg =  "Sync has been triggered."
    redirect :action => :index, :query => {:msg => @msg}
  end
  
  def push_notify
    SyncEngine.sync
  end
   
  def sync_notify
    status = @params['status'] ? @params['status'] : ""
    
    if status == "complete" or status == "ok"
      # WebView.refresh
    elsif status == "error"
      if @params['server_errors'] && @params['server_errors']['create-error']
          SyncEngine.on_sync_create_error( @params['source_name'], @params['server_errors']['create-error'].keys(), :delete)
      end

      err_code = @params['error_code'].to_i
      rho_error = Rho::RhoError.new(err_code)

      if err_code == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end

      @msg = rho_error.message unless @msg and @msg.length > 0   

      if rho_error.unknown_client?(@params['error_message'])
        Rhom::Rhom.database_client_reset
        SyncEngine.dosync

      elsif err_code == Rho::RhoError::ERR_UNATHORIZED
        WebView.navigate( 
          url_for(
            :action => :login, 
            :query => { :msg => "Server credentials expired!" } 
          )
        )                
      else
        WebView.navigate( 
          url_for(
            :action => :err_sync, 
            :query => { :msg => @msg } 
          )
        )
      end    
    end
  end
end
