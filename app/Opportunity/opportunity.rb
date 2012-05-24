require 'time'
require 'date'
require 'rho/rhotabbar'

class Opportunity
  include Rhom::FixedSchema
  include ChangedFlag
  include SQLHelper
  
  enable :sync
  set :schema_version, '1.0'
  set :sync_priority, 30

  property :opportunityid, :string
  property :statecode, :string
  property :cssi_leadtypeid, :string
  property :cssi_leadvendorid, :string
  property :cssi_inputsource, :string
  property :cssi_leadsourceid, :string
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
  property :temp_id, :string
  property :actualclosedate, :string
  property :opportunityratingcode, :string
  property :status_update_timestamp, :string
  property :ownerid, :string
  property :cssi_assigneddate, :string
  property :cssi_assetownerid, :string

  index :opportunity_pk_index, [:opportunityid]
  unique_index :unique_opp, [:opportunityid] 
  
  index :object_index, [:object]
  index :opp_contact_index, [:contact_id]
  index :opp_statecode_index, [:statecode]
  index :opp_statuscode_index, [:statuscode]
  index :opp_createdon_index, [:createdon]

  belongs_to :contact_id, 'Contact'
    
  def contact
    Contact.find_contact(contact_id) unless contact_id.blank?
  end
  
  def self.create_new(params)
      new_opportunity = Opportunity.create(params)
      new_opportunity.update_attributes( :temp_id => new_opportunity.object )
      new_opportunity
  end
  
  def self.create_for_new_contact(opportunity_params, contact_id) 
    opp = create_new(opportunity_params)  
    opp.update_attributes( :contact_id =>  contact_id)
    opp.update_attributes( :statecode => 'Open')
    opp.update_attributes( :cssi_statusdetail => 'New')
    opp.update_attributes( :statuscode => 'New Opportunity')
    opp.update_attributes( :opportunityratingcode => 'Warm')
    opp.update_attributes( :createdon => Time.now.strftime("%Y-%m-%d %H:%M:%S"))   
    opp.update_attributes( :cssi_inputsource => 'Manual')
    opp.update_attributes( :ownerid => StaticEntity.system_user_id)  
    opp.update_attributes( :cssi_assetownerid => StaticEntity.system_user_id) 
    opp 
  end
  
  def self.find_opportunity(id)
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @opportunity = Opportunity.find(id)
    else
      id.gsub!(/[{}]/,"")

      @opportunity = Opportunity.find_by_sql(%Q{
          select o.* from Opportunity o where temp_id='#{id}'
        }).first
      @opportunity
      end
  end

  # TODO: Dave/Carter, why is find_contact here in Opportunity.rb?
  def self.find_contact(id)
    
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @contact = Contact.find(id)
    else
      id.gsub!(/[{}]/,"")
      @contact = Contact.find_by_sql(%Q{
          select c.* from Contact c where temp_id='#{id}'
        }).first
      @contact
      end
  end
  
  def self.latest_integrated_lead
    find_by_sql(LATEST_INTEGRATED_LEAD)
  end
  
  def self.latest_assigned_lead
    find_by_sql(LATEST_ASSIGNED_LEAD).first
  end
    
  
  def self.open_opportunities
    find(:all, :conditions => "statecode not in ('Won', 'Lost')")
  end
  
  def self.todays_new_leads(page=nil, page_size=DEFAULT_PAGE_SIZE)
    sql = %Q{
      #{new_leads_sql}
      #{CREATED_ON_SQL} = #{NOW_SQL}
      #{ORDER_BY_CREATED_ON_DESC_SQL}
      #{get_pagination_sql(page, page_size)}
    }
    
    find_by_sql(sql)
  end
  
  def self.previous_days_leads(page=nil, page_size=DEFAULT_PAGE_SIZE)
    sql = %Q{
      #{new_leads_sql}
      #{CREATED_ON_SQL} < #{NOW_SQL}
      #{ORDER_BY_CREATED_ON_DESC_SQL}
      #{get_pagination_sql(page, page_size)}
    }
    
    find_by_sql(sql)
  end
  
  # TODO: not an optimal query. find a better one.
  def self.by_last_activities(page, statusReasonFilter, sortByFilter, createdFilter, isDailyFilter, page_size=DEFAULT_PAGE_SIZE)
    #Find all opportunities that have activities of which none are open or scheduled
    #Also include opportunities that have no activities and have a status code != "New Opportunity"
    #Sort by the opportunity's last activity date
    
    statusReasonWhereClause = 'and '
    case statusReasonFilter
      when 'NoContactMade'
        statusReasonWhereClause += "(o.statuscode = 'No Contact Made')"
      when 'ContactMade'
        statusReasonWhereClause += "(o.statuscode = 'Contact Made')"
      when 'AppointmentSet'
        statusReasonWhereClause += "(o.statuscode = 'Appointment Set')"
      when 'DealInProgress'
        statusReasonWhereClause += "(o.statuscode = 'Deal in Progress')"
      else
        statusReasonWhereClause = ''
    end
    
    sortByClause= ''
    case sortByFilter
      when 'LastActivityDateAscending'
        sortByClause = "order by datetime(o.cssi_lastactivitydate) asc"
      when 'LastActivityDateDescending'
        sortByClause = "order by datetime(o.cssi_lastactivitydate) desc"
      when 'CreateDateAscending'
        sortByClause = "order by datetime(o.createdon) asc"
      when 'CreateDateDescending'
        sortByClause = "order by datetime(o.createdon) desc"
      else
        sortByClause = "order by datetime(o.cssi_lastactivitydate) asc"
    end
        
    createdClause = 'and '
    case createdFilter # It should be a number unless "All" is selected
      when 'All'
        createdClause += "date(o.createdon) <= date('now')"
      when /^\d+$/ # When it's a number (i.e. string only contains numerical characters)
        createdClause += "date(o.createdon) = date('now', '-#{createdFilter.to_i} days')"
      else
        createdClause = ''
    end
    
    dailyClause = ''
    if isDailyFilter == 'true'
      dailyClause = %Q{
        and not exists (
          select a0.object
          from Activity a0
          where a0.parent_type='Opportunity' and a0.parent_id=o.object
            and a0.type='PhoneCall' and a0.statuscode = 'Made' and date(a0.scheduledstart)=#{NOW_SQL}
        )
      }
    end
    
    # This query is complex; be sure you know what you are doing before modifying this
    sql = %Q{
      select * from Opportunity o 
        where o.ownerid = '#{StaticEntity.system_user_id}'
        and o.statecode not in ('Won', 'Lost') 
        and (
          o.statuscode <> 'New Opportunity'
          or exists (
            select a1.object from Activity a1 where 
            a1.parent_type='Opportunity' and 
            a1.parent_id=o.object and 
            a1.type in ('PhoneCall','Appointment') and
            (a1.statecode not in ('Open', 'Scheduled') or a1.scheduledend = '' or a1.scheduledend is null)
          )
        )
        and not exists (
          select a2.object from Activity a2 where
          a2.parent_type='Opportunity' and 
          a2.parent_id=o.object and
          a2.type in ('PhoneCall','Appointment') and
          (a2.statecode in ('Open', 'Scheduled') and a2.scheduledend is not null and a2.scheduledend <> '')
        )
        #{dailyClause}
        #{statusReasonWhereClause}
        #{createdClause}
        #{sortByClause}
        #{get_pagination_sql(page, page_size)}
    }
    
    find_by_sql( sql )
  end
  
  def is_owned_by_this_opportunity_sql
    "parent_type = 'Opportunity' and parent_id = '#{object}'"
  end
  
  def appointments
    Activity.find_by_sql(%Q{
        select * from Activity 
        where type='Appointment' 
        and #{is_owned_by_this_opportunity_sql}
        order by datetime(scheduledstart) 
      }) 
  end
  
  def activities
    Activity.find_by_sql(%Q{
        select * from Activity where #{is_owned_by_this_opportunity_sql}
      })
  end
  
  def activity_list
    Activity.find_by_sql(%Q{
        select type, scheduledstart as "displaytime", statuscode, cssi_disposition, subject from Activity where #{is_owned_by_this_opportunity_sql}
        AND type in ('Appointment','PhoneCall') AND scheduledstart IS NOT NULL
        UNION
        select type, scheduledend as "displaytime", statuscode, cssi_disposition, subject from Activity where #{is_owned_by_this_opportunity_sql}
        AND type = 'Task' AND scheduledend IS NOT NULL
        UNION
        select type, createdon as "displaytime", statuscode, cssi_disposition, subject from Activity where #{is_owned_by_this_opportunity_sql}
        AND scheduledstart IS NULL AND scheduledend IS NULL order by "displaytime" desc
      })
  end
  
  def phone_calls
    sql = %Q{
        select * from Activity where type='PhoneCall' and #{is_owned_by_this_opportunity_sql}
        order by scheduledstart
      }
      
    Activity.find_by_sql(sql)
  end
  
  def app_details
    ApplicationDetail.find_by_sql(%Q{
        select a.* 
        from ApplicationDetail a 
        where opportunity_id = '#{object}' 
    })
  end
    
  def create_application_details
    APPDetails.create({
      :notetext => note_text, 
      :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
      :parent_id => self.object,
      :parent_type => 'Opportunity' 
    }) 
  end
  
  def update_application_details
    
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
        select n.* 
        from Note n 
        where #{is_owned_by_this_opportunity_sql} 
        or n.parent_id in (
          select ac.object from Activity ac where 
          ac.parent_type='Opportunity'
          and ac.parent_id='#{object}'
        )
        order by datetime(n.createdon) desc
    })
  end
  
  def create_note(note_text)
    unless note_text.blank?
      Note.create_new({
        :notetext => note_text, 
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :parent_id => self.object,
        :parent_type => 'Opportunity' 
      })
    end
  end
  
  def record_phone_call_made_now(disposition="")
    phone_call_attrs = {
      :scheduledstart => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),  
      :cssi_disposition => disposition,
      :statecode => 'Completed',
      :statuscode => 'Made'
    }
    
    if phone_call = most_recent_open_phone_call   
      ## if updating an open phone call update the activity page as a precaution
      Activity.local_changed=true
      phone_call.update_attributes(phone_call_attrs)
      
    else
      phone_call = Activity.create_new(phone_call_attrs.merge({
        :parent_type => 'Opportunity', 
        :subject => "Phone Call - #{self.contact.full_name}",
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
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
  
  def has_activities?
    activities && activities.size > 0
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
