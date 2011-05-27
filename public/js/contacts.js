$(document).ready(function() {
	
	$('.validateContactOpp').click(function() { 
			validateNewContactInfo();
	});
});
	
function loadContactsAsync(page){
	$.post('Contact/get_contacts_page', { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$('ul#contact-list').append(contacts);
				
				$('.group-divider').each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsAsync(page + 1);
			} 
		}
	);
}

function validateNewContactInfo(){
	
	if ( document.getElementById('contact_firstname').value.length==0 || document.getElementById('contact_firstname').value==null ) {
      	alert('Please enter a first name');
		return false;
    }
	if ( document.getElementById('contact_lastname').value.length==0 || document.getElementById('contact_lastname').value==null ) {
      	alert('Please enter a last name');
		return false;
    }
	if (		
		( document.getElementById('contact_emailaddress1').value.length==0 || document.getElementById('contact_emailaddress1').value==null )
		&&
		(document.getElementById('contact_mobilephone').value.length==0 || document.getElementById('contact_mobilephone').value==null )
		&&
		(document.getElementById('contact_telephone1').value.length==0 || document.getElementById('contact_telephone1').value==null )
		&&
		(document.getElementById('contact_telephone2').value.length==0 || document.getElementById('contact_telephone2').value==null )
		&&
		(document.getElementById('contact_telephone3').value.length==0 || document.getElementById('contact_telephone3').value==null )
	){
		// no phone numbers and no email address
		alert('Please enter an email address or phone number');
		return false;
	}
    
	return true;
}