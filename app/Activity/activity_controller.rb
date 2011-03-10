require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'

class ActivityController < Rho::RhoController
  include BrowserHelper
  
  def update_status
    puts 
    puts @params.inspect
    opportunity = Opportunity.find(@params['opportunity_id'])
    puts @params.inspect
    if !opportunity.phone_calls.blank?
      puts "Updating Phone Call"
      phone_call = opportunity.most_recent_phone_call
      phone_call.update_attributes(@params['phone_call'].merge({:disposition_detail => ""}))
    else
      phone_call = PhoneCall.create(
        { :parent_type => 'opportunity', 
          :parent_id => opportunity.opportunityid 
        }.merge(@params['phone_call'].merge({:disposition_detail => ""}))
      )
    end
    
    Activity.sync
    
    redirect :controller => :Opportunity, :action => :index_follow_up
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
