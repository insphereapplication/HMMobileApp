var offline_bar_selector = ".ui-offline-bar",
    sync_spinner_selector = "#syncSpinner";

function updateConnectionStatusIndicator() {
    var $offline_bar_selector = $(offline_bar_selector);
    if ($offline_bar_selector.length > 0)
        $.post('/app/Settings/get_connection_status', function(ajax_result) {
            var result = ajax_result.split(",");
            var connection_status = result[0];
            var sync_status = result[1];
            if (connection_status === "Offline")
                $offline_bar_selector.show();
            else
                $offline_bar_selector.hide();
            var $sync_spinner_selector = $(sync_spinner_selector);
            if ($sync_spinner_selector.length > 0)
                if (sync_status === "Syncing")
                    $sync_spinner_selector.show();
                else
                    $sync_spinner_selector.hide();
        });
}

var timeoutID = null;

function pollConnectionStatus() {
    updateConnectionStatusIndicator();
    // update connection status every 30000 ms
    timeoutID = setTimeout("pollConnectionStatus()", 30000);
}

function setAppActive() {
    if (timeoutID === null)
        pollConnectionStatus();
}

function setAppDeactive() {
    if (timeoutID !== null) {
        clearTimeout(timeoutID);
        timeoutID = null;
    }
}

$(document).bind("pageinit", function() {
    if (timeoutID === null)
        pollConnectionStatus();
});

//dynamically populate phone numbers from dropdowns
function populatePhone(dropdown)
{
	if (dropdown == null){
		return true;
	}
    for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
		text=document.getElementById("phoneList").text;
		selected_type=dropdown.options[i].text
        break;
      }
    }
	document.getElementById("phoneNumber").value=selected;
	document.getElementById("phone_type_selected").value=selected_type;
	if (selected_type == 'Ad Hoc'){
		document.getElementById("phoneNumber").disabled = false;
	}
	else
	{
		document.getElementById("phoneNumber").disabled = true;
	}
    return true;
}


function updateAddress()
{
	var dropdown = document.getElementById('select_location');
	var textbox = document.getElementById('location');
	
	if (dropdown == null ){	
		 return true;
	}
	
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

function popupTomorrowDateTimeAJPicker(flag, title, field_key) {
  val = $("#"+field_key).val();
  $.get('/app/Opportunity/tomorrowPopup', { flag: flag, title: title, field_key: field_key, preset: val });
  return false;
}

function popupBirthDateAJPicker(flag, title, field_key) {
  val = $(document.getElementById(field_key)).val();
  $.get('/app/Opportunity/birthPopup', { flag: flag, title: title, field_key: field_key, preset: val });
  return false;
}

function setFieldValue(field, value) {
  document.getElementById(field).value=value;
  $("#"+field).refresh();
}

// Enable the phoneNumber text box so that it submits with the form
function enablePhoneNumber(){
	document.getElementById('phoneNumber').disabled=false; 
	document.getElementById('phone_type_selected').disabled=false; 
	return true;
}

//Enable appointment location text box so that it submits with the form
function enableLocation(){
	document.getElementById('location').disabled=false; return true;	
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
