class Activity
  include Rhom::PropertyBag
  
  #   {"statecode":"Open",
  #    "activityid":"9b90b4bf-7d46-e011-837e-0050569c157c",
  #    "scheduledend":"3/2/2011 6:00:00 AM",
  #    "regardingobjectid":{"type":"opportunity","name":"Frankliny, Benjamin - 2/9/2011","id":"10b8f740-6e34-e011-a625-0050569c157c"},
  #    "phonenumber":"(123) 456-7890",
  #    "cssi_phonetype":"Home",
  #    "subject":"Test","statuscode":"Open","type":"PhoneCall"}
  
  #   :object=>"5b0635e7-f245-e011-837e-0050569c157c", 
  #   :activityid=>"5b0635e7-f245-e011-837e-0050569c157c", 
  #   :cssi_disposition=>"No Answer", 
  #   :cssi_phonetype=>"Home", 
  #   :parent_id=>"540ca70a-2d35-e011-a625-0050569c157c", 
  #   :parent_type=>"opportunity", 
  #   :phonenumber=>"(123) 456-7897", 
  #   :scheduledend=>"3/2/2011 6:00:00 AM", 
  #   :statecode=>"Open", 
  #   :statuscode=>"Open", 
  #   :subject=>"No Answer - LoggerTest 7, Test - 2/10/2011", 
  #   :type=>"PhoneCall"}>

  enable :sync
  set :sync_priority, 1 # this needs to be loaded first so that opportunities can know their context
  
  OPEN_STATE_CODES = ['Open', 'Scheduled']
  
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize) 
      parent.find(:first, :conditions => {"#{self.parent_type.downcase}id" => self.parent_id})
    end
  end
  
  def opportunity
    parent if parent && parent_type.downcase == "opportunity"
  end
  
  def contact
    parent if parent && parent_type.downcase == "contact"
  end
  
  def open?
    OPEN_STATE_CODES.include?(self.statecode)
  end
  
  def days_past_due
    DateUtil.days_ago(self.scheduledend) 
  end
  
end

class PhoneCall < Activity
end

class Appointment < Activity
  
  # an array of class-level cache objects
  CACHED = [@open_appointments]
  
  # clear out all class-level cache objects
  def self.clear_cache
    CACHED.each {|cache| cache = nil }
  end
  
  def self.open_appointments
    find(:all, :conditions => {'statecode' => 'Scheduled'}).reject{|appointment| puts appointment.inspect; appointment.parent.closed? }
  end
  
  def self.past_due_appointments
    open_appointments.select_all_before_today(:scheduledend) 
  end
  
  def self.future_appointments
    open_appointments.select_all_after_today(:scheduledend)
  end
  
  def self.todays_appointments
    open_appointments.select_all_occurring_today(:scheduledend)
  end
  
end
