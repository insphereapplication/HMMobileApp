require 'rho/rhoapplication'
require 'rho/rhotabbar'

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
    
    #To remove default toolbar uncomment next line:
    #@@toolbar = nil
    super

    # Uncomment to set sync notification callback to /app/Settings/sync_notify.
    SyncEngine::set_objectnotify_url("/app/Settings/sync_notify")
    SyncEngine.set_notification(-1, "/app/Settings/sync_notify", '')
  end
end
