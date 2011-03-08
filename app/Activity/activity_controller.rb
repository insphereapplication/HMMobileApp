require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ActivityController < Rho::RhoController
  include BrowserHelper
  
  def update_status
    opportunity = Opportunity.find(@params['opportunityid'])
    phone_call = opportunity.create_or_find_earliest_phone_call
    phone_call.cssi_disposition = @params['disposition']
    phone_call.update
    SyncEngine.dosync
    redirect :controller => :opportunity, :action => :show, :id => opportunity.object
  end

  #GET /Activity
  def index
    @activities = Activity.find(:all)
    render
  end

  # GET /Activity/{1}
  def show
    @activity = Activity.find(@params['id'])
    if @activity
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Activity/new
  def new
    @activity = Activity.new
    render :action => :new
  end

  # GET /Activity/{1}/edit
  def edit
    @activity = Activity.find(@params['id'])
    if @activity
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Activity/create
  def create
    @activity = Activity.create(@params['activity'])
    redirect :action => :index
  end

  # POST /Activity/{1}/update
  def update
    @activity = Activity.find(@params['id'])
    @activity.update_attributes(@params['activity']) if @activity
    redirect :action => :index
  end

  # POST /Activity/{1}/delete
  def delete
    @activity = Activity.find(@params['id'])
    @activity.destroy if @activity
    redirect :action => :index
  end
end
