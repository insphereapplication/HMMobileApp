require 'rho/rhocontroller'
require 'helpers/browser_helper'

class OpportunityController < Rho::RhoController
  include BrowserHelper

  #GET /Opportunity
  def index
    @new_lead_contacts = Opportunity.find(:all).map{|opp| opp.contact }
    puts @new_leads.inspect
    render :action => :index, :layout => 'layout_JQM_Lite'
  end
  
  def index_follow_up
    @opportunities = Opportunity.find(:all)
    render :action => :index_follow_up,
            :layout => 'layout_JQM_Lite'
  end
  
  def index_appointments
    @opportunities = Opportunity.find(:all)
    render :action => :index_appointments,
            :layout => 'layout_JQM_Lite'
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
