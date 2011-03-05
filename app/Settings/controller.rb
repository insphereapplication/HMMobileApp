require 'rho'
require 'rho/rhocontroller'
require 'rho/rhoerror'
require 'helpers/browser_helper'

class SettingsController < Rho::RhoController
  include BrowserHelper
  #layout :layout_jquerymobile
  
  def index
    @msg = @params['msg']
    render :action => :index
  end

  def login
    @msg = @params['msg']
    render :action => :login, :back => '/app', :layout => 'layout_jquerymobile'
  end

  def login_callback
    puts @params.inspect
    errCode = @params['error_code'].to_i
    if errCode == 0
      SyncEngine.dosync
      WebView.navigate ( url_for :controller => :Contact, :action => :index )
    else
      if errCode == Rho::RhoError::ERR_CUSTOMSYNCSERVER
        @msg = @params['error_message']
      end
  
      @msg = "The user name or password you entered is not valid"    
      WebView.navigate ( url_for :action => :login, :query => {:msg => @msg} )
    end  
  end

  def do_login
    if @params['login'] and @params['password']
      begin
        SyncEngine.login(@params['login'], @params['password'], (url_for :action => :login_callback) )
        render :action => :wait
      rescue Rho::RhoError => e
        @msg = e.message
        render :action => :login
      end
    else
      @msg = Rho::RhoError.err_message(Rho::RhoError::ERR_UNATHORIZED) unless @msg && @msg.length > 0
      render :action => :login
    end
  end
  
  def logout
    SyncEngine.logout
    @msg = "You have been logged out."
    render :action => :login,
            :layout => 'layout_jquerymobile'
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
  
  def sync_notify
    # status = @params['status'] ? @params['status'] : ""
    #  if status == "ok" && @params["source_name"] == "Contact"
    #    WebView.navigate ( url_for :controller => :Contact, :action => :index )
    #  end
  end
end
