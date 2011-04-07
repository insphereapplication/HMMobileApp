
class Settings
  include Rhom::PropertyBag

  class << self
    
    def credentials
      [login,password]
    end
    
    def has_persisted_credentials?
      !instance.login.blank? && !instance.password.blank?
    end
    
    def has_verified_credentials?
      has_persisted_credentials? && instance.credentials_verified
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
      instance.credentials_verified || false
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
    
    def instance
      @instance ||= Settings.find(:first) || Settings.create({})
    end
  end
end
