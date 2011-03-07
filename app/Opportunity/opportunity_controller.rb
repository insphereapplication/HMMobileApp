require 'rho/rhocontroller'
require 'helpers/browser_helper'

class OpportunityController < Rho::RhoController
  include BrowserHelper

  #GET /Opportunity
  def index
    @new_leads = Opportunity.new_leads
    render :action => :index, :layout => 'layout_JQM_Lite'
  end
  
  def index_follow_up
    @todays_follow_ups = Opportunity.todays_follow_ups
    @past_due_follow_ups = Opportunity.past_due_follow_ups
    @future_follow_ups = Opportunity.future_follow_ups
    @last_activities = Opportunity.last_activities
    render :action => :index_follow_up, :layout => 'layout_JQM_Lite'
  end
  
  def index_appointments
    @open_appointments = Appointment.open_appointments
    render :action => :index_appointments, :layout => 'layout_JQM_Lite'
  end

  # GET /Opportunity/{1}
  def show
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Opportunity/new
  def new
    @opportunity = Opportunity.new
    render :action => :new
  end

  # GET /Opportunity/{1}/edit
  def edit
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Opportunity/create
  def create
    @opportunity = Opportunity.create(@params['opportunity'])
    redirect :action => :index
  end

  # POST /Opportunity/{1}/update
  def update
    @opportunity = Opportunity.find(@params['id'])
    @opportunity.update_attributes(@params['opportunity']) if @opportunity
    redirect :action => :index
  end

  # POST /Opportunity/{1}/delete
  def delete
    @opportunity = Opportunity.find(@params['id'])
    @opportunity.destroy if @opportunity
    redirect :action => :index
  end
end
