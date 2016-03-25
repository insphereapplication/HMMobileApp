class SyncUtil
  class << self
    def set_sync_type(type)
	  puts "setting the sync_type #{type}"
      Settings.sync_type = type
    end
    
    def start_sync(sync_type = nil)
      set_sync_type(sync_type) if sync_type
	  Rho::RhoConnectClient.doSync()
    end
    
    def restart_sync(sync_type = nil)
      Rho::RhoConnectClient.stopSync()
      start_sync(sync_type)
    end
  end
end