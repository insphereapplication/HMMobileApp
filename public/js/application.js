$(document).ready(function() {
  $('form').not('#dependent_form, #contact_new, #appdetail, #call_back_form, #appointment_form, #lost_opportunity_other_form, #reset_pin_form, #won_form, #new_task_form', '#new_appointment_form').submit(function() {
    if(typeof jQuery.data(this, "disabledOnSubmit") == 'undefined') {
      jQuery.data(this, "disabledOnSubmit", { submited: true });
      $('input[type=submit], input[type=button]', this).each(function() {
        $(this).attr("disabled", "disabled");
      });
      return true;
    }
    else
    {
      return false;
    }
  });

// Disables a form if the form was valid (prevent duplicate submits)
 $('form').live('submit', function(event) {
     if ($(this).valid()) {
         $('input[type="submit"]').attr('disabled', 'disabled');
		}
 });
});





// Enable the phoneNumber text box so that it submits with the form
function enablePhoneNumber(){
	document.getElementById('phoneNumber').disabled=false; return true;
}

function enableLocation(){
	document.getElementById('location').disabled=false; return true;	
}

function validateLost(){
	if ((document.getElementById('status_code').value.length==0) ||document.getElementById('status_code').value==null) {
      	alert('Please choose a lost reason.');
		return false;
   }
   else { return true; }	
}
//phone number formatting
var zChar = new Array(' ', '(', ')', '-', '.');
var maxphonelength = 14;
var phonevalue1;
var phonevalue2;
var cursorposition;

function ParseForNumber1(object){
  phonevalue1 = ParseChar(object.value, zChar);
}

function ParseForNumber2(object){
  phonevalue2 = ParseChar(object.value, zChar);
}

function backspacerUP(object,e) {
  if(e){
    e = e
  } else {
    e = window.event
  }
  if(e.which){
    var keycode = e.which
  } else {
    var keycode = e.keyCode
  }

  ParseForNumber1(object)

  if(keycode >= 48){
    ValidatePhone(object)
  }
}

function backspacerDOWN(object,e) {
  if(e){
    e = e
  } else {
    e = window.event
  }
  if(e.which){
    var keycode = e.which
  } else {
    var keycode = e.keyCode
  }
  ParseForNumber2(object)
}

function GetCursorPosition(){

  var t1 = phonevalue1;
  var t2 = phonevalue2;
  var bool = false
  for (i=0; i<t1.length; i++)
  {
    if (t1.substring(i,1) != t2.substring(i,1)) {
      if(!bool) {
        cursorposition=i
        window.status=cursorposition
        bool=true
      }
    }
  }
}

function ValidatePhone(object){

  var p = phonevalue1

  p = p.replace(/[^\d]*/gi,"")

  if (p.length < 3) {
    object.value=p
  } else if(p.length==3){
    pp=p;
    d4=p.indexOf('(')
    d5=p.indexOf(')')
    if(d4==-1){
      pp="("+pp;
    }
    if(d5==-1){
      pp=pp+")";
    }
    object.value = pp;
  } else if(p.length>3 && p.length < 7){
    p ="(" + p;
    l30=p.length;
    p30=p.substring(0,4);
    p30=p30+") "

    p31=p.substring(4,l30);
    pp=p30+p31;

    object.value = pp;

  } else if(p.length >= 7){
    p ="(" + p;
    l30=p.length;
    p30=p.substring(0,4);
    p30=p30+") "

    p31=p.substring(4,l30);
    pp=p30+p31;

    l40 = pp.length;
    p40 = pp.substring(0,9);
    p40 = p40 + "-"

    p41 = pp.substring(9,l40);
    ppp = p40 + p41;

    object.value = ppp.substring(0, maxphonelength);
  }

  GetCursorPosition()

  if(cursorposition >= 0){
    if (cursorposition == 0) {
      cursorposition = 2
    } else if (cursorposition <= 2) {
      cursorposition = cursorposition + 1
    } else if (cursorposition <= 4) {
      cursorposition = cursorposition + 3
    } else if (cursorposition == 5) {
      cursorposition = cursorposition + 3
    } else if (cursorposition == 6) {
      cursorposition = cursorposition + 3
    } else if (cursorposition == 7) {
      cursorposition = cursorposition + 4
    } else if (cursorposition == 8) {
      cursorposition = cursorposition + 4
      e1=object.value.indexOf(')')
      e2=object.value.indexOf('-')
      if (e1>-1 && e2>-1){
        if (e2-e1 == 4) {
          cursorposition = cursorposition - 1
        }
      }
    } else if (cursorposition == 9) {
      cursorposition = cursorposition + 4
    } else if (cursorposition < 11) {
      cursorposition = cursorposition + 3
    } else if (cursorposition == 11) {
      cursorposition = cursorposition + 1
    } else if (cursorposition == 12) {
      cursorposition = cursorposition + 1
    } else if (cursorposition >= 13) {
      cursorposition = cursorposition
    }

    var txtRange = object.createTextRange();
    txtRange.moveStart( "character", cursorposition);
    txtRange.moveEnd( "character", cursorposition - object.value.length);
    txtRange.select();
  }

}

