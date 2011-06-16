$(document).ready(function() {
	$('.validateContactOpp').click(function() { 
		return validateNewContactInfo();
	});
	
	// $('input#load-more-button').live('click', function(){
	// 	loadMore();
	// })
	
	$('#submit-search-button').click(function(){
		searchTerm = $('input#search_input').val();
		if ($.trim(searchTerm).length > 1) {
			loadPage();
		} 
		else {
			alert('Search must contain at least 2 characters');
		}
	})
	
  $("#contact_filter").change(function() {
		loadPage();
  });
});

function loadMore(){
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	page = parseInt($('input#load-more-button').attr('page'));
	$("div#load-more-div").remove();
	loadContactsAsync(filterType, page, page, searchTerms, false);
}

function loadPage(){
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	$("div#load-more-div").remove();
	$('.contacts-list li').remove();
	loadContactsAsync(filterType, 0, 0, searchTerms, false);
}

function loadContactsAsync(filterType, page, startPage, searchTerms, navToBottom){
	var pageLimit = 10;
	$.post("/app/Contact/get_contacts_page", { filter: filterType, page: page, search_terms: searchTerms },
		function(contacts) {	
			if (contacts.match(/Error/) == "Error"){
					alert("There was a server error.");
					return;
			}
			
			if (contacts && $.trim(contacts) != "" && page < (startPage + pageLimit)){
				$("ul#contact-list").append(contacts);

				// remove any possible redundant letter-divider list items ('A', 'B', etc.)				
				$(".group-divider").each(function(){
				  var ids = $('[id='+this.id+']');
				  if(ids.length>1 && ids[0]==this)
				    $(ids[1]).remove();
				});
				
				loadContactsAsync(filterType, page + 1, startPage, searchTerms, navToBottom);
			} else {
				if (navToBottom){
					document.location.href='#bottom';
				}
				if (page == (startPage + pageLimit) && contacts && $.trim(contacts) != "") {
					$("ul#contact-list").append(getLoadMoreButton("Load More", page));
				}
			}
		}
	);
}

function getLoadMoreButton(text, page){
	return '\
	<div id="load-more-div" data-theme="b" class="ui-btn ui-btn-corner-all ui-shadow ui-btn-up-b">											\
		<span class="ui-btn-inner ui-btn-corner-all">																																			\
			<span class="ui-btn-text">' + text + '</span>																																		\
		</span>																																																						\
		<input id="load-more-button" class="standardButton ui-btn-hidden" page="' + page + '" data-theme="b"/>						\
	</div>'
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