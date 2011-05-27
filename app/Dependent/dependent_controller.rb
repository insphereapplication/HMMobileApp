require 'rho/rhocontroller'
require 'helpers/browser_helper'

class DependentController < Rho::RhoController
  include BrowserHelper

  #GET /Dependent
  def index
    @dependents = Dependent.find(:all)
    render :back => '/app'
  end

  # GET /Dependent/{1}
  def show
    @dependent = Dependent.find(@params['id'])
    if @dependent
      @contact = @dependent.contact
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Dependent/new
  def new
    @contact = Contact.find(@params['id'])
    @dependent = Dependent.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Dependent/{1}/edit
  def edit
    @dependent = Dependent.find(@params['id'])
    if @dependent
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Dependent/create
  def create
    puts "********** Calling DependentController.create **********"
    puts "********** attributes = #{@params['dependent']}"
    @dependent = Dependent.create(@params['dependent'])
    @dependent.update_attributes(:cssi_dateofbirth => DateUtil.birthdate_build(@dependent.cssi_dateofbirth))
    @dependent.update_attributes(:cssi_age => age(@dependent.cssi_dateofbirth))
    SyncEngine.dosync
    redirect :controller => :Contact, :action => :show, :id => @dependent.contact_id
  end

  # POST /Dependent/{1}/update
  def update
    puts "********** Calling DependentController.update **********"
    puts "********** attributes = #{@params['dependent']}"
    @dependent = Dependent.find(@params['id'])
    @dependent.update_attributes(@params['dependent']) if @dependent
    redirect :action => :index
  end

  # POST /Dependent/{1}/delete
  def delete
    @dependent = Dependent.find(@params['id'])
    @dependent.destroy if @dependent
    redirect :action => :index  end
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
      @dependent = Dependent.find(@params['id'])
      @dependent.destroy if @dependent
      WebView.navigate(url_for :controller => :Contact, :action => :show, :id => @dependent.cssi_dependentsid, :query => {:origin => @params['origin']})
    else
      WebView.navigate(url_for :controller => :Dependent, :action => :dependent_edit, :id => @params['id'], :query => {:origin => @params['origin']})
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
