require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ApplicationDetailController < Rho::RhoController
  include BrowserHelper


  #GET /ApplicationDetail
  def index
    @appdetail = ApplicationDetail.find_application(:all)
    render :back => '/app'
  end

  # GET /ApplicationDetail/{1}
  def show
    Settings.record_activity
    @appdetail = ApplicationDetail.find_application(@params['id'])
    @opportunity = Opportunity.find_opportunity(@params['opportunity'])
    if @appdetail && @opportunity
      render :action => :show, :back => 'callback:', :origin => @params['origin'], :layout => 'layout'
    else
      WebView.navigate(url_for(:controller => :Opportunity, :action => :index, :back => 'callback:', :layout => 'layout_jqm_opportunity_list'))  
    end
  end

  # GET /ApplicationDetail/new
  def new
    Settings.record_activity
    @opportunity = Opportunity.find_opportunity(@params['id'])
    @appdetail = ApplicationDetail.new
    render :action => :new, :back => 'callback:', :origin => @params['origin'], :layout => 'layout'
  end

  # GET /ApplicationDetail/{1}/edit
  def edit
    Settings.record_activity
    @appdetail = ApplicationDetail.find_application(@params['id'])
    if @appdetail
      render :action => :edit, :back => 'callback:', :origin => @params['origin'], :layout => 'layout'
    else
      redirect :action => :index
    end
  end

  # POST /ApplicationDetail/create
  def create
    Settings.record_activity
    puts "********** Calling ApplicationDetailController.create **********"
    puts "********** origin = #{@params['origin']}"
    appdatetime = DateTime.strptime(@params['cssi_applicationdate'].to_s, DateUtil::BIRTHDATE_PICKER_TIME_FORMAT)
    @appdetail = ApplicationDetail.create_new(@params['appdetail'].merge({:cssi_applicationdate => appdatetime.strftime(DateUtil::DEFAULT_TIME_FORMAT)}))
    Rho::RhoConnectClient.doSync
    redirect :controller => :Opportunity, :action => :won, :query => {:origin => @params['origin'], :id => @appdetail.opportunity_id}
  end

  # POST /ApplicationDetail/{1}/update
  def update
    Settings.record_activity
    puts "********** Calling ApplicationDetailController.update **********"
    puts "********** id = #{@params['appdetail'].inspect}"
    puts @params['cssi_applicationdate'].inspect
    appdatetime = DateTime.strptime(@params['cssi_applicationdate'].to_s, DateUtil::BIRTHDATE_PICKER_TIME_FORMAT)
    @appdetail = ApplicationDetail.find_application(@params['id'])
    @appdetail.update_attributes(@params['appdetail'].merge({:cssi_applicationdate => appdatetime.strftime(DateUtil::DEFAULT_TIME_FORMAT)})) if @appdetail    
	Rho::RhoConnectClient.doSync(false,'',false)
    redirect :controller => :Opportunity, :action => :won, :query => {:origin => @params['origin'], :id => @appdetail.opportunity_id, :opportunity => @params['opportunity']}
  end


  # POST /ApplicationDetail/{1}/delete
  def delete
    Settings.record_activity
    @appdetail = ApplicationDetail.find_application(@params['id'])
    @appdetail.destroy if @appdetail
    redirect :action => :index
  end
  
  def confirm_app_detail_delete
    Alert.show_popup ({
        :message => "Click OK to Delete this Application", 
        :title => "Confirm Delete", 
        :buttons => ["Cancel", "Ok",],
        :callback => url_for(:action => :app_detail_delete, 
                                        :query => {
				                                :id => @params['id'],
				                                :origin => @params['origin'],
				                                :opportunity => @params['opportunity']
				                                })
				                   })
  end
  
  def app_detail_delete
    if @params['button_id'] == "Ok"
      @appdetail = ApplicationDetail.find_application(@params['id'])
      opportunityid = @appdetail ? @appdetail.opportunity_id : @params['opportunity'] 
      @appdetail.destroy if @appdetail
      Rho::RhoConnectClient.doSync
      WebView.navigate(url_for :controller => :Opportunity, :action => :won, :id => opportunityid, :origin => @params['origin'], :opportunity => opportunityid)
    else
      WebView.executeJavascript("hideSpin();")
    end 
  end
end
