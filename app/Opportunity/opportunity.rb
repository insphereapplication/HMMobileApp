require 'time'
require 'date'

class Opportunity
  include Rhom::PropertyBag

  enable :sync

  property :opportunityid, :string
  property :ownerid, :string
  property :cssi_assignedagentid, :string
  property :statecode, :string
  property :statuscode, :string
  property :cssi_statusdetail, :string
  property :cssi_leadsourceid, :string
  property :cssi_leadvendorid, :string
  property :cssi_leadtypeid, :string
  property :createdon, :string
  property :cssi_leadcost, :string
  property :modifiedon, :string
  property :cssi_lastactivitydate, :string
  property :cssi_callcounter, :string
  property :contact_id, :string
  
  belongs_to :contact_id, 'Contact'
    
  def contact
    @contact ||= Contact.find(self.contact_id)
  end
  
  def self.new_leads
    @new_leads ||= find(:all, :conditions => {"statuscode" => "New Opportunity"}).reject{|opp| opp.has_activities? }#.sort{|opp1, opp2| Date.parse(opp1.createdon) <=> Date.parse(opp2.createdon) }
  end 

  def self.follow_up_phone_calls
    @follow_up_phone_calls ||= find(:all).map{|opportunity| opportunity.open_phone_calls.first }.compact#.sort{|c1, c2| Date.parse(c1.scheduledend) <=> Date.parse(c2.scheduledend) }
  end
  
  def self.todays_follow_ups
    follow_up_phone_calls.select_all_occurring_today(:scheduledend)
  end
  
  def self.past_due_follow_ups
    follow_up_phone_calls.select_all_after_today(:scheduledend)
  end
  
  def self.future_follow_ups
    follow_up_phone_calls.select_all_before_today(:scheduledend)
  end
  
  def self.todays_new_leads
    new_leads.select_all_occurring_today(:createdon)
  end
  
  def self.previous_days_leads
    new_leads.select_all_before_today(:createdon)
  end
  
  def days_ago
    begin
      (Date.today - Date.strptime(createdon, "%m/%d/%Y")).to_i
    rescue
      puts "Unable to parse date: #{createdon}; no age returned"
    end
  end
  
  def self.follow_up_activities
    opportunities = find(:all)
    opportunities.map{|opp| opp.open_phone_calls.first }.compact#.sort{|c1, c2| Date.parse(c1.scheduledend) <=> Date.parse(c2.scheduledend) }
  end
  
  def self.last_activities
    find(:all).select {|opp| !opp.is_new? && opp.has_activities? && !opp.has_open_activities? }
  end
  
  def has_activities?
    activities && activities.size > 0
  end
  
  def is_new?
    statuscode == "New Opportunity"
  end

  def has_open_activities?
    activities && activities.any?{|a| a.open? }
  end
  
  def activities
    @activities ||= Activity.find(:all, :conditions => {"parent_type" => "opportunity", "parent_id" => self.opportunityid })
  end
  
  def phone_calls
    @phone_calls ||= PhoneCall.find(:all, :conditions => {"parent_type" => "opportunity", "parent_id" => self.opportunityid })
  end
  
  def open_phone_calls
    @open_calls ||= phone_calls.select{|pc| pc.statuscode == "Open"} 
  end
  
  def is_high_cost
    !cssi_leadcost.blank? && Rho::RhoConfig.lead_cost_threshold && (cssi_leadcost.to_f > Rho::RhoConfig.lead_cost_threshold)
  end

  
end
