function toggle(showHideDiv) {
	var ele = document.getElementById(showHideDiv);
	if(ele.style.display == "block") {
    		ele.style.display = "none";
  	}
	else {
		ele.style.display = "block";
	}
} 

function showSpin(message){
	$.mobile.savingMessage = message;
	$.mobile.pageSaving();
	setTimeout("hideSpin()",5000);
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

//dynamically populate phone numbers from dropdowns
function populatePhone(dropdown)
{
    for (var i=0; i<dropdown.options.length; i++){
      if (dropdown.options[i].selected==true){
        selected = dropdown.options[i].value;
        break;
      }
    }
	document.getElementById("phoneNumber").value=selected;
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
	document.getElementById("[appointment]location").value=selected;
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

function showSpin(message){
	$.mobile.savingMessage = message;
	$.mobile.pageSaving();
	setTimeout("hideSpin()",5000);
}
function hideSpin(){
	$.mobile.pageSaving(true);
	return true;
}