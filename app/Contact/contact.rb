require '/initializers/object_extension'

class Contact
  include Rhom::PropertyBag

  enable :sync
  set :sync_priority, 2
  #Note: These property names are derived from the field names in Microsoft Dynamics CRM--to prevent mapping issues
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
  
  def full_name
    "#{firstname} #{lastname}"
  end
  
  def last_first
      "#{lastname}, #{firstname}"
  end
  
#RETURNS A DESCRIPTIVE SUMMARY FOR THE CONTACT
  def age_sex_loc
    asl = ""
    if gendercode != nil
      asl += gendercode[0,1]
    end
    if(age != nil)
      asl += " " + age
    end
    if(address1_city != nil)
      asl += " " + address1_city + ", " + cssi_state1id
    else
      if(address2_city != nil)
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
  
  def age
    begin
      birthday = Date.strptime(birthdate, "%m/%d/%Y")
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
  
  def phone_numbers_full
    {"Home: #{telephone2}" => telephone2, "Mobile: #{mobilephone}" => mobilephone, "Business: #{telephone1} #{cssi_businessphoneext}" => telephone1, "Alternate: #{telephone3}" => telephone3 }.reject{|type, number| number.blank? }
  end
  
  def addresses
    {'Home' => "#{address1_line1} #{address1_line2} #{address1_city}, #{cssi_state1id} #{address1_postalcode}", 'Business' => "#{address2_line1} #{address2_line2} #{address2_city}, #{cssi_state2id} #{address2_postalcode}" }.reject{|type, address| address.blank? }
  end
  
  def default_address
    addresses.each do |type, address|
      return address
    end
  end
  
  def default_number
    phone_numbers.each do |type, number|
      if type = cssi_preferredphone
        return number
      end
    end
  end
  
  
  def opportunities
    Opportunity.find(
     :all, 
     :conditions => [ 
       "contact_id = #{self.contactid}", 
       query, 
       query
     ], 
     :select => ['title','description'] 
    )
  end
  
  def business_map
    begin
    result = ""
    if address2_line1 && address2_city && cssi_state2id
      result += address2_line1 << "+" << address2_city << "+" << cssi_state2id
    end
    rescue
      puts "Could not generate business map string; Value is #{}"
    end
  end
end
