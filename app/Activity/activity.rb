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
  
  OPEN_STATE_CODES = ['Open', 'Scheduled']
  
  def self.follow_up_activities
    Opportunity.find(:all)
      .map{|opp| opp.open_phone_calls.first }
      .compact
      .sort{|c1, c2| Date.parse(c1.scheduledend) <=> Date.parse(c2.scheduledend) }
  end
  
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize) 
      parent.find(:first, :conditions => {"#{self.parent_type.downcase}id" => self.parent_id})
    end
  end
  
  def opportunity
    parent if parent && parent_type == "Opportunity"
  end
  
  def contact
    parent if parent && parent_type == "Contact"
  end
  
  def open?
    OPEN_STATE_CODES.include?(statecode)
  end
  
end
