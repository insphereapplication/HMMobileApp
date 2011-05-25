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
      @contact = @policy.contact
      puts "*** @contact = " + @contact.inspect + " ***"
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Dependent/new
  def new
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
    @dependent = Dependent.create(@params['dependent'])
    redirect :action => :index
  end

  # POST /Dependent/{1}/update
  def update
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