function ParseChar(sStr, sChar)
{

  if (sChar.length == null)
  {
    zChar = new Array(sChar);
  }
    else zChar = sChar;

  for (i=0; i<zChar.length; i++)
  {
    sNewStr = "";

    var iStart = 0;
    var iEnd = sStr.indexOf(sChar[i]);

    while (iEnd != -1)
    {
      sNewStr += sStr.substring(iStart, iEnd);
      iStart = iEnd + 1;
      iEnd = sStr.indexOf(sChar[i], iStart);
    }
    sNewStr += sStr.substring(sStr.lastIndexOf(sChar[i]) + 1, sStr.length);

    sStr = sNewStr;
  }

  return sNewStr;
}

function toggleDiv(divid){
  if(document.getElementById(divid).style.display == 'none'){
    document.getElementById(divid).style.display = 'block';
  }else{
    document.getElementById(divid).style.display = 'none';
  }
}

function toggle(showHideDiv) {
	var ele = document.getElementById(showHideDiv);
	if(ele.style.display == "block") {
    		ele.style.display = "none";
  	}
	else {
		ele.style.display = "block";
	}
} 

function hideSpin(){
	$.mobile.pageSaving(true);
	return true;
}

function toggle(showHideDiv) {
	var ele = document.getElementById(showHideDiv);
	if(ele.style.display == "block") {
    		ele.style.display = "none";
  	}
	else {
		ele.style.display = "block";
	}
}

function showACSpin(){
	spinner = document.getElementById('acSyncSpinner');
	spinner.style.display = 'block'
}

function hideACSpin(){
	spinner = document.getElementById('acSyncSpinner');
	spinner.style.display = 'none'
}

//dynamically populate phone numbers from dropdowns
function populatePhone(dropdown)
{
    for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
		text=document.getElementById("phoneList").text;
        break;
      }
    }
	if (selected == 'ad-hoc'){
		document.getElementById("phoneNumber").value=''
		document.getElementById("phoneNumber").disabled = false
	}
	else{
	document.getElementById("phoneNumber").value=selected;
	}
    return true;
}

function populateAddress(dropdown, textbox)
{
    for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
		text = dropdown.options[i].text;
        break;
      }
    }
	textbox.value=selected;
	if (text == "Ad Hoc"){
		textbox.disabled=false;
	}
	else{
		textbox.disabled=true;
	}
    return true;
}

function updateAddress()
{
	var dropdown = document.getElementById('select_location');
	var textbox = document.getElementById('location');
	
    for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
		text = dropdown.options[i].text;
        break;
      }
    }
	textbox.value=selected;
	if (text == "Ad Hoc"){
		textbox.disabled=false;
	}
	else{
		textbox.disabled=true;
	}
    return true;
}

function enableLocation()
{
	var textbox = document.getElementById('location');
	textbox.disabled=false;
    return true;
}

function disablePhone(dropdown, phoneText)
{
	for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
        break;
      }
    }

	if (selected != 'ad-hoc'){
		phoneText.disabled='true';
	}
	return true;
}

function enablePhone()
{
	var dropdown = document.getElementById('phoneList');
	var phoneText = document.getElementById('phoneNumber');
	for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
        break;
      }
    }

	if (selected == 'ad-hoc'){
		phoneText.disabled=false;
	}
	else
	{
		phoneText.disabled=true;
	}
	return true;
}

function populateAddress(dropdown)
{
    for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
        break;
      }
    }
	document.getElementById("location").value=selected;
    return true;
}

function getLocationType()
{
	for (var i=0; i<document.getElementById("select_location").options.length; i++){
      if (document.getElementById("select_location").options[i].selected==true){
        selected = document.getElementById("select_location").options[i].text;
        break;
      }
    }
	document.getElementById('cssi_location').value=selected;
	type = document.getElementById('cssi_location').value;
	return true;
}

