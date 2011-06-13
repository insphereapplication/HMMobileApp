$(document).ready(function() {
	
	$('.validateContactOpp').click(function() { 
		return validateNewContactInfo();
	});
	
	$('.validateSearchFilter').click(function() { 
		return validateSearchFilter();
	});
	
	jQuery(document).ready(function() {
	   jQuery("#contact_filter").change(function() {
	      if(jQuery(this).find("option:selected").val() == "All") {
			$('#contacts-all').show();
			$('#contacts-active-pols').hide();
			$('#contacts-pending-pols').hide();
			$('#contacts-open-opps').hide();
			$('#contacts-won-opps').hide();
		    }	
		else if (jQuery(this).find("option:selected").val() == "With Active Policies"){
			$.ajaxSetup ({  
				cache: false  
			});
			loadContactsWithActivePolsAsync("/app/Contact/get_contacts_with_active_page", "ul#contact2-list2", ".group2-divider2", 0);
			$('#contacts-all').hide();
			$('#contacts-active-pols').show();
			$('#contacts-pending-pols').hide();
			$('#contacts-open-opps').hide();
			$('#contacts-won-opps').hide();
		}
		else if (jQuery(this).find("option:selected").val() == "With Pending Policies"){
			$.ajaxSetup ({  
				cache: false  
			});
			loadContactsWithPendingPolsAsync(0);
			$('#contacts-all').hide();
			$('#contacts-active-pols').hide();
			$('#contacts-pending-pols').show();
			$('#contacts-open-opps').hide();
			$('#contacts-won-opps').hide();
		}
		else if (jQuery(this).find("option:selected").val() == "With Open Opps"){
			$.ajaxSetup ({  
				cache: false  
			});
			loadContactsWithOpenOppsAsync(0);
			$('#contacts-all').hide();
			$('#contacts-active-pols').hide();
			$('#contacts-pending-pols').hide();
			$('#contacts-open-opps').show();
			$('#contacts-won-opps').hide();
		}
		else if (jQuery(this).find("option:selected").val() == "With Won Opps"){
			$.ajaxSetup ({  
				cache: false  
			});
			loadContactsWithWonOppsAsync(0);
			$('#contacts-all').hide();
			$('#contacts-active-pols').hide();
			$('#contacts-pending-pols').hide();
			$('#contacts-open-opps').hide();
			$('#contacts-won-opps').show();
		}
	   });
	});
});

function loadContactsAsync(action_url, contact_div, group_class, page){
	$.post(action_url, { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$(contact_div).append(contacts);
				
				$(group_class).each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsAsync(action_url, contact_div, group_class, page + 1);
			} 
		}
	);
}

function loadContactsWithActivePolsAsync(page){
	$.post('/app/Contact/get_contacts_with_active_page', { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$('ul#contact2-list2').append(contacts);
				
				$('.group2-divider2').each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsWithActivePolsAsync(page + 1);
			} 
		}
	);
}

function loadContactsWithPendingPolsAsync(page){
	$.post('/app/Contact/get_contacts_with_pending_page', { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$('ul#contact3-list3').append(contacts);
				
				$('.group-divider3').each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsWithPendingPolsAsync(page + 1);
			} 
		}
	);
}

function loadContactsWithOpenOppsAsync(page){
	$.post('/app/Contact/get_contacts_with_open_opps_page', { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$('ul#contact4-list4').append(contacts);
				
				$('.group-divider4').each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsWithOpenOppsAsync(page + 1);
			} 
		}
	);
}

function loadContactsWithWonOppsAsync(page){
	$.post('/app/Contact/get_contacts_with_won_opps_page', { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$('ul#contact5-list5').append(contacts);
				
				$('.group-divider5').each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsWithWonOppsAsync(page + 1);
			} 
		}
	);
}

function loadContactsFilterAsync(page){
	$.post('/app/Contact/get_contacts_filter_page', { page: page },
		function(contacts) {				
			if (contacts && $.trim(contacts) != ""){
				$('ul#contact6-list6').append(contacts);
				
				$('.group-divider6').each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsFilterAsync(page + 1);
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

function validateSearchFilter(){
	
	if ( document.getElementById('search_input').value.length < 2 || document.getElementById('search').value==null ) {
      	alert('Search must contain at least 2 characters');
		return false;
    }
    
	return true;
}