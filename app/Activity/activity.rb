class Activity
  include Rhom::FixedSchema
  include ChangedFlag
  include SQLHelper
  
  property :statecode, :string
  property :activityid, :string
  property :phonenumber, :string
  property :parent_type, :string
  property :cssi_phonetype, :string
  property :subject, :string
  property :cssi_fromrhosync, :string
  property :type, :string
  property :parent_id, :string
  property :scheduledstart, :string
  property :scheduledend, :string
  property :scheduleddurationminutes, :string
  property :cssi_disposition, :string
  property :statuscode, :string
  property :location, :string
  property :cssi_location, :string
  property :description, :string
  property :cssi_dispositiondetail, :string
  property :parent_contact_id, :string
  property :createdon, :string
  property :temp_id, :string
  property :prioritycode, :string
  
  #######email properties########
  property :torecipients, :string
  property :actualstart, :string
  property :sender, :string
  property :actualend, :string
  property :ownerid, :string
  property :email_to, :string
  property :bcc, :string
  property :cc, :string
  property :email_from, :string
  ################################
  
  
  belongs_to :parent_id, 'Opportunity'
  belongs_to :parent_contact_id, 'Contact'
  
  index :activity_pk_index, [:activityid]
  unique_index :unique_activity, [:activityid] 
  
  index :activity_parent_index, [:parent_id, :parent_type]
  index :activity_statuscode_index, [:statuscode]
  index :activity_statecode_index, [:statecode]
  index :activity_object_index, [:object]
  index :activity_createdon_index, [:createdon]
  index :activity_type_index, [:type]
  
  enable :sync
  set :sync_priority, 40 # this needs to be loaded before opportunities so that opportunities can know their context
  
  set :schema_version, '1.0'
  
  OPEN_STATE_CODES = ['Open', 'Scheduled']
  
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize)
      result = parent.send("find_#{self.parent_type.downcase}", self.parent_id)
      if (!parent_id.blank? && !parent_id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}') && !result.object.blank? && result.object.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
         #This should be handled by the rhodes framework but we have seen a couple of issues
         puts "Updating activity parent_id temp #{parent_id} with #{result.object}"
         update_attributes( :parent_id => result.object)
      end
      result
    end
  end
  
  def opportunity
    parent if parent_type && parent_type.downcase == "opportunity"
  end
  
  def contact
    parent if parent_type && parent_type.downcase == "contact"
  end
  
  def policy
    parent if parent_type && parent_type.downcase == "policy"
  end
  
  def open?
    OPEN_STATE_CODES.include?(self.statecode)
  end
  
  def days_past_due
    DateUtil.days_ago(self.scheduledend) 
  end
  
  def activity_type
    if type == "PhoneCall"
      "Phone Call"
    else
      type
    end
  end
  
  def self.create_new(params)
      new_activity = Activity.create(params)
      new_activity.update_attributes( :temp_id => new_activity.object )

      Activity.local_changed=true

      new_activity
  end
  
  def self.find_activity(id)
    #CR: Pull pattern strings into a constant
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @activity = Activity.find(id)
    else
      id.gsub!(/[{}]/,"")
      @activity = Activity.find_by_sql(%Q{
          select a.* from Activity a where temp_id='#{id}'
        }).first
      @activity
      end
  end
  
  def self.todays_follow_ups(page=nil, page_size=DEFAULT_PAGE_SIZE) 
    find_by_sql(%Q{
        #{SELECT_OPEN_PHONE_CALL_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_END_SQL} = #{NOW_SQL}
        #{SELECT_FIRST_PER_OPPORTUNITY_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.past_due_follow_ups(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_OPEN_PHONE_CALL_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_END_SQL} < #{NOW_SQL}
        #{SELECT_FIRST_PER_OPPORTUNITY_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.future_follow_ups(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_OPEN_PHONE_CALL_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_END_SQL} > #{NOW_SQL}
        #{SELECT_FIRST_PER_OPPORTUNITY_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def notes
        Note.find_by_sql(%Q{
          select n.*
          from Note n 
          where parent_type = 'PhoneCall' and parent_id = '#{object}'
          order by datetime(n.createdon) desc
      })
  end
  
  def phone_type
    self.cssi_phonetype.blank? ?  "Ad Hoc" : self.cssi_phonetype 
  end
  
  def create_note(note_text)
    unless note_text.blank?
      Note.create({
        :notetext => note_text, 
        :createdon => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT),
        :parent_id => self.object,
        :parent_type => 'PhoneCall'
      })
    end
  end

  def self.appointment_type_where_clause(filter)
    case filter
      when 'All'
        "where (a.type='Appointment' or a.type='PhoneCall')"
      when 'ScheduledAppointments'
        "where a.type='Appointment'"
      when 'ScheduledCallbacks'
        "where a.type='PhoneCall'"
      else
        ''
    end
  end
  
  def self.appointment_like_clause(search)
    search_terms = search.split
    like_clause  = ''
    
    if search_terms.count > 0
      like_clause << ' and ('
      search_terms.each do |search_term|
        like_clause << %Q{c.firstname like '#{search_term}%' or c.lastname like '#{search_term}%' or }
      end
      like_clause.chomp!(" or ")
      like_clause << ')'
    end
    
    like_clause
  end
  
  def self.appointment_time_compare(scheduled_time)
    case scheduled_time
      when 'past_due'
        '<'
      when 'future'
        '>'
      else
        '='
    end
  end
  
  def self.appointment_list(page, filter, search, scheduled_time, page_size=DEFAULT_PAGE_SIZE)
    type_where_clause = appointment_type_where_clause(filter)  
    like_clause       = appointment_like_clause(search)
    time_compare      = appointment_time_compare(scheduled_time)
    
    sql = %Q{
        #{SELECT_SCHEDULED_NO_WHERE_SQL} #{type_where_clause} and
        (c.object=o.contact_id) and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_TIME_SQL} #{time_compare} #{NOW_SQL} and
        #{SCHEDULED_OPEN_SQL}
        #{like_clause}
        #{SCHEDULED_ORDERBY_SQL}
        #{get_pagination_sql(page, page_size)}
      }
      
    find_by_sql(sql)
  end

  def complete
    attrs = {
      :statuscode => 'Completed',
      :statecode => 'Completed',
      :actualend => Time.now.strftime(DateUtil::DEFAULT_TIME_FORMAT)
    }
    attrs[:cssi_disposition] = 'Appointment Held' if type == 'Appointment'
    attrs[:statuscode] = 'Made' if type == 'PhoneCall'
    
    Activity.local_changed=true
    
    update_attributes(attrs)
    
  end

  def self.emails
    find_by_sql(%Q{
        #{SELECT_EMAILS_SQL} 
      })
  end

  def self.activities_type_where_clause(type)
    case type
      when 'Task'
        "and a.type = 'Task'"
      when 'Appointment'
        "and a.type = 'Appointment'"
      when 'PhoneCall'
        "and a.type = 'PhoneCall'"
      else
        "and a.type in ('Task', 'Appointment', 'PhoneCall')"
    end
  end

  def self.activities_priority_where_clause(priority)
    case priority
      when 'Normal'
        "and (a.prioritycode is null or a.prioritycode = 'Normal')"
      when 'High'
        "and a.prioritycode = 'High'"
      else
        ""
    end
  end

  def self.activities_date_where_clause(operator)
    case operator
      when '>'
        "and date(scheduledtime) > date('now', 'localtime') and date(scheduledtime) <= date('now', 'localtime', '+8 days')"
      when 'null'
        "and date(scheduledtime) is null"
      else
        "and date(scheduledtime) #{operator} date('now', 'localtime')"
    end
  end

  def self.activities_orderby_clause(operator)
    if (operator == 'null')
      "order by datetime(a.createdon) desc"
    else
      "order by datetime(scheduledtime)"
    end
  end

  def self.activities_sql(type, priority, operator, page, page_size)
    %Q{
        select
            case
                when a.scheduledstart is null then a.scheduledend
                when a.scheduledstart = '' then a.scheduledend
                else a.scheduledstart
            end as scheduledtime,
            a.*
        from Activity a
        where a.statecode in ('Open', 'Scheduled')
            #{activities_date_where_clause(operator)}
            #{activities_type_where_clause(type)}
            #{activities_priority_where_clause(priority)}
        #{activities_orderby_clause(operator)}
        #{get_pagination_sql(page, page_size)}
    }
  end

  def self.past_due_activities(page, type, priority, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(activities_sql(type, priority, '<', page, page_size))
  end

  def self.no_date_activities(page, type, priority, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(activities_sql(type, priority, 'null', page, page_size))
  end

  def self.today_activities(page, type, priority, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(activities_sql(type, priority, '=', page, page_size))
  end

  def self.future_activities(page, type, priority, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(activities_sql(type, priority, '>', page, page_size))
  end

  def parent_contact
    if (parent_type == 'Contact')
      parent
    else
      this_parent = parent if (parent_type == 'Opportunity' || parent_type == 'Policy')
      result = this_parent ? this_parent.contact : nil
      if (!parent_contact_id.blank? && !parent_contact_id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}')  && !result.blank? && result.object.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
         #This should be handled by the rhodes framework but we have seen a couple of issues
         puts "Updating activity parent contact id temp #{parent_contact_id} with #{result.object}"
         update_attributes( :parent_contact_id => result.object)
      end
      result
    end
  end

  def scheduled_time
    scheduledstart.blank? ? scheduledend : scheduledstart
  end

  def self.complete_activities(activity_ids)
    activity_ids.each do |activity_id|
      activity = self.find_activity(activity_id)
      activity.complete if activity
    end
  end
  
  def self.is_activity_type?(type)
    ['phonecall', 'appointment', 'task', 'email'].include?(type.downcase)
  end
end