//reset type=date inputs to text
$( document ).bind( "mobileinit", function(){
	$.mobile.page.prototype.options.degradeInputs.date = true;
});


function setFieldValue(field, value) {
  document.getElementById(field).value=value;
}

function popupDateTimeAJPicker(flag, title, field_key) {
  $.get('/app/Opportunity/popup', { flag: flag, title: title, field_key: field_key });
  return false;
}

function popupBirthDateAJPicker(flag, title, field_key) {
  $.get('/app/Opportunity/birthpopup', { flag: flag, title: title, field_key: field_key });
  return false;
}

function editpopupDateTimeAJPicker(flag, title, field_key, preset) {
  $.get('/app/Opportunity/edit_popup', { flag: flag, title: title, field_key: field_key, preset: preset });
  return false;
}

function popupAppDateAJPicker(flag, title, field_key, preset) {
  $.get('/app/Opportunity/appdatepopup', { flag: flag, title: title, field_key: field_key, preset: preset });
  return false;
}

function showSpin(message){
	$.mobile.savingMessage = message;
	$.mobile.pageSaving();
	$(':input').attr('disabled', true);
	setTimeout("hideSpin()",5000);
}


function hideSpin(){
	$.mobile.pageSaving(true);
	return true;
}

if (!Array.prototype.reduce)
{
  Array.prototype.reduce = function(fun , initial)
  {
    var len = this.length;
    if (typeof fun != "function")
      throw new TypeError();

    // no value to return if no initial value and an empty array
    if (len == 0 && arguments.length == 1)
      throw new TypeError();

    var i = 0;
    if (arguments.length >= 2)
    {
      var rv = arguments[1];
    }
    else
    {
      do
      {
        if (i in this)
        {
          rv = this[i++];
          break;
        }

        // if array contains no values, no initial value to return
        if (++i >= len)
          throw new TypeError();
      }
      while (true);
    }

    for (; i < len; i++)
    {
      if (i in this)
        rv = fun.call(null, rv, this[i], i, this);
    }

    return rv;
  };
}

function updateConnectionStatusIndicator()
{
	offline_bar_selector = '.ui-offline-bar'
	sync_spinner_selector = '#syncSpinner'
	if( $(offline_bar_selector).length>0 )
	{
		$.post('/app/Settings/get_connection_status', 
			function(ajax_result) {
				result = ajax_result.split(",")
				connection_status = result[0]
				sync_status = result[1]		
				if(connection_status == "Offline")
				{
					$(offline_bar_selector).show();
				}
				else
				{
					$(offline_bar_selector).hide();
				}
				
				if(sync_status == "Syncing")
				{
					$(sync_spinner_selector).show();
				}
				else
				{
					$(sync_spinner_selector).hide();
				}
				
				
			}
		);
	}
}

function stopSyncSpin(){
	spinner = document.getElementById('syncSpinner');
	spinner.style.visibility = 'hidden'
}

function startSyncSpin(){
	spinner = document.getElementById('syncSpinner');
	spinner.style.visibility = 'visible'
}

function pollConnectionStatus(interval_ms)
{
	updateConnectionStatusIndicator();
	setTimeout("pollConnectionStatus("+ interval_ms +")",interval_ms);
}

$(document).ready(function() {
	$.ajaxSetup ({  
		cache: false  
	});
	//update connection status every 5000 ms. declared in application.js.
	pollConnectionStatus(5000);
});

// If a contact number is set as both preferred and DNC, this adjusts the styles to display correctly.
$('#contact_show, #ACcontact_show').live('pagecreate',function(event){
  	var replace = $('li[two-icons] div span');
	if ( replace.length == 1 ) // We can only have 1 preferred number, so only one of these will have the attribute
	{
		replace.replaceWith('<span class="ui-icon ui-icon-donotcall"></span><span class="ui-icon ui-icon-check" style="float:right; right:33px;"></span>');
	}
});

$('#opportunity_show, #contact_show, #phone_dialog').live('pagecreate',function(event){
  	var replace = $('span[two-icons]');
	if ( replace.length == 1 ) // We can only have 1 preferred number, so only one of these will have the attribute
	{
		replace.replaceWith('<span class="ui-icon ui-icon-donotcall"></span><span class="ui-icon ui-icon-check" style="float:right; right:33px;"></span>');
	}
});
