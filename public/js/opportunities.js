$(document).ready(function() {
	
   	$('#new-leads-button').click(function() {
		setNavContext('new-leads')
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#new-leads-button').addClass('ui-btn-active');
		$('#new-leads').show();
	});
	
	$('#follow-ups-button').click(function() {
		setNavContext('follow-ups')
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#follow-ups-button').addClass('ui-btn-active');
		$('#follow-ups').show();
	});
	
	$('#appointments-button').click(function() {
		setNavContext('appointments')
		$('.opp-tab').hide();
		$('.tab-button').removeClass('ui-btn-active')
		$('#appointments-button').addClass('ui-btn-active');
		$('#appointments').show();
	});
	
	$.ajaxSetup ({  
	    cache: false  
	});
	
	loadNewLeads(); 
	loadFollowUps();
	loadAppointments();
	
 });

function setNavContext(context){
	$.post('Opportunity/set_opportunities_nav_context', { context: context })
}


function loadNewLeads(){
	$('.opportunity-item').remove();
	loadOpportunities('todays_new_leads', 'span#todays-leads-list', 0);
	loadOpportunities('previous_days_new_leads', 'span#previous-days-leads-list', 0);
}

function loadFollowUps(){
	$('.opportunity-item').remove();
	loadOpportunities('past_due_follow_ups', 'span#past-due-follow-ups-list', 0);
	loadOpportunities('todays_follow_ups', 'span#todays-follow-ups-list', 0);
	loadOpportunities('by_last_activities', 'span#by-last-activities-list', 0);
	loadOpportunities('future_follow_ups', 'span#future-follow-ups-list', 0);
}

function loadAppointments(){
	$('.opportunity-item').remove();
	loadOpportunities('past_due_appointments', 'span#past-due-appointments-list', 0);
	loadOpportunities('todays_appointments', 'span#todays-appointments-list', 0);
	loadOpportunities('future_appointments', 'span#future-appointments-list', 0);
}

function loadOpportunities(opportunity_method, list_selector, opportunity_page){
	$.post('Opportunity/' + opportunity_method, { page: opportunity_page },
		function(opportunities) {	
			if (opportunities && $.trim(opportunities) != ""){
				$(list_selector).append(opportunities);
				loadOpportunities(opportunity_method, list_selector, opportunity_page + 1);
			} 
		}
	);
}