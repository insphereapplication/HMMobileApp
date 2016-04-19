require 'json'

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
    
    def filter_values
      @filter_values ||= Rho::JSON.parse(instance.filter_values || '{}')
	  puts "***Filter values ***: #{@filter_values}"
	  @filter_values
    end
    
    def clear_credentials
      instance.login=nil
      instance.password=nil
      instance.pin_last_activity_time=nil
      instance.pin_confirmed=false
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
    
    def pin_last_activity_time
      instance.pin_last_activity_time || ''
    end
    
    
    def pin_confirmed
      instance.pin_confirmed|| ''
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
    
    def last_synced
      instance.last_synced || ''
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
    
    def pin_last_activity_time=(pin_last_activity_time)
      instance.pin_last_activity_time=pin_last_activity_time
      instance.save
    end
    
    def pin_confirmed=(pin_confirmed)
      instance.pin_confirmed=pin_confirmed
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
    
    def last_synced=(value)
      instance.last_synced=value
      instance.save
    end
    
    def set_filter_values(value)
      @filter_values = value
      instance.filter_values = ::JSON.generate(value)
      instance.save
    end

    def update_persisted_filter_values(prefix, filter_names, params)
	  puts "In filter perstst update."
	  puts "prefix: #{prefix}, filter_names: #{filter_names}, params: #{params}"
      persisted_filter_update = filter_names.inject({}){|sum,filter_name| 
        sum["#{prefix}#{filter_name}"] = params[filter_name] unless params[filter_name].nil?
        sum
      }

      set_filter_values((filter_values || {}).merge(persisted_filter_update)) unless persisted_filter_update.count == 0
    end
    
    def get_persisted_filter_values(prefix, filters)
      filters.inject({}){|sum,filter|
        persisted_filter_value = Settings.filter_values["#{prefix}#{filter[:name]}"]
        sum[filter[:name]] = persisted_filter_value.blank? ? filter[:default_value] : persisted_filter_value
        sum
      }
    end
    
    def instance #pulls settings from DB, caches them in @instance
      flush_instance unless @instance
      @instance
    end
    
    def flush_instance #populates @instance with settings from DB
      @instance = Settings.find(:first) || Settings.create({})
    end
    
    def pin_is_current?
       if Time.new - instance.pin_last_activity_time < Constants::PIN_EXPIRE_SECONDS
         return true
       else
         return false
       end
     end
    
    def record_activity
     
      if !Settings.pin_last_activity_time.blank? && Settings.pin_last_activity_time.class==String
        Settings.pin_last_activity_time = Time.parse(Settings.pin_last_activity_time)
      end
      
      #CR: can use 'blank?' here
      if Settings.pin_last_activity_time.nil? || Settings.pin_last_activity_time==""
        Settings.pin_last_activity_time=Time.new
        Settings.pin_confirmed=false
      elsif Time.new - Settings.pin_last_activity_time < Constants::PIN_EXPIRE_SECONDS
          Settings.pin_last_activity_time=Time.new
      else
          Settings.pin_confirmed=false
          Settings.pin_last_activity_time=Time.new
      end
    end
    
    def last_integrated_lead
      instance.last_integrated_lead || ''
    end
    
    def last_integrated_lead=(value)
      instance.last_integrated_lead=value
      instance.save
    end
    
    def last_assigned_lead
      instance.last_assigned_lead || ''
    end
    
    def last_assigned_lead=(value)
      instance.last_assigned_lead=value
      instance.save
    end
  end
end
