require 'rho/rhocontroller'
require 'helpers/browser_helper'

class PolicyController < Rho::RhoController
  include BrowserHelper

  #GET /Policy
  def index
    @policies = Policy.find(:all)
    render :back => '/app'
  end

  # GET /Policy/{1}
  def show
    Settings.record_activity
    @policy = Policy.find_policy(@params['id'])
    if Settings.pin_confirmed == true && @policy
      @contact = @policy.contact
      render :action => :show, :back => 'callback:', :query => {:origin => @params['origin'], :activity => @params['activity']}
    else
      if @params['origin'] == 'activity'
        redirect :controller => :Activity, :action => :show, :id => @params['activity'], :query => {:origin => @params['origin'], :opportunity => @params['opportunity']}
      else    
        redirect :controller => :Contact, :action => :show, :id => @params['contact'], :query => {:origin => @params['origin'], :opportunity => @params['opportunity']}
      end
    end
  end

  # GET /Policy/new
  def new
    @policy = Policy.new
    render :action => :new, :back => 'callback:'
  end

  # GET /Policy/{1}/edit
  def edit
    @policy = Policy.find_policy(@params['id'])
    if @policy
      render :action => :edit, :back => 'callback:'
    else
      redirect :action => :index
    end
  end

  # POST /Policy/create
  def create
    @policy = Policy.create_new(@params['policy'])
    redirect :action => :index
  end

  # POST /Policy/{1}/update
  def update
    @policy = Policy.find_policy(@params['id'])
    @policy.update_attributes(@params['policy']) if @policy
    redirect :action => :index
  end

  # POST /Policy/{1}/delete
  def delete
    @policy = Policy.find_policy(@params['id'])
    @policy.destroy if @policy
    redirect :action => :index  end
end
