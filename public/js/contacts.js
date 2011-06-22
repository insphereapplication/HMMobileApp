$(document).ready(function() {
	$('input#load-more-button').live('click', function(){
		loadMore();
	})
	
	$('#submit-search-button').click(function(){
		toggleDiv('filter'); 
		toggleDiv('plus'); 
		toggleDiv('minus');
		select_list_field = document.getElementById('contact_filter');
		select_list_selected_index = select_list_field.selectedIndex;
		filter = select_list_field.options[select_list_selected_index].text;
		input = $('input#search_input').val();
		showFilterParams(filter, input);
		loadPage();
	})
	
	$('#submit-ac-search').click(function(){
		initializeSearchAC();
	})
	
	$('#contact_filter_clear').click( function()
	{
		$('ul#contact-list').empty();
		$('#contact_filter').val('all');
		$('#search_input').val('');
		$('#filter-params').remove();
		loadPage();
		return false;
	})
});

function initializeSearchAC(){
	firstName = $('input#search_first_name').val();
	lastName = $('input#search_last_name').val();
	// The callback function is empty except for error handling -- Rhosync's search method is asynchronous and will trigger a separate redirect 
	$.post("/app/SearchContacts/search_contacts", {first_name: firstName, last_name: lastName},
		function(result) {	
			if (result.match(/Error/) == "Error"){
					alert("There was a server error.");
					return;
			}
	});
}

function loadMore(){
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	page = parseInt($('input#load-more-button').attr('page'));
	$("div#load-more-div").remove();
	loadContactsAsync(filterType, page, page, searchTerms);
}

function loadPage(){
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	$("div#load-more-div").remove();
	$('.contacts-list li').remove();
	loadContactsAsync(filterType, 0, 0, searchTerms);
}

function loadContactsAsync(filterType, page, startPage, searchTerms){
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
				
				loadContactsAsync(filterType, page + 1, startPage, searchTerms);
			} 
			else if (page == (startPage + pageLimit) && contacts && $.trim(contacts) != "") {
					$("ul#contact-list").append(getLoadMoreButton("Load More", page));
			}
			
			if ( $.trim(contacts) == "" ) // No contacts found with the current filter settings
			{
				checkForNoContacts();
			}
		}
	);
}

function checkForNoContacts()
{
	if ( 0 == $("ul#contact-list li").length )
	{
		$("ul#contact-list").empty();
		$("ul#contact-list").append('<span id="no-contacts-found" style="display:block; margin-left:auto; margin-right:auto; text-align: center;">No contacts found with current filter</span>');
	}
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

function showFilterParams(filter, input){
	filterparams = '<span id="filter-params" style="margin-top:5px;font-size:12px;">Filter: ' + filter + ', "' + input + '"</span>'
	$('#filter-params').remove();
	$('#filter-details').append( filterparams );

}
