class Contact
  include Rhom::PropertyBag

  #enable :sync
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
  

  def self.seed_db(number)
    #Norton, Kyle - Pariveda Solutions - 22 Feb 2011
    #Purpose: Used in testing to populate dummy list of contacts
    
    #clean db
    Rhom::Rhom.database_full_reset    

    #db transaction wrapper
    db = ::Rho::RHO.get_src_db('Contact')
    db.start_transaction
    begin
      i=0
      while i < number
      
        tempContact = {} #contact hash
        tempContact["object"] = i.to_s  #set parameters
        tempContact["firstname"] = "First"
        tempContact["lastname"] = "Last"+i.to_s
        tempContact["gendercode"] = "Male"
        tempContact["birthdate"] = "01/01/190" + i.to_s 
        tempContact["telephone2"] = "832-515-7955" + i.to_s #home phone
        tempContact["mobilephone"] = "832-515-7955" + i.to_s
        tempContact["telephone1"] = "832-515-7955" + i.to_s #business phone
         tempContact["cssi_businessphoneext"] = "1234" + i.to_s
        tempContact["telephone3"] = "832-515-7955" + i.to_s #alternate phone
        tempContact["cssi_preferredphone"] = "Home" #preferred phone number type
        tempContact["emailaddress1"] = "fake-email@aol.com" #email address
        tempContact["address1_line1"] = "123 fake st" #home address line 1
        tempContact["address1_line2"] = "#1111" #home address line 2
        tempContact["address1_city"] = "Yourtown" # home address city
        tempContact["cssi_state1id"] = "CA" #home address state
        tempContact["address1_postalcode"] = "11111" #home zip
        tempContact["address2_line1"] = "123 Biz Avenue" #business address line 1
        tempContact["address2_line2"] = "Ste 200" # business address line 2
        tempContact["address2_city"] = "Businessville" #business address city
        tempContact["cssi_state2id"] = "BZ" #business address state
        tempContact["address2_postalcode"] = "22222" #business address zip
        
        Contact.create(tempContact) #add contact to db table
        
        i=i+1
      end
      db.commit
    rescue
      db.rollback
    end
  end
end
