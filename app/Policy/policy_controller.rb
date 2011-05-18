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
    @policy = Policy.find(@params['id'])
    if @policy
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Policy/new
  def new
    @policy = Policy.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Policy/{1}/edit
  def edit
    @policy = Policy.find(@params['id'])
    if @policy
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Policy/create
  def create
    @policy = Policy.create(@params['policy'])
    redirect :action => :index
  end

  # POST /Policy/{1}/update
  def update
    @policy = Policy.find(@params['id'])
    @policy.update_attributes(@params['policy']) if @policy
    redirect :action => :index
  end

  # POST /Policy/{1}/delete
  def delete
    @policy = Policy.find(@params['id'])
    @policy.destroy if @policy
    redirect :action => :index  end
end
