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
    if @policy
      @contact = @policy.contact
      puts "*** @contact = " + @contact.inspect + " ***"
      render :action => :show, :back => 'callback:'
    else
      redirect :action => :index
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
