class Activity
  include Rhom::FixedSchema
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
  property :cssi_disposition, :string
  property :statuscode, :string
  property :location, :string
  property :cssi_location, :string
  property :description, :string
  property :cssi_dispositiondetail, :string
  property :parent_contact_id, :string
  property :createdon, :string
  property :temp_id, :string
  
  index :activity_pk_index, [:activityid]
  unique_index :unique_activity, [:activityid] 
  
  index :activity_parent_index, [:parent_id, :parent_type]
  index :activity_statuscode_index, [:statuscode]
  index :activity_statecode_index, [:statecode]
  
  enable :sync
  set :sync_priority, 40 # this needs to be loaded before opportunities so that opportunities can know their context
  
  set :schema_version, '1.0'
  
  OPEN_STATE_CODES = ['Open', 'Scheduled']
  
  def parent
    if self.parent_type && self.parent_id
      parent = Object.const_get(self.parent_type.capitalize) 
      parent.find(:first, :conditions => {"#{self.parent_type.downcase}id" => self.parent_id})
    end
  end
  
  def opportunity
    parent if parent && parent_type.downcase == "opportunity"
  end
  
  def contact
    parent if parent && parent_type.downcase == "contact"
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
      new_activity
  end
  
  def self.find_activity(id)
    
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
  
  
# end

# class PhoneCall < Activity
  
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
# end

# class Appointment < Activity
  
  def self.past_due_scheduled(page=nil, page_size=DEFAULT_PAGE_SIZE)   
    find_by_sql(%Q{
        #{SELECT_SCHEDULED_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_TIME_SQL} < #{NOW_SQL}and 
        #{SCHEDULED_OPEN_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.future_scheduled(page=nil, page_size=DEFAULT_PAGE_SIZE)    
    find_by_sql(%Q{
        #{SELECT_SCHEDULED_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_TIME_SQL} > #{NOW_SQL} and 
        #{SCHEDULED_OPEN_SQL} 
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def self.todays_scheduled(page=nil, page_size=DEFAULT_PAGE_SIZE)
    find_by_sql(%Q{
        #{SELECT_SCHEDULED_SQL} and
        #{OWNED_BY_OPEN_OPPORTUNITY_SQL} and
        #{SCHEDULED_TIME_SQL} = #{NOW_SQL}and 
        #{SCHEDULED_OPEN_SQL}
        #{get_pagination_sql(page, page_size)}
      })
  end
  
  def complete
    update_attributes({
      :statuscode => 'Completed',
      :statecode => 'Completed',
      :cssi_disposition => 'Appointment Held'
    })
  end
  
end
