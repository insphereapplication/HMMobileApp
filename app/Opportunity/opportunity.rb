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
  
  #   {"statecode":"Open",
  #    "activityid":"9b90b4bf-7d46-e011-837e-0050569c157c",
  #    "scheduledend":"3/2/2011 6:00:00 AM",
  #    "regardingobjectid":{"type":"opportunity","name":"Frankliny, Benjamin - 2/9/2011","id":"10b8f740-6e34-e011-a625-0050569c157c"},
  #    "phonenumber":"(123) 456-7890",
  #    "cssi_phonetype":"Home",
  #    "subject":"Test","statuscode":"Open","type":"PhoneCall"}
  
  #6, :object=>"5b0635e7-f245-e011-837e-0050569c157c", 
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
    
  def contact
    @contact = Contact.find(self.contact_id)
  end
  
  def self.new_leads
    @new_leads ||= find(:all, :conditions => {"statuscode" => "New Opportunity"}).reject{|opp| opp.has_activities? }#.sort{|opp1, opp2| Date.parse(opp1.createdon) <=> Date.parse(opp2.createdon) }
  end 
  

  def days_ago()
    begin
      (Date.today - Date.strptime(createdon, "%m/%d/%Y")).to_i
    rescue
      puts "Unable to parse date: #{}; no age returned"
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
  
  def open_phone_calls
    @open_calls ||= PhoneCall.find(:all, :conditions => {"statuscode" => "Open", "parent_type" => "opportunity", "parent_id" => self.opportunityid })
  end
  
  def is_high_cost
    if(cssi_leadcost != nil or cssi_leadcost != "")
      if Rho::RhoConfig.exists?('lead_cost_threshold')
        if cssi_leadcost.to_f > Rho::RhoConfig.lead_cost_threshold
          return true
        end
      end
    end
  end

  
end
