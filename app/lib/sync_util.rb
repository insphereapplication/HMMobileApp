class SyncUtil
  class << self
    def set_sync_type(type)
      Settings.sync_type = type
    end
    
    def start_sync(sync_type = nil)
      set_sync_type(sync_type) if sync_type
      SyncEngine.dosync
    end
  end
end