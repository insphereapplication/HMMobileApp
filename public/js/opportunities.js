$(document).ready(function() {
	
   	$('#new-leads-button').live('click', function() {
		checkForChanges('new-leads');
		setNavContext('new-leads');
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#new-leads-button').addClass('ui-btn-active');
		$('#new-leads').show();
	});
	
	$('#follow-ups-button').live('click', function() {
		checkForChanges('follow-ups');
		setNavContext('follow-ups')
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#follow-ups-button').addClass('ui-btn-active');
		$('#follow-ups').show();
	});
	
	$('#appointments-button').live('click', function() {
		checkForChanges('appointments');
		setNavContext('appointments')
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#appointments-button').addClass('ui-btn-active');
		$('#appointments').show();
	});
	
	$.ajaxSetup ({  
	    cache: false  
	});
	
 });

function checkForChanges(tab){
	$.post('/app/Opportunity/refresh_if_changed', { tab: tab });
}

function setNavContext(context){
	$.post('/app/Opportunity/set_opportunities_nav_context', { context: context })
}

function loadNewLeads(){
	newLeadBuckets = getLinkedBucketList([ 
		{ opportunity_method: 'todays_new_leads', 			 list_selector: 'span#todays-leads-list', 				next: null},
		{ opportunity_method: 'previous_days_new_leads', list_selector: 'span#previous-days-leads-list',  next: null}
	]);
								
	loadOpportunities(newLeadBuckets, 0);
}

function loadFollowUps( statusReasonFilter, sortByFilter, createdFilter )
{
	$('#by-last-activities-list').empty();
	
	followUpBucket = getLinkedBucketList([ 
		{ opportunity_method: 'by_last_activities',  list_selector: 'span#by-last-activities-list',  next: null}
	]);
	
	var jsonParams = { statusReason: statusReasonFilter,
					   sortBy: sortByFilter,
					   created: createdFilter };
	
	loadOpportunities( followUpBucket, 0, jsonParams, true);
}

function loadScheduled( scheduledSelectFilter, scheduledSearchInput )
{
	$('#past-due-appointments-list').empty();
	$('#todays-appointments-list').empty();
	$('#future-appointments-list').empty();
	
	appointmentBucket = getLinkedBucketList([ 
		{ opportunity_method: 'past_due_scheduled', list_selector: 'span#past-due-appointments-list', next: null},
		{ opportunity_method: 'todays_scheduled',   list_selector: 'span#todays-appointments-list',   next: null},
		{ opportunity_method: 'future_scheduled',   list_selector: 'span#future-appointments-list',   next: null}
	]);
	
	var jsonParams = { filter: scheduledSelectFilter,
					   search: scheduledSearchInput };	
											
	loadOpportunities(appointmentBucket, 0, jsonParams, true);
}

function loadOpportunities(opportunityBucket, opportunity_page, jsonParams, initTabLoad)
{
	if ( jsonParams == undefined )
	{
		jsonParams = { page: opportunity_page };
	}
	else
	{
		jsonParams.page = opportunity_page;
	}
	
	if (initTabLoad == undefined)
	{
		jsonParams.init_tab_load = false;
	}
	else
	{
		jsonParams.init_tab_load = initTabLoad;
	}
	
	var jsonString = "{";
	for ( var index in jsonParams )
	{
		jsonString += index + " : " + jsonParams[index] + ",";
	}
	
	jsonString = jsonString.replace( /,$/, "" );
	jsonString += "}";
	
	$.post('/app/Opportunity/' + opportunityBucket.opportunity_method, jsonParams, // {page: opp_page, filter: filter, search: search}
		function(opportunities) {				
			if (opportunities && $.trim(opportunities) != "")
			{
				$(opportunityBucket.list_selector).append(opportunities);
				loadOpportunities(opportunityBucket, opportunity_page + 1, jsonParams);
			}
			else if (opportunityBucket.next != null)
			{
				checkForNoOpportunities( opportunityBucket.opportunity_method );
				loadOpportunities(opportunityBucket.next, 0, jsonParams);
			}
			else
			{
				checkForNoOpportunities( opportunityBucket.opportunity_method );
			}
		}
	);
}

function checkForNoOpportunities( opportunityMethod )
{
	if ( 'past_due_scheduled' == opportunityMethod && 1 == $('#past-due-appointments-list li').length )
	{
		$('#past-due-appointments-list').append( '<span id="no-past-due-found" style="display:block; margin-left:auto; margin-right:auto; text-align: center;">No past due opportunities found with current filter</span>' );
	}
	
	if ( 'todays_scheduled' == opportunityMethod && 1 == $('#todays-appointments-list li').length )
	{
		$('#todays-appointments-list').append( '<span id="no-today-found" style="display:block; margin-left:auto; margin-right:auto; text-align: center;">No opportunities due today found with current filter</span>' );
	}

	if ( 'future_scheduled' == opportunityMethod && 1 == $('#future-appointments-list li').length )
	{
		$('#future-appointments-list').append( '<span id="no-future-found" style="display:block; margin-left:auto; margin-right:auto; text-align: center;">No future opportunities found with current filter</span>' );
	}
}

// link the buckets. 
function getLinkedBucketList(bucketArray){
	for(var i=0; i<bucketArray.length; i++){
		bucketArray[i].next = bucketArray[i+1]; 
	}
	return bucketArray[0];
}





