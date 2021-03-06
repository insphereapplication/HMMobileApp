$(document).ready(function() {
	$('#load-more-button').live('click', function(){
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
	$('#contact-do-nothing-button').hide();
}

function disableSearchButtons(){
	$('#submit-search-button').unbind('click');
	$('#contact_filter_clear').unbind('click');
	$('#contact-do-nothing-button').hide();
}

function disableACSearchButtons(){
	$('#submit-ac-search').unbind('click');
	$('#contact-do-nothing-button').hide();
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
	$("div#load-more-button").text("Loading ...");
	$("div#load-more-button").show(1000);
	disableSearchButtons();
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	page = 	parseInt($('input#current_page').val());
	loadContactsAsync(filterType, page, page, searchTerms);
}

function loadPage(){
	disableSearchButtons();
	filterType = $('#contact_filter').val();
	searchTerms = $('input#search_input').val();
	$("ul#contact-list").empty();
	$('input#last_row_count').val(0);
	loadContactsAsync(filterType, 0, 0, searchTerms);
}


function loadContactsAsync(filterType, page, startPage, searchTerms){	
	$.get("/app/Contact/get_contacts_page", { filter: filterType, page: page, search_terms: searchTerms },
		function(contacts) {	
			if (contacts.match(/^Error/) == "Error"){
					alert("There was a server error.\n" + contacts);
					return;
			}
	    	//alert ("In contact async page");
			$("div#load-more-button").remove();
			if (contacts && $.trim(contacts) != "" && page < (startPage + pageLimit)){
				$("ul#contact-list").append(contacts);
                                // remove any possible redundant letter-divider list items ('A', 'B', etc.)
                                $(".group-divider").each(function() {
                                    var ids = $('[id=' + this.id + ']');
                                    if (ids.length > 1 && ids[0] == this)
                                        $(ids[1]).remove();
                                });
			    if (page + 1 < (startPage + pageLimit))
				{
				//This should not be used unless we start making multiple db call per load again
				loadContactsAsync(filterType, page + 1, startPage, searchTerms);
				}
				else 
				{
				 	
					$('input#current_page').val(page + 1);
				
				
					previous_row_count = parseInt($('input#last_row_count').val());
					new_row_count = $("li").length;
					
					if (previous_row_count + 100 < new_row_count)
					{
					 $("ul#contact-list").append(getLoadMoreButton("Load More"));
					}
					$('input#last_row_count').val(new_row_count);
				}

			
			} 

			
			if ( $.trim(contacts) == "" ) // No contacts found with the current filter settings
			{
				checkForNoContacts();
			}
			// re-initialize one-time filter and clear button handlers -- they were removed during the page load
			initializeFilterButtonHandlers();

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

function getLoadMoreButton(text){
	return '\
	<div id="load-more-button" data-theme="b" class="ui-btn ui-btn-corner-all ui-shadow ui-btn-up-b">											\
		<span class="ui-btn-inner ui-btn-corner-all">																																			\
			<span class="ui-btn-text">' + text + '</span>																																		\
		</span>																																																						\
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
