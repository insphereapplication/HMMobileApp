function loadAllActivities() {
	disableSearchButtons();
    var filter = getActivitiesFilter();
    $('#activity_filter_details').html('Filter: ' + filter.type + ', ' + filter.status + ', ' + filter.priority);
    var buckets = [];
    if (filter.status == 'Today') {
        buckets.push(
            {activity_method: 'past_due_activities', list_selector: '#no_date_activities', insert_before: true, next: null},
            {activity_method: 'no_date_activities', list_selector: '#today_activities', insert_before: true, next: null},
            {activity_method: 'today_activities', list_selector: '#future_activities', insert_before: true, next: null}
        );
        $('#future_activities').hide();
    }
    else if (filter.status == 'Next7Days') {
        buckets.push(
            {activity_method: 'past_due_activities', list_selector: '#no_date_activities', insert_before: true, next: null},
            {activity_method: 'no_date_activities', list_selector: '#today_activities', insert_before: true, next: null},
            {activity_method: 'today_activities', list_selector: '#future_activities', insert_before: true, next: null},
            {activity_method: 'future_activities', list_selector: '#all_activities', insert_before: false, next: null}
        );
    }
    else {
        buckets.push(
            {activity_method: 'no_date_activities', list_selector: '#today_activities', insert_before: true, next: null}
        );
        $('#past_due_activities').hide();
        $('#today_activities').hide();
        $('#future_activities').hide();
    }
    // disable filter
    loadActivities(getLinkedBucketList(buckets), 0, filter);
	
}

// this creates two one-time handlers for the 'clear' and 'filter' buttons. They must be removed during a page load, and will be re-added when the load is done.
function initializeFilterButtonHandlers(){
	$('#activity-search-button').click(function(){
		filterActivities();
	});
	
	$('#activity_filter_clear').click( function()
	{
	  		clearActivitiesFilter();
	});
	//$('#activity-collapsible-bar').show();
	$('#do-nothing-button').hide();

}

function disableSearchButtons(){
	$('#activity-search-button').unbind('click');
	$('#activity_filter_clear').unbind('click');
	//$('#activity-collapsible-bar').hide();
	$('#do-nothing-button').hide();


}


function getLinkedBucketList(bucketArray) {
	for(var i = 0; i < bucketArray.length; i++) {
		bucketArray[i].next = bucketArray[i+1]; 
	}
	return bucketArray[0];
}

var counter = 0;
function loadActivities(activityBucket, activity_page, jsonParams) {
	counter++;
    jsonParams.page = activity_page;
    $.post('/app/Activity/' + activityBucket.activity_method, jsonParams,
        function(activities) {
            if (activities && $.trim(activities) != "") {
                if (activityBucket.insert_before)
                    $(activityBucket.list_selector).before(activities);
                else
                    $(activityBucket.list_selector).append(activities);
                loadActivities(activityBucket, activity_page + 1, jsonParams);
            }
            else if (activityBucket.next != null) {
                checkForNoActivities(activityBucket.activity_method);
                loadActivities(activityBucket.next, 0, jsonParams);
            }
            else {
                checkForNoActivities(activityBucket.activity_method);
            }
            counter--;
            if (counter == 0)
                initializeFilterButtonHandlers();
        });
}

function checkForNoActivities(activity_method) {
    if ('past_due_activities' == activity_method) {
        insertEmptyMessageIfEmpty('past_due_activities', 'past due activities');
    }
    else if ('no_date_activities' == activity_method) {
        insertEmptyMessageIfEmpty('no_date_activities', 'activities without date');
    }
    else if ('today_activities' == activity_method) {
        insertEmptyMessageIfEmpty('today_activities', 'today activities');
    }
    else if ('future_activities' == activity_method) {
        insertEmptyMessageIfEmpty('future_activities', 'future activities');
    }
}

function insertEmptyMessageIfEmpty(folderId, message) {
    var id = '#' + folderId;
    var item = $(id + ' + li');
    if (item.length == 0 || (item.attr('id') ? true : false)) {
        $(id).after('<span style="display:block; margin-left:auto; margin-right:auto; text-align: center;">No ' + message + ' found with current filter</span>');
    }
}

function toggleCollapsible(id) {
    $('#' + id + '_icon').toggleClass('ui-icon-plus ui-icon-minus');
    $('#' + id + '_content').toggleClass('ui-collapsible-content-collapsed');
	$('#' + id + '_details').toggle();
}

function toggleActivitiesFilter() {
	
    toggleCollapsible('activity_filter');
}

function getActivitiesFilter() {
    return {
        'type': $('#activity_type_filter').val(),
        'status': $('#activity_status_filter').val(),
        'priority': $('#activity_priority_filter').val()
    };
}

function clearActivitiesFilter() {
    $('#activity_type_filter').val('All');
    $('#activity_status_filter').val('Today');
    $('#activity_priority_filter').val('All');
    location.href = location.href.replace(/\?.*$/, '') + '?' + $.param(getActivitiesFilter());
}

function filterActivities() {
	disableSearchButtons();
	toggleCollapsible('activity_filter');
	showFilterParams();
    location.href = location.href.replace(/\?.*$/, '') + '?' + $.param(getActivitiesFilter());
}


function showFilterParams(){
    var filter = getActivitiesFilter();
    $('#activity_filter_details').html('Filter: ' + filter.type + ', ' + filter.status + ', ' + filter.priority);
}

function completeSelectedActivities() {
    var ids = $('input:checked', $('#all_activities')).parent().map(function() { return $(this).attr('activity-id'); }).get();
    if (ids.length > 0) {
        location.href = location.href.replace(/\?.*$/, '') + '?' + $.param({ 'selected-activity': ids });
    } else {
        $.post('/app/Activity/complete_activities_alert');
    }
}


function onRowClick(e, width, url) {
    if (e.pageX < width) {
        $('input', $(e.target).parent()).click();
    } else {
        window.open(url);
    }
}
