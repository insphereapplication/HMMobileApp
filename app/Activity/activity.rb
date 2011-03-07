class Activity
  include Rhom::PropertyBag

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
