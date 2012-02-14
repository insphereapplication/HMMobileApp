require 'helpers/browser_helper'

class Contact
  include Rhom::FixedSchema
  include ChangedFlag
  include SQLHelper
  
  set :schema_version, '1.0'
  enable :sync
  set :sync_priority, 20
  
  # Note: These property names are derived from the field names in Microsoft Dynamics CRM--to prevent mapping issues
  property :firstname, :string
  property :lastname, :string
  property :gendercode, :string  
  property :birthdate, :string
  property :telephone2, :string #home phone
  property :mobilephone, :string #mobile phone
  property :telephone1, :string #business phone
  property :cssi_businessphoneext, :string #business phone extension
  property :telephone3, :string #alternate phone
  property :cssi_preferredphone, :string #preferred phone type(Business, Home, Mobile, or Alternate)
  property :emailaddress1, :string #email address
  property :address1_line1, :string #home address line 1
  property :address1_line2, :string #home address line 2
  property :address1_city, :string #home address city
  property :cssi_state1id, :string #home address state
  property :address1_postalcode, :string #home address postal code
  property :address2_line1, :string #business address line 1
  property :address2_line2, :string #business address line 2
  property :address2_city, :string #business address city
  property :cssi_state2id, :string #business address state
  property :address2_postalcode, :string 
  property :contactid, :string
  property :cssi_heightft, :string
  property :cssi_heightin, :string
  property :cssi_weight, :string
  property :cssi_usetobacco, :string
  property :familystatuscode, :string
  property :cssi_allowcallsalternatephone, :string
  property :cssi_allowcallsbusinessphone, :string
  property :cssi_allowcallshomephone, :string
  property :cssi_allowcallsmobilephone, :string
  property :cssi_companydncalternatephone, :string
  property :cssi_companydncbusinessphone, :string
  property :cssi_companydnchomephone, :string
  property :cssi_companydncmobilephone, :string
  property :cssi_spousename, :string #start contact spouse information
  property :cssi_spouselastname, :string
  property :cssi_spousebirthdate, :string
  property :cssi_spouseheightft, :string
  property :cssi_spouseheightin, :string
  property :cssi_spouseweight, :string
  property :cssi_spouseusetobacco, :string
  property :cssi_spousegender, :string #end contact spouse information
  property :temp_id, :string
  
  index :contact_pk_index, [:contactid]
  unique_index :unique_contact, [:contactid]
  
  PHONE_TYPES = ["home", "mobile", "business", "alternate"]
  
  # If a contact has a spouse first or spouse last name we consider that the contact has a spouse.
  def has_spouse_info?
    return !cssi_spousename.blank? || !cssi_spouselastname.blank? 
  end
  
  def self.create_new(params)
    new_contact = Contact.create(params)
    new_contact.update_attributes( :temp_id => new_contact.object )
    new_contact
  end
  
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
  
  #given an array of contact ids, returns the IDs that are currently on the device
  def self.find_contacts_on_device(contact_ids)    
    return [] if contact_ids.empty?
        Contact.find_by_sql(%Q{
        select distinct c.object as 'contactid' from Contact c, Opportunity o
        where o.contact_id=c.object and c.object in ('#{contact_ids.join("', '")}')
        union
        select distinct c.object as 'contactid' from Contact c, Policy p
        where p.contact_id=c.object and c.object in ('#{contact_ids.join("', '")}')
        union
        select distinct c.object as 'contactid' from Contact c, Activity a
        where a.parent_contact_id=c.object and c.object in ('#{contact_ids.join("', '")}')
        union
        select distinct c.object as 'contactid' from Contact c, Activity a
        where a.parent_id=c.object and c.object in ('#{contact_ids.join("', '")}')
      }).map{|contact| contact.contactid } 
  end  
  
  def self.get_filtered_contacts(page, filter, search_terms)
    case filter
    when 'all' 
      all_open(page, search_terms)
    when 'active-policies'
      with_policies(page, 'Active', search_terms)
    when 'pending-policies'
      with_policies(page, 'Pending', search_terms)
    when 'open-opps'
      with_open_opps(page, search_terms)
    when 'won-opps'
      with_won_opps(page, search_terms)
    end
  end
  
  def self.all_open(page=nil, terms=nil, page_size=DEFAULT_PAGE_SIZE)  
    Contact.find_by_sql(%Q{
      select distinct c.contactid, c.* from Contact c, Opportunity o 
            where o.contact_id=c.object and 
            o.statecode not in ('Lost') 
            #{get_search_sql(terms)}
      union
      select distinct c.contactid, c.* from Contact c, Policy p where c.object = p.contact_id
      #{get_search_sql(terms)}
      union
      select distinct c.contactid, c.* from Contact c, Activity a where c.object = a.parent_id
      #{get_search_sql(terms)}
      order by lastname collate nocase
      #{get_pagination_sql(page, page_size)}
    })
  end
  
  def self.with_policies(page=nil, statuscode='', terms=nil, page_size=DEFAULT_PAGE_SIZE)    
    Contact.find_by_sql(%Q{
      select distinct c.contactid, c.* from Contact c, Policy p where c.object = p.contact_id and p.statuscode = '#{statuscode}'
      #{get_search_sql(terms)}
      order by lastname collate nocase
      #{get_pagination_sql(page, page_size)}
    })
  end
  
  def self.with_open_opps(page=nil, terms=nil, page_size=DEFAULT_PAGE_SIZE)    
    Contact.find_by_sql(%Q{
      select distinct c.contactid, c.* from Contact c, Opportunity o 
            where o.contact_id=c.object and 
            o.statecode not in ('Won', 'Lost') 
            #{get_search_sql(terms)}
      order by lastname collate nocase
      #{get_pagination_sql(page, page_size)}
    })
  end
  
  def self.with_won_opps(page=nil, terms=nil, page_size=DEFAULT_PAGE_SIZE)    
    Contact.find_by_sql(%Q{
      select distinct c.contactid, c.* from Contact c, Opportunity o 
            where o.contact_id=c.object and 
            o.statecode = 'Won' 
            #{get_search_sql(terms)}
      order by lastname collate nocase
      #{get_pagination_sql(page, page_size)}
    })
  end
  
  def self.get_search_sql(term)
    #terms_ary = terms.split(/[\s,]/).reject{|term| term.blank? }
    #terms_ary = terms
    term.blank? ? '' : "and (c.firstname like '#{term}%' OR c.lastname like '#{term}%' OR c.emailaddress1 like '#{term}%' OR c.telephone1 like '%#{term}%' OR c.telephone2 like '%#{term}%' OR c.telephone3 like '%#{term}%' OR c.mobilephone like '%#{term}%')"
  end
  
  def full_name
    "#{firstname} #{lastname}"
  end
  
  def last_first
    "#{lastname}, #{firstname}"
  end
  
  def home_street
    "#{address1_line1}"
  end
  
  def business_street
    "#{address2_line1}"
  end  

  def age_sex_loc
    asl = ""
    if gendercode != nil
      asl += gendercode[0,1]
    end
    if(age != nil)
      asl += " " + age
    end
    if(address1_city && cssi_state1id)
      state = cssi_state1id.blank? ? "" : ", " + cssi_state1id
      asl += " " + address1_city + state
    else
      if(address2_city && cssi_state2id)
        state = cssi_state2id.blank? ? "" : ", " + cssi_state2id
        asl += " " + address2_city + state
      end
    end
    asl
  end
  
  def age_sex(label = false)
    result = ""
    if gendercode != nil
      result += gendercode
    end
    if(age != nil)
      space = label ? result.blank? ? "Age " : ", Age " : " "
      result += space + age
    end
    result
  end
  
  def city_summary
    if address1_city
      state = cssi_state1id.blank? ? "" : ", " + cssi_state1id
      zip = address1_postalcode.blank? ? "" : ", " + address1_postalcode
      " #{address1_city}#{state}#{zip}"
    elsif address2_city
      state = cssi_state2id.blank? ? "" : ", " + cssi_state2id
      zip = address2_postalcode.blank? ? "" : ", " + address2_postalcode
      " #{address2_city}#{state}#{zip}"
    end
  end
  
  def home_city
    if address1_city
      state = cssi_state1id.blank? ? "" : ", " + cssi_state1id
      "#{address1_city}#{state} #{address1_postalcode}"
    end
  end

  def business_city
    if address2_city
      state = cssi_state2id.blank? ? "" : ", " + cssi_state2id
      "#{address2_city}#{state} #{address2_postalcode}"
    end
  end
  
  def show_home_address
    if !address1_line1.blank? || !address1_line2.blank? || !address1_city.blank? || !cssi_state1id.blank? || !address1_postalcode.blank?
      true
    else
      false
    end
  end

  def show_business_address
    if !address2_line1.blank? || !address2_line2.blank? || !address2_city.blank? || !cssi_state2id.blank? || !address2_postalcode.blank?
      true
    else
      false
    end
  end
  
  def age
    begin
      birthday = Date.strptime(birthdate, DateUtil::DEFAULT_TIME_FORMAT)
       day_diff = Date.today - birthday.day
       month_diff = Date.today.month - birthday.month - (day_diff < 0 ? 1 : 0)
        (Date.today.year - birthday.year - (month_diff < 0 ? 1 : 0)).to_s
    rescue
    end
  end
  
  def spouse_age
    begin
      birthday = Date.strptime(cssi_spousebirthdate, DateUtil::DEFAULT_TIME_FORMAT)
       day_diff = Date.today - birthday.day
       month_diff = Date.today.month - birthday.month - (day_diff < 0 ? 1 : 0)
        (Date.today.year - birthday.year - (month_diff < 0 ? 1 : 0)).to_s
    rescue
    end
  end  
  
  def business_phone
    phone_number = telephone1
    phone_number += " x#{cssi_businessphoneext}" unless cssi_businessphoneext.blank?
    phone_number
  end
  
  def phone_numbers
    {'Home' => telephone2, 'Mobile' => mobilephone, 'Business' => business_phone, 'Alternate' => telephone3 }.reject{|type, number| number.blank? }
  end
  
  def preferred_phone_type?(phone_type)
    if cssi_preferredphone && phone_type && cssi_preferredphone.downcase == phone_type.downcase
      true
    else
      false
    end
  end
  
  def do_not_call?(phone_type)
    raise "Invalid phone type #{phone_type}" unless PHONE_TYPES.include?(phone_type.downcase)
    allow_calls = self.send("cssi_allowcalls#{phone_type.downcase}phone".to_sym)
    company_dnc = self.send("cssi_companydnc#{phone_type.downcase}phone".to_sym)
    puts "*"*80
    puts "Type: #{phone_type}, Allow calls: #{allow_calls}, company DNC: #{company_dnc}"
    allow_calls == "False" || company_dnc == "True"
  end
  
  def preferred_number
      phone_numbers.each do |type, number|
          if preferred_phone_type?(type)
            return number
          end
      end
  end
  
  def addresses
    {'Home' => "#{address1_line1} #{address1_line2} #{address1_city} #{cssi_state1id} #{address1_postalcode}".strip, 'Business' => "#{address2_line1} #{address2_line2} #{address2_city} #{cssi_state2id} #{address2_postalcode}".strip }.reject{|type, address| address.blank? }
  end
  
  def default_address
    addresses.each do |type, address|
      return address
    end
    return ""
  end
  
  def default_number
    phone_numbers.each do |type, number|
        if type == cssi_preferredphone
          return number
        end
    end
    return ""
  end
  
  def opportunities
    Opportunity.find(:all, :conditions => {"contact_id" => self.object, "ownerid" => StaticEntity.system_user_id})
  end
  
  def policies
    Policy.find(:all, :conditions => {"contact_id" => self.object})
  end
  
  def dependents
    Dependent.find(:all, :conditions => {"contact_id" => self.object})
  end
  
  def business_map
    begin
        return ("#{address2_line1}+#{address2_city}+#{cssi_state2id}+#{address2_postalcode}").gsub!(" ","+")
    rescue
        puts "Could not generate business map string; Value is #{}"
    end
  end
  
  def home_map
    begin
        return ("#{address1_line1}+#{address1_city}+#{cssi_state1id}+#{address1_postalcode}").gsub!(" ","+")
    rescue
        puts "Could not generate home_map map string; Value is #{}"
    end
  end
  
  def map_phone_numbers
    phone_numbers.map{ |type, number|
      do_not_call = do_not_call?(type)
      preferred = preferred_phone_type?(type)
      yield(type,number,do_not_call,preferred)
	  }
  end
  
  
  def activity_list
    Activity.find_by_sql(%Q{
       select * from Activity where (parent_type = 'Contact' and parent_id = '#{self.object}' ) or 
       (parent_type = 'Opportunity' and parent_id in (select object from Opportunity where contact_id = '#{self.object}')) or
       (parent_type = 'Policy' and parent_id in (select object from Policy where contact_id = '#{self.object}'))
      })
  end
end
