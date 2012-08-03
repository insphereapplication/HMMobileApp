require 'helpers/browser_helper'

# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Dependent
  include Rhom::FixedSchema
  
  enable :sync
  set :sync_priority, 70

  property :contact_id, :string
  property :cssi_age, :string
  property :cssi_comments, :string
  property :cssi_dateofbirth, :string
  property :cssi_dependentsid, :string
  property :cssi_gender, :string
  property :cssi_heightft, :string
  property :cssi_heightin, :string
  property :cssi_lastname, :string
  property :cssi_name, :string
  property :cssi_usetobacco, :string
  property :cssi_weight, :string
  property :temp_id, :string
  
  belongs_to :contact_id, 'Contact'

  def contact
    contact = Contact.find_contact(self.contact_id)
    if (!contact_id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}') && contact.object.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
       #This should be handled by the rhodes framework but we have seen a couple of issues
       puts "Updating dependent contact id temp #{contact_id} with #{contact.object}"
       update_attributes( :contact_id => contact.object)
    end
    contact
  end
  
  def self.create_new(params)
    # capitalize names
    params['cssi_name'] = params['cssi_name'].capitalize_words if params['cssi_name']
    params['cssi_lastname'] = params['cssi_lastname'].capitalize_words if params['cssi_lastname']
    new_dependent = Dependent.create(params)
    new_dependent.update_attributes( :temp_id => new_dependent.object )
    new_dependent
  end
  
  def self.find_dependent(id)
    
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @dependent = Dependent.find(id)
    else
      id.gsub!(/[{}]/,"")
      @dependent = Dependent.find_by_sql(%Q{
          select d.* from Dependent d where temp_id='#{id}'
        }).first
      @dependent
      end
  end
  
  def self.find_contact(id)
    
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @contact = Contact.find(id)
    else
      id.gsub!(/[{}]/,"")
      @contact = Contact.find_by_sql(%Q{
          select c.* from Contact c where temp_id='#{id}'
        }).first  
      update_contact_id(@contact.object) if (contact.object.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @contact
      end
  end
  
  def update_contact_id(id)
    puts "contact id: #{id} should have been updated by the rhodes frame, but is a fix incase it does not get updated."
    @dependent.update_attributes( :contact_id => id )
  end
end
