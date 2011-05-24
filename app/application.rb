require 'rho/rhoapplication'
require 'rho/rhotabbar'
require 'utils/util'
require 'initializers/extensions'
require 'lib/libs'

class AppApplication < Rho::RhoApplication
  def initialize
    @@toolbar = nil
    super
    @default_menu = { 
      "Close" => :close, 
      "View Log" => :log 
    }
    
    SyncEngine.set_ssl_verify_peer(false)
    SyncEngine.set_notification(-1, "/app/Settings/sync_notify", '') 
  end
  
  #wipe the database and force a resync if a different user logs in
  def on_sync_user_changed
    super
    Rhom::Rhom.database_full_reset
  end
  
  def on_activate_app
      # put your application activation code here
      SyncEngine.set_pollinterval(Constants::DEFAULT_POLL_INTERVAL)
  end
  
  def on_deactivate_app
      # Don't call any UI operations here, they'll be ignored
      # For example, WebView.refresh
  
      # to increase sync polling interval 
      SyncEngine.stop_sync
      SyncEngine.set_pollinterval(0)
  
      # To stop local web server when application switched to 
      # background return "stop_local_server"
      # return "stop_local_server" 
  end
  
  def on_ui_created
    puts "calling ui_created!!!"
    $first_render = true
    # put your application UI creation code here
    # for example, create tab bar:
    # NativeBar.create(Rho::RhoApplication::TABBAR_TYPE, tabs)
    super
  end
  
  def on_ui_destroyed
    puts "calling ui_destroyed!"
      # put your code here
      # example:
      # @forbid_ui_operations = true
  end

  def on_migrate_source(old_version, new_src)
    puts "*!*!*!*!*!*! PERFORMING ON_MIGRATE_SOURCE !*!*!*!*!*!*!*!*!*"
    puts "*!*!*!*!*!*! OLD VERSION IS: #{old_version} !*!*!*!*!*!*!*!*!*"
    puts "*!*!*!*!*!*! new_src IS: #{new_src} !*!*!*!*!*!*!*!*!*"
    Alert.show_popup({
      :title => "ON_MIGRATE_SOURCE",
      :message => "old version is #{old_version}; NEW VERSION IS: #{new_src}",
      :buttons => ["OK"]
    })
    # ... do something like alert user ...
    super
  end  
  
  
  

end
