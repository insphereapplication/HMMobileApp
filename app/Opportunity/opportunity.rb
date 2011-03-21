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
  property :cssi_lineofbusiness, :string
  
  belongs_to :contact_id, 'Contact'
  
  # an array of class-level cache objects
  CACHED = [@new_leads, @phone_calls]
  CLOSED_STATECODES = ['Won', 'Lost']
  
  # clear out all class-level cache objects
  def self.clear_cache
    CACHED.each {|cache| cache = nil }
  end
    
  def contact
    Contact.find(self.contact_id)
  end
  
  def self.new_leads
    find(:all, :conditions => {"statuscode" => "New Opportunity"}).reject{|opp| opp.has_activities? || opp.closed?}.compact#.date_sort(:createdon)
  end 

  def self.follow_up_phone_calls
    find(:all).map{|opportunity| opportunity.open_phone_calls.first }.compact#.date_sort(:scheduledend)
  end
  
  def self.todays_follow_ups
    follow_up_phone_calls.select_all_occurring_today(:scheduledend)
  end
  
  def self.past_due_follow_ups
    follow_up_phone_calls.select_all_before_today(:scheduledend)
  end
  
  def self.future_follow_ups
    follow_up_phone_calls.select_all_after_today(:scheduledend)
  end
  
  def self.todays_new_leads
    new_leads.select_all_occurring_today(:createdon)
  end
  
  def self.previous_days_leads
    new_leads.select_all_before_today(:createdon)
  end
  
  def self.follow_up_activities
    opportunities = find(:all)
    opportunities.map{|opp| opp.open_phone_calls.first }.compact#.date_sort(:scheduledend)
  end
  
  def self.last_activities
    find(:all).select {|opp| opp.has_activities? && !opp.has_open_activities? }
  end
  
  def record_phone_call_made_now
    phone_call_attrs = {
      :scheduledend => Time.now.to_s, 
      :subject => "Phone Call - #{self.contact.full_name}",
      :statecode => 'Completed', 
      :parent_type => 'Opportunity', 
      :parent_id => self.object
    }
    
    if phone_call = most_recent_open_phone_call   
      phone_call.update_attributes(phone_call_attrs)
    else
      phone_call = PhoneCall.create(phone_call_attrs)
    end
    
  end
  
  def complete_most_recent_open_call
    if most_recent_open_phone_call
      record_phone_call_made
    end
  end
  
  def closed?
    CLOSED_STATECODES.include?(statecode)
  end
  
  def has_activities?
    activities && activities.size > 0
  end
  
  def days_past_due
    DateUtil.days_ago(next_activity_due_date) 
  end
  
  def next_activity_due_date
    most_recent_phone_call.scheduledend if most_recent_phone_call && most_recent_phone_call.scheduledend 
  end
  
  def last_activity_date
    last_activity.scheduledend if last_activity && last_activity.scheduledend 
  end
  
  def most_recent_open_or_create_new_phone_call
    most_recent_open_phone_call || PhoneCall.new
  end
  
  def is_new?
    statuscode == "New Opportunity"
  end

  def has_open_activities?
    activities && activities.any?{|a| a.open? }
  end
  
  def activities
    Activity.find(:all, :conditions => {"parent_type" => "opportunity", "parent_id" => self.opportunityid })
  end
  
  def phone_calls
    PhoneCall.find(:all, :conditions => {"parent_type" => "opportunity", "parent_id" => self.opportunityid })
  end
  
  def appointments
    Activity.find(:all, :conditions => {"type" => "Appointment", "parent_type" => "opportunity", "parent_id" => self.opportunityid})
  end
  
  def most_recent_phone_call
    phone_calls.first
  end
  
  def most_recent_open_phone_call
    open_phone_calls.first if open_phone_calls
  end
  
  def open_phone_calls
    phone_calls.select{|pc| pc.statuscode == "Open"} if phone_calls
  end
  
  def rollup_status
    last_activity && !last_activity.cssi_disposition.blank? ? last_activity.cssi_disposition : "Callback"
  end
  
  def last_activity
    activities.first if activities
  end
  
  def created_on_formatted
    Time.parse(createdon).to_formatted_string if createdon
  end
  
  def create_or_find_earliest_phone_call(attributes)
    if phone_calls.size > 0
      return phone_calls.compact.date_sort(:scheduledstart).first
    else
      phone_call = Activity.create('type' => 'PhoneCall', 'disposition' => params['cssi_disposition'], 'parent_id' => opportunityid, 'parent_type' => 'opportunity')
      return phone_call
    end
  end
  
  def is_high_cost
    unless cssi_leadcost.blank?
      if Rho::RhoConfig.exists?('lead_cost_threshold')
        cssi_leadcost.to_f > Rho::RhoConfig.lead_cost_threshold
      end
    end
  end
end

def days_old
  formatted_days
  begin
    if Date.today == DateTime.strptime(createdon, "%m/%d/%Y")
      return "Today"
    else
      formatted_days = (Date.today - Date.strptime(createdon, "%m/%d/%Y %I:%M:%S %p")).to_i
      return formatted_days + "d"
    end
  rescue
    puts "Unable to parse date: #{}; no age returned"
  end
end
