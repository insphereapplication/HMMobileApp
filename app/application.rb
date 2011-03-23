require 'rho/rhoapplication'
require 'rho/rhotabbar'
require 'utils/util'
require 'initializers/extensions'



class AppApplication < Rho::RhoApplication
  def initialize
    # Tab items are loaded left->right, @tabs[0] is leftmost tab in the tab-bar
    # Super must be called *after* settings @tabs!
      @tabs = [
                { :label => "Opps", :action => '/app/Opportunity', 
                  :icon => "/public/images/iphone/tabs/pib_tab_icon.png", :web_bkg_color => 0x7F7F7F }, 
                { :label => "Contacts",  :action => '/app/Contact',  
                  :icon => "/public/images/iphone/tabs/activities_tab_icon.png" },
                { :label => "Settings",  :action => '/app/Settings',  
                  :icon => "/public/images/iphone/tabs/settings_tab_icon.png", :reload => true },
              ]
    # Important to call super _after_ you define @tabs!
    super
    System.set_push_notification("/app/Settings/push_notify", '')

    $opportunity_nav_context = []

  end
  
  #wipe the database and force a resync if a different user logs in
  def on_sync_user_changed
    super
    Rhom::Rhom.database_local_reset
  end
  
  # always force a login at startup. Will be automatic if user has successfully logged in before (see: Settings/controller.login)
  def on_activate_app
    SyncEngine.logout
  end 
  
  
end
