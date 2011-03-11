require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'helpers/application_helper'

class OpportunityController < Rho::RhoController
  include BrowserHelper

  #GET /Opportunity
  def index
    @todays_new_leads = Opportunity.todays_new_leads
    @previous_days_leads = Opportunity.previous_days_leads
    Opportunity.clear_cache
    render :action => :index, :layout => 'layout_JQM_Lite'
  end
  
  def index_follow_up
    @todays_follow_ups = Opportunity.todays_follow_ups
    @past_due_follow_ups = Opportunity.past_due_follow_ups
    @future_follow_ups = Opportunity.future_follow_ups
    @last_activities = Opportunity.last_activities
    #all_opps = [@todays_follow_ups | @past_due_follow_ups].map{|opp| opp.object }
    Opportunity.clear_cache
    render :action => :index_follow_up, :layout => 'layout_JQM_Lite'
  end
  
  def index_appointments
    @past_due_appointments = Appointment.past_due_appointments
    @todays_appointments = Appointment.todays_appointments
    @future_appointments = Appointment.future_appointments
    Appointment.clear_cache
    render :action => :index_appointments, :layout => 'layout_JQM_Lite'
  end
  
  def sync_object_notify
    WebView.refresh
  end
  
  # GET /Opportunity/{1}
  def show
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      @next_id = (@opportunity.object.to_i + 1).to_s
      @prev_id = (@opportunity.object.to_i - 1).to_s
      @contact = @opportunity.contact
      render :action => :show,
              :layout => 'layout_jquerymobile'
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
  
  def status_update
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :status_update,
              :layout => 'layout_jquerymobile'
    else
      redirect :action => :index
    end
  end 
  
  # GET /Opportunity/{1}/activity_summary
  def activity_summary
    @opportunity = Opportunity.find(@params['id'])
    if @opportunity
      render :action => :activity_summary,
              :layout => 'layout_jquerymobile'
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
    Opportunity.sync
    redirect :action => :index
  end

  # POST /Opportunity/{1}/delete
  def delete
    @opportunity = Opportunity.find(@params['id'])
    @opportunity.destroy if @opportunity
    redirect :action => :index
  end
end
