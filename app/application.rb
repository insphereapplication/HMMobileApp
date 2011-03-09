require 'rho/rhoapplication'
require 'rho/rhotabbar'
require 'initializers/enumerable_extension'
require 'initializers/rhom_sti_extension'
# ['activity/phone_call', 'activity/appointment'].each {|model| require model}

# Dir[File.join(File.dirname(__FILE__),'initializers','**','*.rb')].each { |file| require file }

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

    # Uncomment to set sync notification callback to /app/Settings/sync_notify.
    # SyncEngine.set_notification(-1, "/app/Settings/sync_notify", '')
    #     System.set_push_notification("/app/Settings/push_notify", '')
    # SyncEngine.set_objectnotify_url(
    #   url_for(
    #     :controller => "Opportunity",
    #     :action => :sync_object_notify
    #   )
    # )
    
  end
end
