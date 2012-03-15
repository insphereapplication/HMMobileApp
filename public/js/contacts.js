$(document).ready(function() {
	$('input#load-more-button').live('click', function(){
		loadMore();
	});
	
	$('#submit-ac-search').click(function(){
		initializeSearchAC();
	});
	
	initializeFilterButtonHandlers();
});

// this creates two one-time handlers for the 'clear' and 'filter' buttons. They must be removed during a page load, and will be re-added when the load is done.
function initializeFilterButtonHandlers(){
	$('#submit-search-button').click(function(){
		initializeSearch();
	});
	
	$('#contact_filter_clear').click( function()
	{
  	clearContacts();
	});
}

function disableSearchButtons(){
	$('#submit-search-button').unbind('click');
	$('#contact_filter_clear').unbind('click');
}

function disableACSearchButtons(){
	$('#submit-ac-search').unbind('click');
}

function initializeSearch(){
    toggleCollapsible('contact_filter');
    refreshFilterSummary();
    loadPage();	
}

function clearContacts(){
	$('ul#contact-list').empty();
	$('#contact_filter').val('all');
	$('#search_input').val('');
	refreshFilterSummary();
	loadPage();
	return false;
}

function initializeSearchAC(){
	firstName = $('input#search_first_name').val();
	lastName = $('input#search_last_name').val();
	fullName = $('input#search_fullname').val();
	emailAddress = $('input#search_email').val();
	phoneNumber = $('input#search_phone').val();


	disableACSearchButtons();
	showACSpin();
	// The callback function is empty except for error handling -- Rhosync's search method is asynchronous and will trigger a separate redirect 
	$.get("/app/SearchContacts/search_contacts", {first_name: firstName, last_name: lastName, full_name: fullName, email: emailAddress, phone: phoneNumber},
		function(result) {	
			if (result.match(/Error/) == "Error"){
					alert("There was a server error.");
					return;
			}
	});
}

function loadMore(){
	disableSearchButtons();
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	page = parseInt($('input#load-more-button').attr('page'));
	$("div#load-more-div").remove();
	loadContactsAsync(filterType, page, page, searchTerms);
}

function loadPage(){
	disableSearchButtons();
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	$("ul#contact-list").empty();
	loadContactsAsync(filterType, 0, 0, searchTerms);
}

function loadContactsAsync(filterType, page, startPage, searchTerms){	
	$.get("/app/Contact/get_contacts_page", { filter: filterType, page: page, search_terms: searchTerms },
		function(contacts) {	
			if (contacts.match(/^Error/) == "Error"){
					alert("There was a server error.\n" + contacts);
					return;
			}
			
			if (contacts && $.trim(contacts) != "" && page < (startPage + pageLimit)){
				$("ul#contact-list").append(contacts);
                                // remove any possible redundant letter-divider list items ('A', 'B', etc.)
                                $(".group-divider").each(function() {
                                    var ids = $('[id=' + this.id + ']');
                                    if (ids.length > 1 && ids[0] == this)
                                        $(ids[1]).remove();
                                });
				loadContactsAsync(filterType, page + 1, startPage, searchTerms);
			} 
			else {
				if (page == (startPage + pageLimit) && contacts && $.trim(contacts) != "") {
					$("ul#contact-list").append(getLoadMoreButton("Load More", page));
				}
				// re-initialize one-time filter and clear button handlers -- they were removed during the page load
				initializeFilterButtonHandlers();
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

function refreshFilterSummary(){
	select_list_field = document.getElementById('contact_filter');
	select_list_selected_index = select_list_field.selectedIndex;
	filter = select_list_field.options[select_list_selected_index].text;
	input = $('input#search_input').val();
	showFilterParams(filter, input);
}

function showFilterParams(filter, input){
    $('#contact_filter_details').html('Filter: ' + filter + ', "' + input + '"');
}

function toggleCollapsible(id) {
    $('#' + id + '_icon').toggleClass('ui-icon-plus ui-icon-minus');
    $('#' + id + '_content').toggleClass('ui-collapsible-content-collapsed');
    $('#' + id + '_details').toggle();
}
