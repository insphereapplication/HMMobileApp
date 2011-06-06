# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Policy
  include Rhom::FixedSchema

  enable :sync
  set :sync_priority, 60
  
  property :contact_id, :string
  property :cssi_policyid, :string #
  property :product_id, :string #
  property :product_name, :string #
  property :carrier_id, :string #
  property :carrier_name, :string #
  property :cssi_primaryinsured, :string #
  property :statuscode, :string #
  property :statecode, :string
  property :cssi_statusreason, :string #
  property :cssi_carrierstatusvalue, :string #
  property :cssi_applicationnumber, :string #
  property :cssi_applicationdate, :string #
  property :cssi_submitteddate, :string #
  property :cssi_policynumber, :string #
  property :cssi_effectivedate, :string #
  property :cssi_paymentmode, :string #
  property :cssi_annualpremium, :string #
  property :cssi_insuredtype, :string #
  
  property :modifiedon, :string
  property :temp_id, :string
  
  def contact
    Contact.find_contact(self.contact_id)
  end
  
  def self.create_new(params)
      new_policy = Policy.create(params)
      new_policy.update_attributes( :temp_id => new_policy.object )
      new_policy
  end
  
  def self.find_policy(id)
    
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @policy = Policy.find(id)
    else
      id.gsub!(/[{}]/,"")
      @policy = Policy.find_by_sql(%Q{
          select p.* from Policy p where temp_id='#{id}'
        }).first
      @policy
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
      @contact
      end
  end
end
