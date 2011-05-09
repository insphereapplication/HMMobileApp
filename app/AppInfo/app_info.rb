class AppInfo
  include Rhom::FixedSchema
  
  enable :sync
  set :sync_priority, 1
  
  property :min_required_version, :string
  property :apple_upgrade_url, :string
  property :android_upgrade_url, :string
  
  def self.instance
    AppInfo.find_by_sql("select * from AppInfo limit 1")
  end
end