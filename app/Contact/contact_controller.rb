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
  
  def check_preferred_and_donotcall(phone_type, preferred, allow_call, company_dnc)
    is_preferred = phone_type == preferred

    # Special case where we need 2 icons side by side, and some jQuery/JavaScript tricks are needed
    # We look for the two-icons attribute in the .erb and substitute a formatted HTML string that will show both
    if is_preferred && (allow_call == 'False' || company_dnc == 'True')
      return 'data-icon="check" two-icons=""'
    end
    
    if phone_type == preferred
      'data-icon="check"'
    elsif (allow_call == 'False' || company_dnc == 'True')
      'data-icon="delete"'
    else
      'data-icon="false"'
    end    
  end
  
  def show_edit_do_not_call_icon(allow_call, company_dnc)
    if allow_call == 'False' || company_dnc == 'True'
      '<img src="/public/images/glyphish-icons/28-star.png" height="18" width="18" />'
    end
  end
  
  def do_not_call_button(allow_call,company_dnc,phone_type,phone_number,contact)
    if allow_call == 'True' && company_dnc == 'False'
      %Q{
          <a href="#{url_for(:controller => :Contact, :action => :do_not_call_press, :id => @contact.object, :query => {:origin => @params['origin'], :phone_type => phone_type, :phone_number => phone_number, :contact => contact})}" data-role="button" data-theme="b">DNC</a>
        }
    end 
  end
  
  def do_not_call_press
    phone_type = @params['phone_type']
    phone_number = @params['phone_number']
    id = @params['id']
    
    message = "This will mark #{phone_number} as do not call."
    Alert.show_popup(
                {
                  :title => "Mark as Do Not Call?",
                  :message => message,
                  :buttons => ["Confirm","Cancel"],
                  :callback => url_for( :action => :do_not_call_press_callback, :query => {:phone_type => phone_type, :id => id, :origin => @params['origin']} )
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
          contact.update_attributes( { :cssi_allowcallsmobilephone => 'False', :cssi_companydncmobilephone => 'True' } )
        when "Home"
          contact.update_attributes( { :cssi_allowcallshomephone => 'False', :cssi_companydnchomephone => 'True' } )
        when "Business"
          contact.update_attributes( { :cssi_allowcallsbusinessphone => 'False', :cssi_companydncbusinessphone => 'True' } )
        when "Alternative"
          contact.update_attributes( { :cssi_allowcallsalternatephone => 'False', :cssi_companydncalternatephone => 'True' } )
      end
      
      SyncEngine.dosync
    end
    
    puts "******************** origin = #{@params['origin']}********************"
    
    WebView.navigate( url_for :controller => :Contact, :action => :show, :back => 'callback:', :id => id, :query =>{:origin => @params['origin']}, :layout => 'layout_jquerymobile' )
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

  # POST /Contact/create
  def create
    @contact = Contact.create(@params['contact'])
    @contact.update_attributes(:birthdate => DateUtil.birthdate_build(@contact.birthdate))
    @opp = Opportunity.create(@params['opportunity'])  
    @opp.update_attributes( :contact_id =>  @contact.object)
    @opp.update_attributes( :statecode => 'Open')
    @opp.update_attributes( :statuscode => 'New Opportunity')
    @opp.update_attributes( :createdon => Time.now.strftime("%Y-%m-%d %H:%M:%S"))
    SyncEngine.dosync
    redirect :action => :show, 
             :back => 'callback:',
             :id => @contact.object,
             :query =>{:origin => @params['origin'], :opportunity => @opp.object}
  end

  # POST /Contact/{1}/update
  def update
    puts "CONTACT UPDATE: #{@params.inspect}"
    @contact = Contact.find(@params['id'])
    @contact.update_attributes(@params['contact']) if @contact
    SyncUtil.start_sync
    redirect :action => :show, :back => 'callback:',
              :id => @contact.object,
              :query =>{:opportunity => @params['opportunity'], :origin => @params['origin']}
  end

  def spouse_update
    puts "SPOUSE UPDATE: #{@params.inspect}"
    @contact = Contact.find(@params['id'])
    @contact.update_attributes(@params['contact']) if @contact
    @contact.update_attributes(:cssi_spousebirthdate => DateUtil.birthdate_build(@contact.cssi_spousebirthdate))
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
  
  def spouse_edit
      @contact = Contact.find(@params['id'])
      render :action => :spouse_edit, :back => 'callback:', :id=>@params['id'], :layout => 'layout_jquerymobile', :origin => @params['origin'] 
  end
  
  def confirm_spouse_delete
    Alert.show_popup ({
        :message => "Click OK to Delete this Spouse", 
        :title => "Confirm Delete", 
        :buttons => ["Cancel", "Ok",],
        :callback => url_for(:action => :spouse_delete, 
                                        :query => {
				                                :id => @params['id'],
				                                :origin => @params['origin']
				                                })
				                   })
  end
 
  def spouse_delete
    if @params['button_id'] == "Ok"
      puts "CONTACT DELETE SPOUSE: #{@params.inspect}"
      @contact = Contact.find(@params['id'])
      @contact.update_attributes(:cssi_spousename => "")
      @contact.update_attributes(:cssi_spouselastname => "")
      @contact.update_attributes(:cssi_spousebirthdate => "")
      @contact.update_attributes(:cssi_spouseheightft => "")
      @contact.update_attributes(:cssi_spouseheightin => "")
      @contact.update_attributes(:cssi_spouseweight => "")
      @contact.update_attributes(:cssi_spouseusetobacco => "")
      @contact.update_attributes(:cssi_spousegender => "")
      SyncEngine.dosync
      WebView.navigate(url_for :controller => :Contact, :action => :show, :id => @contact.object, :query => {:origin => @params['origin']})
    else
      WebView.navigate(url_for :controller => :Contact, :action => :spouse_edit, :id => @params['id'], :query => {:origin => @params['origin']})
    end
  end
  
end
