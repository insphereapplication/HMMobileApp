$(document).ready(function() {
	
	$('.validateSearchFilter').click(function() { 
		return validateSearchFilter();
	});
});
	
function loadContactsAsync(page){
	$.post('/app/Contact/get_contacts_page', { page: page },
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

function validateSearchFilter(){
	
	if ( document.getElementById('search_input').value.length < 2 || document.getElementById('search').value==null ) {
      	alert('Search must contain at least 2 characters');
		return false;
    }
    
	return true;
}