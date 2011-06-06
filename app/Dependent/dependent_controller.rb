require 'rho/rhocontroller'
require 'helpers/browser_helper'

class DependentController < Rho::RhoController
  include BrowserHelper

  #GET /Dependent
  def index
    @dependents = Dependent.find_dependent(:all)
    render :back => '/app'
  end

  # GET /Dependent/{1}
  def show
    @dependent = Dependent.find_dependent(@params['id'])
    if @dependent
      @contact = @dependent.contact
      render :action => :show, :back => 'callback:', :origin => @params['origin'], :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end

  # GET /Dependent/new
  def new
    @contact = Contact.find_contact(@params['id'])
    @dependent = Dependent.new
    render :action => :new, :back => 'callback:', :origin => @params['origin'], :layout => 'layout_jquerymobile'
  end

  # GET /Dependent/{1}/edit
  def edit
    @dependent = Dependent.find_dependent(@params['id'])
    if @dependent
      render :action => :edit, :back => 'callback:', :origin => @params['origin'], :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end

  # POST /Dependent/create
  def create
    puts "********** Calling DependentController.create **********"
    puts "********** origin = #{@params['origin']}"
    @dependent = Dependent.create_new(@params['dependent'])
    @dependent.update_attributes(:cssi_dateofbirth => DateUtil.birthdate_build(@dependent.cssi_dateofbirth))
    @dependent.update_attributes(:cssi_age => age(@dependent.cssi_dateofbirth))
    SyncEngine.dosync
    render :controller => :Contact, :action => :show, :origin => @params['origin'], :id => @dependent.contact_id
  end

  # POST /Dependent/{1}/update
  def update
    puts "********** Calling DependentController.update **********"
    puts "********** attributes = #{@params['dependent']}"
    puts "********** id = #{@params['id']}"
    @dependent = Dependent.find_dependent(@params['id'])
    @dependent.update_attributes(@params['dependent']) if @dependent
    @dependent.update_attributes(:contact_id => @dependent.contact_id) if @dependent
    
    # We need to always "update" these fields to make sure the date format gets changed correctly. Age needs to always
    # be recalculated as well since we don't truly know if it changed or not.
    @dependent.update_attributes(:cssi_dateofbirth => DateUtil.birthdate_build(@dependent.cssi_dateofbirth))
    @dependent.update_attributes(:cssi_age => age(@dependent.cssi_dateofbirth))
    
    SyncEngine.dosync
    render :controller => :Contact, :action => :show, :origin => @params['origin'], :id => @dependent.contact_id
  end


  # POST /Dependent/{1}/delete
  def delete
    @dependent = Dependent.find_dependent(@params['id'])
    @dependent.destroy if @dependent
    redirect :action => :index
  end
  
  def confirm_dependent_delete
    Alert.show_popup ({
        :message => "Click OK to Delete this Dependent", 
        :title => "Confirm Delete", 
        :buttons => ["Cancel", "Ok",],
        :callback => url_for(:action => :dependent_delete, 
                                        :query => {
				                                :id => @params['id'],
				                                :origin => @params['origin']
				                                })
				                   })
  end
  
  def dependent_delete
    if @params['button_id'] == "Ok"
      @dependent = Dependent.find_dependent(@params['id'])
      contactid = @dependent.contact_id
      @dependent.destroy if @dependent
      SyncEngine.dosync
      WebView.navigate(url_for :controller => :Contact, :action => :show, :id => contactid, :query => {:origin => @params['origin']})
    else
      WebView.navigate(url_for :controller => :Dependent, :action => :edit, :id => @params['id'], :query => {:origin => @params['origin']})
    end 
  end
  
  def age(dob)
    begin
      puts dob.inspect
      birthdate = Date.parse(dob)
       day_diff = Date.today - birthdate.day
       month_diff = Date.today.month - birthdate.month - (day_diff < 0 ? 1 : 0)
       (Date.today.year - birthdate.year - (month_diff < 0 ? 1 : 0)).to_s
    rescue
      puts "Invalid date parameter in age calculation method; no age returned"
    end
  end
end