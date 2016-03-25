class AppInfo
  include Rhom::PropertyBag
  
  enable :sync
  set :sync_priority, 1
  
  property :min_required_version, :string
  property :latest_version, :string
  property :policy_pin, :string
  
  # Force upgrade URLs, named to maintain backward compatability with older clients
  property :apple_upgrade_url, :string
  property :android_upgrade_url, :string
  
  property :apple_soft_upgrade_url, :string
  property :android_soft_upgrade_url, :string
  
  property :mobile_crypt_key, :string

  property :model_limits, :string
  
  property :quick_quote_users, :string

  def self.instance
    AppInfo.find(:all).first
  end
  
  def set_pin(value)
    self.update_attributes({"policy_pin" => value})
     Rho::RhoConnectClient.doSync
  end

  def get_model_limits
    model_limits.blank? ? {} : Rho::JSON.parse(model_limits)
  end
end
