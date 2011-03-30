require 'time'
require 'date'
require 'rho/rhotabbar'

class Opportunity
  include Rhom::FixedSchema
  
  enable :sync
  
  set :sync_priority, 100

  property :opportunityid, :string
  property :statecode, :string
  property :cssi_leadtypeid, :string
  property :cssi_leadvendorid, :string
  property :cssi_inputsource, :string
  property :cssi_leadsourceid, :string
  property :cssi_assignedagentid, :string
  property :statuscode, :string
  property :cssi_statusdetail, :string
  property :createdon, :string
  property :cssi_leadcost, :string
  property :modifiedon, :string
  property :cssi_lastactivitydate, :string
  property :cssi_callcounter, :string
  property :contact_id, :string
  property :cssi_lineofbusiness, :string
  property :cssi_fromrhosync, :string
  
  index :opportunity_pk_index, [:opportunityid]
  index :contact_index, [:contact_id]
  
  belongs_to :contact_id, 'Contact'
  
  # an array of class-level cache objects
  CLOSED_STATECODES = ['Won', 'Lost']
  
  def opportunity_conditions
     { 
      { 
        :func => 'LOWER', 
        :name => 'parent_type', 
        :op => '='
      } => 'opportunity',
      {
        :name => 'parent_id',
        :op => '='
      } => self.opportunityid
    }
  end
  
  # TODO: fix this and use for better performance
  def self.open_conditions
    [{
      :conditions => { 
        {
          :name => 'statecode', 
          :op => '!='
        } => 'Won'
      }   
    }]
    
  end
    
  def contact
    Contact.find(self.contact_id)
  end

  def self.new_leads
    find_by_sql(%Q{
      select * from Opportunity o where 
      statuscode='New Opportunity' and
      not exists (
        select a.object from Activity a 
        where parent_type='opportunity' and 
        parent_id=o.object
      )
    })
  end 
  
  def self.open_opportunities
    find(:all, :conditions => "statecode not in ('Won', 'Lost')")
  end

  def self.follow_up_phone_calls
    Activity.find_by_sql(%Q{
        select * from Activity a, Opportunity o 
        where a.type='PhoneCall' and 
        a.parent_type='opportunity' and a.parent_id=o.object and 
        o.statecode not in ('Won', 'Lost') 
        order by datetime(scheduledend)
      }) 
  end
  
  def self.todays_follow_ups
    Activity.find_by_sql(%Q{
        select * from Activity a, Opportunity o 
        where a.type='PhoneCall' and 
        a.parent_type='opportunity' and a.parent_id=o.object and 
        o.statecode not in ('Won', 'Lost') and
        (date(scheduledend) = date('now') + #{DateUtil.offset})
        order by datetime(scheduledend)
      })
  end
  
  def self.past_due_follow_ups
    Activity.find_by_sql(%Q{
        select * from Activity a, Opportunity o 
        where a.type='PhoneCall' and 
        a.parent_type='opportunity' and a.parent_id=o.object and 
        o.statecode not in ('Won', 'Lost') and
        (date(scheduledend) < date('now', 'localtime'))
        order by datetime(scheduledend)
      })
  end
  
  def self.future_follow_ups
    Activity.find_by_sql(%Q{
        select * from Activity a, Opportunity o 
        where a.type='PhoneCall' and 
        a.parent_type='opportunity' and a.parent_id=o.object and 
        o.statecode not in ('Won', 'Lost') and
        (date(scheduledend) > date('now', 'localtime'))
        order by datetime(scheduledend)
      })
  end
  
  def self.todays_new_leads
    find_by_sql(%Q{
      select * from Opportunity o where 
      statuscode='New Opportunity' and
      not exists (
        select a.object from Activity a 
        where parent_type='opportunity' and 
        parent_id=o.object
      ) 
      and (date(o.createdon) = date('now', 'localtime'))
      order by date(o.createdon) desc
    })
  end
  
  def self.previous_days_leads
    find_by_sql(%Q{
      select * from Opportunity o where 
      statuscode='New Opportunity' and
      not exists (
        select a.object from Activity a 
        where parent_type='opportunity' and 
        parent_id=o.object
      ) 
      and (date(o.createdon) < date('now', 'localtime') )
      order by date(o.createdon) desc
    })
  end
  
  def self.with_unscheduled_activities
    find_by_sql(%Q{
      select * from Opportunity o where statecode not in ('Won', 'Lost') and 
      exists (
          select a.object from Activity a where 
          a.parent_type='opportunity' and 
          a.parent_id=o.object and 
          a.statecode not in ('Open', 'Scheduled') or scheduledend = ''
        ) 
      order by datetime(o.cssi_lastactivitydate) desc
    })
  end
  
  def create_note(note_text)
    unless note_text.blank?
      Note.create({
        :notetext => note_text, 
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :parent_id => self.object,
        :parent_type => 'opportunity' 
      })
    end
  end
  
  def record_phone_call_made_now(disposition="")
    phone_call_attrs = {
      :scheduledend => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT), 
      :subject => "Phone Call - #{self.contact.full_name}",
      :cssi_disposition => disposition,
      :statecode => 'Completed'
    }
    
    if phone_call = most_recent_open_phone_call   
      phone_call.update_attributes(phone_call_attrs)
    else
      phone_call = Activity.create(phone_call_attrs.merge({
        :parent_type => 'Opportunity', 
        :parent_id => self.object,
        :type => 'PhoneCall'
        })
      )
    end
    
  end
  
  def complete_most_recent_open_call(disposition="")
    if most_recent_open_phone_call
      record_phone_call_made_now(disposition)
    end
  end
  
  def closed?
    CLOSED_STATECODES.include?(statecode)
  end
  
  def days_past_due
    DateUtil.days_ago(next_activity_due_date) 
  end
  
  def next_activity_due_date
    most_recent_phone_call.scheduledend if most_recent_phone_call && most_recent_phone_call.scheduledend 
  end
  
  def most_recent_open_or_create_new_phone_call
    most_recent_open_phone_call || Activity.new({:type => 'PhoneCall'})
  end
  
  def is_new?
    statuscode == "New Opportunity"
  end

  def has_open_activities?
    activities && activities.any?{|a| a.open? }
  end
  
  def has_activities?
    activities && activities.size > 0
  end
  
  def has_scheduled_activities?
    activities && activities.any?{|a| a.open? && !a.scheduledend.blank? }
  end
  
  def scheduled_activities
    activities.select{|activity| activity.open? && !activity.scheduledend.blank? } if activities
  end
  
  def incomplete_appointments
    appointments.reject{|appointment| appointment.statecode == 'Completed' }
  end
  
  def appointments
    Activity.find(:all, 
                  :conditions => opportunity_conditions.merge({
                                  :name => 'type',
                                  :op => '='
                                } => 'Appointments'), 
                  :op => 'and')
  end
  
  def activities
    Activity.find( :all, :conditions => opportunity_conditions, :op => 'and')
  end
  
  def phone_calls
    Activity.find(:all, 
                  :conditions => opportunity_conditions.merge({
                                  :name => 'type',
                                  :op => '='
                                } => 'PhoneCall'), 
                  :op => 'and')
  end
  
  def adhoc_numbers
   phone_calls.each do |phone_call|
     if @phonenumber
       phonenumber
     end
   end
  end
  
  def notes
    Note.find(:all, :conditions => {"parent_type" => "opportunity", "parent_id" => self.object})
  end
  
  def most_recent_phone_call
    phone_calls.first
  end
  
  def most_recent_open_phone_call
    open_phone_calls.first if open_phone_calls
  end
  
  def open_phone_calls
    phone_calls.select{|phone_call| phone_call.open? } if phone_calls
  end
  
  def last_activity
    activities.first if activities
  end
  
  def created_on_formatted
    Time.parse(createdon).to_formatted_string if createdon
  end
  
  def is_high_cost
    unless cssi_leadcost.blank?
      if Rho::RhoConfig.exists?('lead_cost_threshold')
        cssi_leadcost.to_f > Rho::RhoConfig.lead_cost_threshold
      end
    end
  end
end
