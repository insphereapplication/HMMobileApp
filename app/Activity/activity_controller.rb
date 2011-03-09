require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ActivityController < Rho::RhoController
  include BrowserHelper
  
  def update_status
    puts "UPDATE STATUS: #{@params.inspect}"
    opportunity = Opportunity.find(@params['id'])
    puts "OPPORTUNITY: #{opportunity.inspect}"
    if opportunity
       puts "CREATE OR FIND"
        if opportunity.phone_calls.size > 0
          puts "FOUND PHONE CALLS #{opportunity.opportunityid}"
          return phone_calls.compact.date_sort(:scheduledstart).first
        else
          puts "CREATING NEW PHONE CALL: #{opportunity.opportunityid}"
          phone_call = Activity.create('type' => 'PhoneCall', 'cssi_disposition' => @params['disposition'], 'parent_id' => opportunity.opportunityid, 'parent_type' => 'Opportunity')
          puts "CREATED PHONE CALL: #{phone_call.inspect}"
          Activity.sync
          puts "SYNCED"
        end
      redirect :controller => :Opportunity, :action => :show, :id => opportunity.object
    end
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
