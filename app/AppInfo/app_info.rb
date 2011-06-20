class AppInfo
  include Rhom::PropertyBag
  
  enable :sync
  set :sync_priority, 1
  
  property :min_required_version, :string
  property :latest_version, :string
  
  # Force upgrade URLs, named to maintain backward compatability with older clients
  property :apple_upgrade_url, :string
  property :android_upgrade_url, :string
  
  property :apple_soft_upgrade_url, :string
  property :android_soft_upgrade_url, :string
  
  def self.instance
    AppInfo.find(:all).first
  end
end