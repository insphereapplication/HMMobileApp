class DeviceCapabilities
  class << self
    def is_connected?
      System.has_network
    end
    
    def connection_status
      is_connected? ? 'Online' : 'Offline'
    end
  end
end