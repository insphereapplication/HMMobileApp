class AppInfo
  include Rhom::PropertyBag
  
  enable :sync
  set :sync_priority, 1
  
  property :min_required_version, :string
  property :latest_version, :string
  property :policy_pin, :string
  
  # Force upgrade URLs, named to maintain backward compatibility with older clients
  property :apple_upgrade_url, :string2
  property :android_upgrade_url, :string
  
  property :apple_soft_upgrade_url, :string
  property :android_soft_upgrade_url, :string
  
  property :mobile_crypt_key, :string

  property :model_limits, :string
  
  property :quick_quote_users, :string
  
  property :background_sync_time, :string
  
  property :model_limits_last_checked_time, :string
  
  property :model_limits_warning_time, :string

  def self.instance
    AppInfo.find(:all).first
  end
  
  def set_pin(value)
    self.update_attributes({"policy_pin" => value})
     Rho::RhoConnectClient.doSync
  end
  
  def set_background_sync_time(value)
    self.update_attributes({"background_sync_time" => value})
     Rho::RhoConnectClient.doSync
  end

  def get_background_sync_time
    default_sync_time = System::get_property('platform') == 'APPLE' ? 'off' : '15'
	 background_sync_time.blank? ? default_sync_time : background_sync_time
  end
  
  def get_model_limits
    #limits should come from server but get out a sync every now so adding default set
    model_limits.blank? ?  {"Activity" => 2999 ,"Opportunity" => 499, "Contact" => 3499, "Policy" => 7499, "Note" => 1749} : Rho::JSON.parse(model_limits)
  end
  
  def get_model_limits_warning_time
     model_limits_warning_time.blank? ? '' : model_limits_warning_time
  end
  
  def set_model_limits_warning_time(value)
    self.update_attributes({"model_limits_warning_time" => value})
        Rho::RhoConnectClient.doSync
  end
  
end
