require 'rho/rhoapplication'
require 'rho/rhotabbar'
require 'utils/util'
require 'initializers/extensions'
require 'lib/libs'
require 'Contact/contact_controller'
require 'Activity/activity_controller'

class AppApplication < Rho::RhoApplication
  def initialize
    puts "calling App Initialize"
    @@toolbar = nil
    super
    @default_menu = { 
      "Close" => :close, 
      "View Log" => :log 
    }

    SyncEngine.set_notification(-1, "/app/Settings/sync_notify", '') 
    System.set_push_notification("/app/Settings/push_notify", '')
    SyncEngine.set_pollinterval(0) if System::get_property('platform') == 'ANDROID'
    $app_activated = ""
  end
  
  #wipe the database and force a resync if a different user logs in
  def on_sync_user_changed
    super
    Rhom::Rhom.database_full_reset
  end
  
  def on_activate_app
      puts "calling on_activate_app"
      SyncEngine.dosync if (!$app_activated.blank? && !SyncEngine.is_syncing && Settings.last_synced && !Settings.last_synced.blank? && Time.new - Settings.last_synced > 60)
      SyncEngine.set_pollinterval(Constants::DEFAULT_POLL_INTERVAL)
      $app_activated = "true"
      puts "In app active: #{$app_activated}"
      WebView.execute_js("setAppActive();")
  end
  
  def on_deactivate_app
      # Don't call any UI operations here, they'll be ignored
      # For example, WebView.refresh
  
      # poll once an hour on android devices when the app is backgrounded
      puts "calling on_deactivate_app"
      SyncEngine.set_pollinterval(0) if System::get_property('platform') == 'ANDROID'
      $app_activated = "false"
      puts "In app decactive: #{$app_activated}"
      WebView.execute_js("setAppDeactive();") 

      # To stop local web server when application switched to 
      # background return "stop_local_server"
      #return "stop_local_server" 
  end
  
  def self.activated?
    $app_activated == "true"
  end
  
  def on_ui_created
    puts "calling ui_created!!!"
    #  Remove first render and adding to Activity and Contact 
    #Reset the first render flags to true for activity and contact pages
    #ContactController.reset_first_render
    #ActivityController.reset_first_render
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

  
  
  

end
