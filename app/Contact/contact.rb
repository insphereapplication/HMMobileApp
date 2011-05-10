

class Contact
  include Rhom::FixedSchema
  include ChangedFlag
  include SQLHelper
  
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
  
  index :contact_pk_index, [:contactid]
  unique_index :unique_contact, [:contactid] 
  
  def self.all_open(page=nil, page_size=DEFAULT_PAGE_SIZE)    
    Contact.find_by_sql(%Q{
      select distinct(c.contactid), c.* from Contact c, Opportunity o 
      where o.contact_id=c.contactid and 
      o.statecode not in ('Won', 'Lost')
      order by LOWER(c.lastname)
      #{get_pagination_sql(page, page_size)}
    })
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
      asl += " " + address1_city + ", " + cssi_state1id
    else
      if(address2_city && cssi_state2id)
        asl += " " + address2_city + ", " + cssi_state2id
      end
    end
    asl
  end
  
  def age_sex
    result = ""
    if gendercode != nil
      result += gendercode
    end
    if(age != nil)
      result += " " + age
    end
    result
  end
  
  def city_summary
    if address1_city
      " #{address1_city}, #{cssi_state1id}, #{address1_postalcode}"
    elsif address2_city
      " #{address2_city}, #{cssi_state2id}, #{address2_postalcode}"
    end
  end
  
  def home_city
    if address1_city
    "#{address1_city}, #{cssi_state1id} #{address1_postalcode}"
    end
  end

  def business_city
    if address2_city
      "#{address2_city}, #{cssi_state2id} #{address2_postalcode}"
    end
  end
  
  def age
    begin
      birthday = Date.strptime(birthdate, DateUtil::DEFAULT_TIME_FORMAT)
       day_diff = Date.today - birthday.day
       month_diff = Date.today.month - birthday.month - (day_diff < 0 ? 1 : 0)
        (Date.today.year - birthday.year - (month_diff < 0 ? 1 : 0)).to_s
    rescue
      puts "Invalid date parameter in age calculation method; no age returned"
    end
  end
  
  def phone_numbers
    {'Home' => telephone2, 'Mobile' => mobilephone, 'Business' => telephone1, 'Alternate' => telephone3 }.reject{|type, number| number.blank? }
  end
  
  def preferred_number
      phone_numbers.each do |type, number|
          if type == cssi_preferredphone
            return number
          end
      end
  end

  
  def phone_numbers_full
    {"Home: #{telephone2}" => telephone2, "Mobile: #{mobilephone}" => mobilephone, "Business: #{telephone1} #{cssi_businessphoneext}" => telephone1, "Alternate: #{telephone3}" => telephone3 }.reject{|type, number| number.blank? }
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
    Opportunity.find(:all, :conditions => {"contact_id" => self.object})
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
  
  
end
