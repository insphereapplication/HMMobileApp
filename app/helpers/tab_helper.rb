module TabHelper
# All the Constants for the TAB numbering should be defined here

  $ActivitiesTAB  = 0
  $TrackersTAB    = 1
  $SettingTAB     = 2
  $DebugTAB       = 3

  def self.create_tabbar
    tabs = [
      { :label => "Activities", :action => '/app/Assessment/show_assessment', :icon => "/public/images/iphone/tabs/activities_tab_icon.png", :reload => false }, 
      { :label => "Trackers",  :action => '/app/Trackers/',  :icon => "/public/images/iphone/tabs/trackers_tab_icon.png", :reload => false },
      { :label => "Settings",  :action => '/app/Settings/',  :icon => "/public/images/iphone/tabs/settings_tab_icon.png", :reload => false },
      { :label => "DEBUG!",  :action => '/app/Debug/',  :icon => "/public/images/iphone/tabs/pig_tab_icon.png", :reload => false }
    ]

    Rho::NativeTabbar.create(tabs) unless ( System::get_property('platform') == 'Blackberry' || (System::get_property('platform') == 'ANDROID' && $useHTMLTabbarDroid) ) 
    WebView.navigate('/app/Assessment/show_assessment', $ActivitiesTAB) unless ( System::get_property('platform') == 'Blackberry' || (System::get_property('platform') == 'ANDROID' && $useHTMLTabbarDroid) )

    $tabbarDisabled = false
  end
  
  def self.remove_tabbar
    Rho::NativeTabbar.remove unless ( System::get_property('platform') == 'Blackberry' || (System::get_property('platform') == 'ANDROID' && $useHTMLTabbarDroid ))
  end
  
  def self.switch_tab(tab)
    Rho::NativeTabbar.switch_tab(tab) unless ( System::get_property('platform') == 'Blackberry' || (System::get_property('platform') == 'ANDROID'  && $useHTMLTabbarDroid))
  end
end