require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'date'
require 'time'
require 'rho/rhotabbar'

class ContactController < Rho::RhoController
  include BrowserHelper

  $first_render = true

  #GET /Contact
  def index
    $tab = 1
    render :action => :index, :back => 'callback:', :layout => 'layout_JQM_Lite'
  end
  
  def show_all_contacts
    puts "CONTACT LOCAL IS CHANGED: #{Contact.local_changed?}"
    if Contact.local_changed? || $first_render
      WebView.navigate(url_for :controller => :Contact, :action => :index)
      Contact.local_changed = false
      $first_render = false
    end
  end
  
  def self.is_first_render?
    rendered = !!@rendered
    @rendered = true
    !rendered
  end
  
  def get_contacts_page
    @contacts = Contact.all_open(@params['page'].to_i)
    puts @contacts.inspect
    @grouped_contacts = @contacts.sort { |a,b| a.last_first.downcase <=> b.last_first.downcase }.group_by{|c| c.last_first.downcase.chars.first}
    render :action => :contact_page, :back => 'callback:'
  end

  # GET /Contact/{1}
  def show
    @contact = Contact.find(@params['id'])
    if @contact
      @next_id = (@contact.object.to_i + 1).to_s
      @prev_id = (@contact.object.to_i - 1).to_s
      render :action => :show, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin']     
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def check_preferred_and_donotcall(phone_type, preferred, allow_call)
    is_preferred = phone_type == preferred

    # Special case where we need 2 icons side by side, and some jQuery/JavaScript tricks are needed
    # We look for the two-icons attribute in the .erb and substitute a formatted HTML string that will show both
    if is_preferred && allow_call == 'False'
      return 'data-icon="check" two-icons=""'
    end
    
    if phone_type == preferred
      'data-icon="check"'
    elsif allow_call == 'False'
      'data-icon="delete"'
    else
      'data-icon="false"'
    end    
  end
  
  def show_edit_do_not_call_icon(allow_call)
    if allow_call == 'False'
      '<img src="/public/images/glyphish-icons/28-star.png" height="18" width="18" />'
    end
  end
  
  def do_not_call_button(allow_call,phone_type,contact)
    if allow_call == 'True'
      %Q{
          <a href="#{url_for(:controller => :Contact, :action => :do_not_call_press, :id => @contact.object, :query => {:phone_type => phone_type, :contact => contact})}" data-role="button" data-theme="b">DNC</a>
        }
    end 
  end
  
  def do_not_call_press
    phone_type = @params['phone_type']
    id = @params['id']
    
    Alert.show_popup(
                {
                  :message => "Mark as Do Not Call?",
                  :buttons => ["Confirm","Cancel"],
                  :callback => url_for( :action => :do_not_call_press_callback, :query => {:phone_type => phone_type, :id => id} )
                })
  end
  
  def do_not_call_press_callback
    button_id   = @params['button_id']
    id          = @params['id']
    phone_type  = @params['phone_type']
    
    contact = Contact.find(id)
    
    if button_id == 'Confirm' and contact
      case phone_type
        when "Mobile"
          contact.update_attributes( { :cssi_allowcallsmobilephone => 'False' } )
        when "Home"
          contact.update_attributes( { :cssi_allowcallshomephone => 'False' } )
        when "Business"
          contact.update_attributes( { :cssi_allowcallsbusinessphone => 'False' } )
        when "Alternative"
          contact.update_attributes( { :cssi_allowcallsalternatephone => 'False' } )
      end
      
      SyncEngine.dosync
    end
    
    WebView.navigate( url_for :controller => :Contact, :action => :show, :back => 'callback:', :id => id, :layout => 'layout_jquerymobile' )
  end
  
  def select_preferred(phone_type, preferred)
    if phone_type == preferred
      return "selected"
    end
  end
  
  def age(dob)
    begin
      birthdate = Date.parse(dob)
       day_diff = Date.today - birthdate.day
       month_diff = Date.today.month - birthdate.month - (day_diff < 0 ? 1 : 0)
       "Age" + (Date.today.year - birthdate.year - (month_diff < 0 ? 1 : 0)).to_s
    rescue
      puts "Invalid date parameter in age calculation method; no age returned"
    end
  end

  # GET /Contact/new
  def new
    @contact = Contact.new
    render :action => :new, :back => 'callback:', :layout => 'layout_jquerymobile'
  end

  # GET /Contact/{1}/edit
  def edit
    @contact = Contact.find(@params['id'])
    if @contact
      render :action => :edit, :back => 'callback:'
    else
      redirect :action => :index, :back => 'callback:'
    end
  end
  
  def dependent_show
    render :action => :dependent_show, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin'] 
  end

  # POST /Contact/create
  def create
    @contact = Contact.create(@params['contact'])
    redirect :action => :index, :back => 'callback:'
  end

  # POST /Contact/{1}/update
  def update
    puts "CONTACT UPDATE: #{@params.inspect}"
    @contact = Contact.find(@params['id'])
    @contact.update_attributes(@params['contact']) if @contact
    SyncEngine.dosync
    redirect :action => :show, :back => 'callback:',
              :id => @contact.object,
              :query =>{:opportunity => @params['opportunity'], :origin => @params['origin']}
  end

  # POST /Contact/{1}/delete
  def delete
    @contact = Contact.find(@params['id'])
    @contact.destroy if @contact
    redirect :action => :index, :back => 'callback:'
  end

  def map
    WebView.refresh
      if System::get_property('platform') == 'APPLE'
        System.open_url("maps:q=#{@params['address']}")
      else
        System.open_url("http://maps.google.com/?q= #{@params['address'].strip.gsub(/ /,'+')}")
      end
  end
  
  def maptest
      System.open_url("maps:q=5918_capella_park_dr+houston+tx")
  end
  
  def spouse_show
      @contact = Contact.find(@params['id'])
      render :action => :spouse_show, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin'] 
  end
  
  def spouse_add
      @contact = Contact.find(@params['id'])
      render :action => :spouse_add, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin'] 
  end
  
end
