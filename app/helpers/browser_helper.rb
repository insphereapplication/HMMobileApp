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
      <a class="UpdateStatusWon" href="#{ url_for(:controller => :Activity, :action => :confirm_win_status, 
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
    if !System.has_network
      #show connection state
      %Q{
        	<div data-nobackbtn="true" class="ui-offline-bar" role="banner"> Connection State: Offline </div>
      }
    end
  end
  
  def udpate_status_lost_link(opportunity, text, status_code)
    #launch dialog to confirm lost
    %Q{
      <a class="UpdateStatusLost" href="#{ url_for(:controller => :Activity, :action => :confirm_lost_status, 
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
  	options = {:currency_symbol => "$", :delimiter => ",", :decimal_symbol => ".", :currency_before => true, :no_decimal => false}.merge(options)

  	# split integer and fractional parts 
  	int, frac = ("%.2f" % number).split('.')
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
      date = (Date.strptime(input, DateUtil::DEFAULT_BIRTHDATE_FORMAT))
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