require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'
require 'time'

class ContactController < Rho::RhoController
  include BrowserHelper

  #GET /Contact
  def index
    puts "INDEX!!"
    @contacts = Contact.find(:all)
    @grouped_contacts = @contacts.sort { |a,b| a.last_first.downcase <=> b.last_first.downcase }.group_by{|c| c.last_first.chars.first}
    render :action => :index,
            :layout => 'layout_JQM_Lite'
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
  
  def check_preferred(phone_type, preferred)
    if phone_type == preferred
      "check"
    else
      "false"
    end
  end
  
  def seed_db_150
    #Norton, Kyle - Pariveda Solutions - 22 Feb 2011
    #Purpose: Used to seed database with a test set of contacts
    Contact.seed_db(150)
    WebView.navigate('/app/Settings?msg=Seeded%20Database%20with%20150%20contacts')
  end
  
  def age(dob)
    birthdate = Date.parse(dob)
     day_diff = Date.today - birthdate.day
     month_diff = Date.today.month - birthdate.month - (day_diff < 0 ? 1 : 0)
     Date.today.year - birthdate.year - (month_diff < 0 ? 1 : 0)
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
    redirect :action => :show,
              :id => @contact.object
  end

  # POST /Contact/{1}/delete
  def delete
    @contact = Contact.find(@params['id'])
    @contact.destroy if @contact
    redirect :action => :index
  end
end
