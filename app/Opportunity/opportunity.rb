require 'date'
require 'time'

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
    @contact = Contact.find(self.contact_id)
  end
  
  def self.new_leads
    Opportunity.find(:all, :conditions => {"statuscode" => "New Opportunity"}).sort{|opp1, opp2| Date.parse(opp1.createdon) <=> Date.parse(opp2.createdon) }
  end 
  
end
