require 'time'
require 'date'
require 'rho/rhotabbar'

class Opportunity
  include Rhom::FixedSchema
  include ChangedFlag
  include SQLHelper
  
  enable :sync
  
  set :sync_priority, 30

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
  property :overriddencreatedon, :string
  property :competitorid, :string
  property :actual_end, :string
  
  index :opportunity_pk_index, [:opportunityid]
  unique_index :unique_opp, [:opportunityid] 
  
  index :object_index, [:object]
  index :opp_contact_index, [:contact_id]
  index :opp_statecode_index, [:statecode]
  index :opp_statuscode_index, [:statuscode]
  index :opp_createdon_index, [:createdon]

  belongs_to :contact_id, 'Contact'
    
  def contact
    Contact.find(self.contact_id)
  end

  def self.new_leads
    find_by_sql(NEW_LEADS_SQL)
  end 
  
  def self.open_opportunities
    find(:all, :conditions => "statecode not in ('Won', 'Lost')")
  end
  
  def self.todays_new_leads(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
      #{NEW_LEADS_SQL}
      #{CREATED_ON_SQL} = #{NOW_SQL}
      #{ORDER_BY_CREATED_ON_DESC_SQL}
      #{get_pagination_sql(page, page_size)}
    })
  end
  
  def self.previous_days_leads(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
      #{NEW_LEADS_SQL}
      #{CREATED_ON_SQL} < #{NOW_SQL}
      #{ORDER_BY_CREATED_ON_DESC_SQL}
      #{get_pagination_sql(page, page_size)}
    })
  end
  
  # TODO: not an optimal query. find a better one.
  def self.by_last_activities(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
      select * from Opportunity o where o.statecode not in ('Won', 'Lost') and 
        exists (
            select a1.object from Activity a1 where 
            a1.parent_type='Opportunity' and 
            a1.parent_id=o.object and 
            (a1.statecode not in ('Open', 'Scheduled') or a1.scheduledend = '' or a1.scheduledend is null)
          ) and 
        not exists (
            select a2.object from Activity a2 where
            a2.parent_type='Opportunity' and 
            a2.parent_id=o.object and
            (a2.statecode in ('Open', 'Scheduled') and a2.scheduledend is not null and a2.scheduledend <> '')
          )
      order by datetime(o.cssi_lastactivitydate) asc
      #{get_pagination_sql(page, page_size)}
    })
  end
  
  def is_owned_by_this_opportunity_sql
    "parent_type = 'Opportunity' and parent_id = '#{object}'"
  end
  
  def appointments
    Activity.find_by_sql(%Q{
        select * from Activity where type='Appointment' and #{is_owned_by_this_opportunity_sql}
      })
  end
  
  def activities
    Activity.find_by_sql(%Q{
        select * from Activity where #{is_owned_by_this_opportunity_sql}
      })
  end
  
  def phone_calls
    Activity.find_by_sql(%Q{
        select * from Activity where type='PhoneCall' and #{is_owned_by_this_opportunity_sql}
      })
  end
  
  def adhoc_numbers
   phone_calls.each do |phone_call|
     if @phonenumber
       phonenumber
     end
   end
  end
  
  def notes
    Note.find_by_sql(%Q{
        select n.* from Note n where #{is_owned_by_this_opportunity_sql} or (
          n.parent_type = 'PhoneCall' and n.parent_id in (
            select pc.object from Activity pc where pc.type='PhoneCall' and 
            pc.parent_type='Opportunity' and 
            pc.parent_id='#{object}'
          )
        ) order by datetime(n.createdon) desc
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
      :statecode => 'Completed',
      :statuscode => 'Made'
    }
    
    if phone_call = most_recent_open_phone_call   
      phone_call.update_attributes(phone_call_attrs)
    else
      phone_call = Activity.create(phone_call_attrs.merge({
        :parent_type => 'Opportunity', 
        :parent_id => self.object,
        :type => 'PhoneCall',
        :parent_contact_id => self.contact_id
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
