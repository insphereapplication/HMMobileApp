
class Settings
  include Rhom::PropertyBag
  
  set :schema_version, '1.0'

  class << self
    
    def credentials
      [login,password,pin]
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
    
    def is_new_opportunity_sync?
      sync_type == 'new_opportunity'
    end
    
    def clear_credentials
      instance.login=nil
      instance.password=nil
      instance.pin=nil
      instance.credentials_verified=false
      instance.save
    end
    
    def login
      instance.login || ''
    end
    
    def password
      instance.password || ''
    end
    
    def pin
      instance.pin || ''
    end
    
    def credentials_verified
      # use string comparison below because settings DB always stores & returns strings
      # sometimes "instance" is in-memory and **not** fetched from db, which could return real boolean types instead of strings here
      # to_s covers both cases
      instance.credentials_verified.to_s == 'true'
    end
    
    def initial_sync_complete
      # use string comparison below because settings DB always stores & returns strings
      # sometimes "instance" is in-memory and **not** fetched from db, which could return real boolean types instead of strings here
      # to_s covers both cases
      instance.initial_sync_complete.to_s == 'true'
    end
    
    def sync_type
      instance.sync_type || 'background'
    end
    
    def new_opportunity_sync_pending
      result = instance.new_opportunity_sync_pending || false
      
      # use string comparison below because settings DB always stores & returns strings
      # sometimes "instance" is in-memory and **not** fetched from db, which could return real boolean types instead of strings here
      # to_s covers both cases
      result.to_s == 'true'
    end
    
    def new_opportunity_sync_pending=(new_opportunity_sync_pending)
      instance.new_opportunity_sync_pending=new_opportunity_sync_pending
      instance.save     
    end
    
    def login=(login)
      instance.login=login
      instance.save
    end
    
    def password=(password)
      instance.password=password
      instance.save
    end
    
    def pin=(pin)
      instance.pin=pin
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
    
    def instance #pulls settings from DB, caches them in @instance
      flush_instance unless @instance
      @instance
    end
    
    def flush_instance #populates @instance with settings from DB
      @instance = Settings.find(:first) || Settings.create({})
    end
  end
end
