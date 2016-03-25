class DeviceCapabilities
  class << self
    def is_connected?
      System.has_network
    end
    
    def connection_status
      is_connected? ? 'Online' : 'Offline'
    end
    
    def is_syncing?
      Rho::RhoConnectClient.isSyncing()
    end
    
    def sync_status
      is_syncing? ? 'Syncing' : 'Idle'
    end
  end
end