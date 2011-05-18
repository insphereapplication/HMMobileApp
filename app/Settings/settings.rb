
class Settings
  include Rhom::PropertyBag
  
  set :schema_version, '1.0'

  class << self
    
    def credentials
      [login,password]
    end
    
    def has_persisted_credentials?
      !instance.login.blank? && !instance.password.blank?
    end
    
    def has_verified_credentials?
      has_persisted_credentials? && credentials_verified
    end
    
    def initial_sync_completed?
      initial_sync_complete
    end
    
    def is_background_sync?
      sync_type == 'background'
    end
    
    def is_init_sync?
      sync_type == 'init'
    end
    
    def clear_credentials
      instance.login=nil
      instance.password=nil
      instance.credentials_verified=false
      instance.save
    end
    
    def login
      instance.login || ''
    end
    
    def password
      instance.password || ''
    end
    
    def credentials_verified
      #use string comparison below because settings DB always stores & returns strings
      instance.credentials_verified == 'true'
    end
    
    def initial_sync_complete
      #use string comparison below because settings DB always stores & returns strings
      instance.initial_sync_complete == 'true'
    end
    
    def sync_type
      instance.sync_type || 'background'
    end
    
    def login=(login)
      instance.login=login
      instance.save
    end
    
    def password=(password)
      instance.password=password
      instance.save
    end
    
    def credentials_verified=(verified)
      instance.credentials_verified=verified
      instance.save
    end
    
    def initial_sync_complete=(value)
      instance.initial_sync_complete=value
      instance.save
    end
    
    def sync_type=(value)
      instance.sync_type=value
      instance.save
    end
    
    def instance
      @instance ||= Settings.find(:first) || Settings.create({})
    end
  end
end
