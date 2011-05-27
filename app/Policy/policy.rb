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
  
  def contact
    Contact.find(self.contact_id)
  end
end
