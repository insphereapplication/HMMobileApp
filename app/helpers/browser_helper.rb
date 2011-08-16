require 'date'
require 'time'
module BrowserHelper

  def udpate_status_no_contact_link(opportunity, status_detail)
    %Q{
      <a class="UpdateStatus" onClick="showSpin('Status Updated')" href="#{ url_for(:controller => :Activity, :action => :update_status_no_contact, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  			    :status_detail => status_detail,
  			    :origin => @params['origin']
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			#{status_detail}
			</a>
    }
  end
  
  def udpate_status_won_link(opportunity)
    #launch dialog to confirm won
    %Q{
      <a class="UpdateStatus" href="#{ url_for(:controller => :Activity, :action => :confirm_win_status, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  				  :origin => @params['origin']
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			Won
			</a>
    }
  end
  
  def offline_bar
    %Q{
      	<div data-nobackbtn="true" class="ui-offline-bar#{ DeviceCapabilities.is_connected? ? ' ui-hidden' : '' }" role="banner"> Connection State: Offline </div>
    }
  end
  
  def sync_spinner
      %Q{
        	<img class="#{ DeviceCapabilities.is_syncing? ? 'ui-hidden' : '' }" id="syncSpinner" src="/public/images/syncSpinner.gif" height="12" width="12" />
      }
  end
  
  def udpate_status_lost_link(opportunity, text, status_code)
    #launch dialog to confirm lost
    %Q{
      <a class="UpdateStatus" href="#{ url_for(:controller => :Activity, :action => :confirm_lost_status, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  			    :status_code => status_code,
  			    :origin => @params['origin']
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			#{text}
			</a>
    }
  end
  
  def update_opportunity_statecode_link(opportunity, statecode)
     %Q{
        <a href="#{ url_for(:controller => :Opportunity, :action => :update, :id => opportunity.object, 
  				:query => {
  				  'opportunity[statecode]' => statecode
  			    })
  				}" 
  				rel="external" data-transition="fade">
  				#{statecode}
  			</a>
      }
  end

  def cancelbutton_by_origin(origin)
    case origin
      when "new-leads"
        # we've removed the icon as it overlaps with the header text; to put it back, add 'data-icon="back"' to the tag
        '<a href="/app/Opportunity?selected_tab=new-leads" data-direction="reverse" rel="external">Cancel</a>'
      when "follow-ups"
        '<a href="/app/Opportunity?selected_tab=follow-ups" data-direction="reverse" rel="external">Cancel</a>'
      when "appointments"
        '<a href="/app/Opportunity?selected_tab=appointments" data-direction="reverse" rel="external">Cancel</a>'
      when "contact"
         '<a href="/app/Contact" data-direction="reverse" rel="external">Cancel</a>'
      else
        '<a href="/app/Opportunity" data-direction="reverse" rel="external">Cancel</a>'
    end
  end
  
  def gen_options(options, selected_value)
    options.map{|option|
      selected_text = (option[:value] == selected_value) ? 'selected="true"' : ''
      "<option class=\"ui-btn-text\" #{selected_text} value=\"#{option[:value]}\">#{option[:label]}</option>"
    }.join("\n")
  end
  
  def scheduled_filter_options
    options = [
      {:value => 'All', :label => 'All'},
      {:value => 'ScheduledAppointments', :label => 'Appointments'},
      {:value => 'ScheduledCallbacks', :label => 'Callbacks'}
    ]
    
    persisted_selection = Settings.filter_values['scheduled_filter']
    persisted_selection = 'All' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def followup_status_reason_filter_options  	
  	options = [
      {:value => 'All', :label => 'All'},
      {:value => 'NoContactMade', :label => 'No Contact Made'},
      {:value => 'ContactMade', :label => 'Contact Made'},
      {:value => 'AppointmentSet', :label => 'Appointment Set'},
      {:value => 'DealInProgress', :label => 'Deal in Progress'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}statusReason"]
    persisted_selection = 'All' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def followup_sort_by_filter_options
		options = [
      {:value => 'LastActivityDateAscending', :label => 'Latest Activity Date'},
      {:value => 'LastActivityDateDescending', :label => 'Earliest Activity Date'},
      {:value => 'CreateDateAscending', :label => 'Created Ascending'},
      {:value => 'CreateDateDescending', :label => 'Created Descending'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}sortBy"]
    persisted_selection = 'LastActivityDateAscending' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def followup_created_filter_options
    options = [
      {:value => 'All', :label => 'All'},
      {:value => '1', :label => '1 Day Ago'},
      {:value => '2', :label => '2 Days Ago'},
      {:value => '3', :label => '3 Days Ago'},
      {:value => '4', :label => '4 Days Ago'},
      {:value => '5', :label => '5 Days Ago'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_FOLLOWUP_FILTER_PREFIX}created"]
    persisted_selection = 'All' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end
  
  def contact_filter_options
    options = [
      {:value => 'all', :label => 'All'},
      {:value => 'active-policies', :label => 'Active Policies'},
      {:value => 'pending-policies', :label => 'Pending Policies'},
      {:value => 'open-opps', :label => 'Open Opportunities'},
      {:value => 'won-opps', :label => 'Won Opportunities'}
    ]
    
    persisted_selection = Settings.filter_values["#{Constants::PERSISTED_CONTACT_FILTER_PREFIX}filter"]
    persisted_selection = 'all' if persisted_selection.blank?
    
    gen_options(options, persisted_selection)
  end

  
  def opp_detail_backbutton(origin)
      case origin
        when "new-leads"
          '<a href="/app/Opportunity?selected_tab=new-leads" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
        when "follow-ups"
          '<a href="/app/Opportunity?selected_tab=follow-ups" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
        when "appointments"
          '<a href="/app/Opportunity?selected_tab=appointments" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
        when "contact"
           '<a href="/app/Contact" data-direction="reverse" rel="external" data-icon="back">Contacts</a>'
        else
          '<a href="/app/Opportunity" data-direction="reverse" rel="external" data-icon="back">Opps</a>'
      end
  end

  def placeholder(label=nil)
    "placeholder='#{label}'" if platform == 'apple'
  end

  def platform
    System::get_property('platform').downcase
  end

  def selected(option_value,object_value)
    "selected=\"yes\"" if option_value == object_value
  end

  def checked(option_value,object_value)
    "checked=\"yes\"" if option_value == object_value
  end
  
  def format_currency(number, options={})
  	# :currency_before => false puts the currency symbol after the number
  	# default format: $12,345,678.90
  	
  	number = number.blank? ? 0 : number # default to 0 if given number is blank
  	
  	options = {:currency_symbol => "$", :delimiter => ",", :decimal_symbol => ".", :currency_before => true, :no_decimal => false}.merge(options)
    
  	# split integer and fractional parts 
  	int, frac = ("%.2f" % number.to_f).split('.')
  	# insert the delimiters
  	int.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")

  	if options[:no_decimal]
  		frac_part = ""
  	else
  		frac_part = options[:decimal_symbol] + frac
  	end

  	if options[:currency_before]
  		options[:currency_symbol] + int + frac_part
  	else
  		int + frac_part + options[:currency_symbol]
  	end
  end
  
  def to_date(input)
    begin
      date = (Date.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%m/%d/%Y')
      result
    rescue
      puts "DATE !~!~!~!~!~ DATE ISSUE !~!~!!~!~!~!~!~!~!!~!"
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_birthdate(input)
    begin
      date = (Date.strptime(input, DateUtil::BIRTHDATE_PICKER_TIME_FORMAT))
      result = date.strftime('%m/%d/%Y')
      result
    rescue
      puts "DATE !~!~!~!~!~ DATE ISSUE !~!~!!~!~!~!~!~!~!!~!"
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_date_noyear(input)
    begin
      date = (Date.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%m/%d')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end

  def to_datetime(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%m/%d/%Y %I:%M %p')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_endtime(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = date.strftime('%I:%M %p')
      result
    rescue
      puts "Could not parse  value: #{input}"
    end
  end
  
  def to_datetime_noyear(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      date.strftime(DateUtil::NO_YEAR_FORMAT).sub(/\A0+/, '')
    rescue
      puts "Could not parse date value: #{input}"
    end
  end
  
  def days_ago_formatted(input)
    begin
      date = (DateTime.strptime(input, DateUtil::DEFAULT_TIME_FORMAT))
      result = (Date.today - date).to_i
      if result == 0 
        return "Today"
      else
        result + "d"
      end
    rescue
      puts "Could not parse date value: #{input}, Today is: #{Date.today.to_s}"
    end
  end
  
  def format_for_mapping(location)
  end
  
  # converts True/False to Yes/No, used on contact/spouse/dependent for displaying tobacco use
  def use_tobacco_string(value)
    if value == 'True'
      'Yes'
    else
      'No'
    end
  end

end