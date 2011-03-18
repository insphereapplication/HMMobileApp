require 'rho/rhoapplication'
require 'rho/rhotabbar'
require 'initializers/extensions'
require 'utils/util'


class AppApplication < Rho::RhoApplication
  def initialize
    # Tab items are loaded left->right, @tabs[0] is leftmost tab in the tab-bar
    # Super must be called *after* settings @tabs!
    @tabs = [
          { :label => "Opps", :action => '/app/Opportunity', 
            :icon => "/public/images/iphone/tabs/pib_tab_icon.png", :reload => true, :web_bkg_color => 0x7F7F7F }, 
          { :label => "Contacts",  :action => '/app/Contact',  
            :icon => "/public/images/iphone/tabs/activities_tab_icon.png" },
          { :label => "Settings",  :action => '/app/Settings',  
            :icon => "/public/images/iphone/tabs/settings_tab_icon.png" },
        ]
    # Important to call super _after_ you define @tabs!
    super
    
    if SyncEngine::logged_in == 1
      render :action => :index
      SyncEngine.dosync
    else
      render :action => :login
    end
  end
  
  # wipe the database and force a resync if a different user logs in
  def on_sync_user_changed
    super
    Rhom::Rhom.database_local_reset
  end
  
end
