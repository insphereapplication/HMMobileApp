# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class ApplicationDetail
  include Rhom::FixedSchema

  enable :sync
  set :sync_priority, 80

  property :cssi_applicationid, :string
  property :cssi_applicationssubmitted, :string
  property :opportunity_id, :string
  property :cssi_carrierid, :string  
  property :cssi_applicationdate, :string
  property :cssi_lineofbusinessid, :string
  property :cssi_avforapplicationsubmitted, :string
  property :cssi_fromrhosync, :string
  property :temp_id, :string
  
  belongs_to :opportunity_id, 'Opportunity'

  # def opportunity
  #   Opportunity.find_opportunity(self.opportunityid)
  # end
  
  def self.create_new(params)
      new_application = ApplicationDetail.create(params)
      new_application.update_attributes( :temp_id => new_application.object)
      new_application
  end
  
  def self.find_application(id)
    id.gsub!(/[{}]/,"")
    if (id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
      @appdetail = ApplicationDetail.find(id)
    else 
      @appdetail = ApplicationDetail.find_by_sql(%Q{
          select a.* from ApplicationDetail a where temp_id='#{id}'
        }).first
      @appdetail
      end
  end
  
  def self.find_application_by_opportunity(id, temp_id)
   if temp_id.blank?
    @applications = ApplicationDetail.find(
      :all, 
      :conditions => {"opportunity_id" => "#{id}"}
     )
   else
     @applications = ApplicationDetail.find(:all, :conditions => {{:name => "opportunity_id", :op => "IN"} => ["#{id}","#{temp_id}"]})   
     @applications.each do |appdetail| 
        if (!appdetail.blank? && !appdetail.opportunity_id.blank? && !appdetail.opportunity_id.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}') && id.upcase.match('[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}'))
           #This should be handled by the rhodes framework but we have seen a couple of issues
           puts "Updating application detail opportunity id temp #{appdetail.opportunity_id} with #{id}"
           appdetail.update_attributes( :opportunity_id => id)
        end
     end
   end
   @applications
  end

end
