require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ContactController < Rho::RhoController
  include BrowserHelper
  layout :layout_jquerymobile

  #GET /Contact
  def index
    puts "INDEX!!"
    @contacts = Contact.find(:all)
  end

  # GET /Contact/{1}
  def show
    @contact = Contact.find(@params['id'])
    if @contact
      @next_id = (@contact.object.to_i + 1).to_s
      @prev_id = (@contact.object.to_i - 1).to_s
      render :action => :show,
              :layout => 'layout_jquerymobile'     
    else
      redirect :action => :index
    end
  end
  
  def seed_db_150
    #Norton, Kyle - Pariveda Solutions - 22 Feb 2011
    #Purpose: Used to seed database with a test set of contacts
    Contact.seed_db(150)
    WebView.navigate('/app?msg=Seeded%20Database%20with%20150%20contacts')
  end

  # GET /Contact/new
  def new
    @contact = Contact.new
    render :action => :new
  end

  # GET /Contact/{1}/edit
  def edit
    @contact = Contact.find(@params['id'])
    if @contact
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Contact/create
  def create
    @contact = Contact.create(@params['contact'])
    redirect :action => :index
  end

  # POST /Contact/{1}/update
  def update
    @contact = Contact.find(@params['id'])
    @contact.update_attributes(@params['contact']) if @contact
    redirect :action => :index
  end

  # POST /Contact/{1}/delete
  def delete
    @contact = Contact.find(@params['id'])
    @contact.destroy if @contact
    redirect :action => :index
  end
end
