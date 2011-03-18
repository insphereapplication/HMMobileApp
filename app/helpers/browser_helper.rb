require 'date'
require 'time'
module BrowserHelper

  def udpate_status_no_contact_link(opportunity, status_detail)
    %Q{
      <a onClick="showSpin()" href="#{ url_for(:controller => :Activity, :action => :update_status_no_contact, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  			    :status_detail => status_detail
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			#{status_detail}
			</a>
    }
  end
  
  def udpate_status_won_link(opportunity)
    %Q{
      <a onClick="showSpin()" href="#{ url_for(:controller => :Activity, :action => :update_won_status, 
  				:query => {
  				  :opportunity_id => opportunity.object
  			    }
  			  )
  			}" 
  			data-transition="fade">
  			Won
			</a>
    }
  end
  
  def udpate_status_lost_link(opportunity, text, status_code)
    %Q{
      <a onClick="showSpin()" href="#{ url_for(:controller => :Activity, :action => :udpate_lost_status, 
  				:query => {
  				  :opportunity_id => opportunity.object,
  			    :status_code => status_code
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
        <a onClick="showSpin()" href="#{ url_for(:controller => :Opportunity, :action => :update, :id => opportunity.object, 
  				:query => {
  				  'opportunity[statecode]' => statecode
  			    })
  				}" 
  				rel="external" data-transition="fade">
  				#{statecode}
  			</a>
      }
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
      date = (Date.strptime(input, '%m/%d/%Y'))
      result = date.strftime('%m/%d/%Y')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_date_noyear(input)
    begin
      date = (Date.strptime(input, '%m/%d/%Y'))
      result = date.strftime('%m/%d')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end


  def to_datetime(input)
    begin
      date = (DateTime.strptime(input, '%m/%d/%Y %I:%M:%S %p'))
      result = date.strftime('%m/%d/%Y %I:%M %p')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end
  
  def to_datetime_noyear(input)
    begin
      date = (DateTime.strptime(input, '%m/%d/%Y %I:%M:%S %p'))
      result = date.strftime('%m/%d %I:%M %p')
      result
    rescue
      puts "Could not parse date value: #{input}"
    end
  end
  
  def days_ago_formatted(input)
    begin
      date = (DateTime.strptime(input, '%m/%d/%Y %I:%M:%S %p'))
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

end