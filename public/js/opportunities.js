$(document).ready(function() {
	
   	$('#new-leads-button').click(function() {
		checkForChanges('new-leads');
		setNavContext('new-leads');
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#new-leads-button').addClass('ui-btn-active');
		$('#new-leads').show();
	});
	
	$('#follow-ups-button').click(function() {
		checkForChanges('follow-ups');
		setNavContext('follow-ups')
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#follow-ups-button').addClass('ui-btn-active');
		$('#follow-ups').show();
	});
	
	$('#appointments-button').click(function() {
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

function loadFollowUps(){
	followUpBucket = getLinkedBucketList([ 
		{ opportunity_method: 'past_due_follow_ups', list_selector: 'span#past-due-follow-ups-list', next: null},
		{ opportunity_method: 'todays_follow_ups',   list_selector: 'span#todays-follow-ups-list',   next: null},
		{ opportunity_method: 'by_last_activities',  list_selector: 'span#by-last-activities-list',  next: null},
		{ opportunity_method: 'future_follow_ups',   list_selector: 'span#future-follow-ups-list',   next: null} 
	]);
	
	loadOpportunities(followUpBucket, 0);
}

function loadScheduled(){
	appointmentBucket = getLinkedBucketList([ 
		{ opportunity_method: 'past_due_scheduled',    list_selector: 'span#past-due-appointments-list', next: null},
		{ opportunity_method: 'todays_scheduled',   list_selector: 'span#todays-appointments-list',   next: null},
		{ opportunity_method: 'future_scheduled',   list_selector: 'span#future-appointments-list',   next: null}
	]);
											
	loadOpportunities(appointmentBucket, 0);
}

 				 

function loadOpportunities(opportunityBucket, opportunity_page){
	$.post('/app/Opportunity/' + opportunityBucket.opportunity_method, { page: opportunity_page },
		function(opportunities) {				
			if (opportunities && $.trim(opportunities) != ""){
				$(opportunityBucket.list_selector).append(opportunities);
				loadOpportunities(opportunityBucket, opportunity_page + 1);
			}else if (opportunityBucket.next != null){
				loadOpportunities(opportunityBucket.next, 0);
			}
		}
	);
}

// link the buckets. 
function getLinkedBucketList(bucketArray){
	for(var i=0; i<bucketArray.length; i++){
		bucketArray[i].next = bucketArray[i+1]; 
	}
	return bucketArray[0];
}





