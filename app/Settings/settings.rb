
class Settings
  include Rhom::PropertyBag

  class << self
    
    def credentials
      [login,password]
    end
    
    def clear_credentials
      login=nil
      password=nil
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
