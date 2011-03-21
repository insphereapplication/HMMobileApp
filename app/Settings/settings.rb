
class Settings
  include Rhom::PropertyBag

  class << self
    
    def credentials
      [login,password]
    end
    
    def has_persisted_credentials?
      !instance.login.blank? && !instance.password.blank?
    end
    
    def clear_credentials
      instance.login=nil
      instance.password=nil
      instance.save
    end
    
    def login
      instance.login || ''
    end
    
    def password
      instance.password || ''
    end
    
    def login=(login)
      instance.login=login
      instance.save
    end
    
    def password=(password)
      instance.password=password
      instance.save
    end
    
    def instance
      @instance ||= Settings.find(:first) || Settings.create({})
    end
  end
end
