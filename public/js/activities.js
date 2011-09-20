var activity_filter_enabled = false;

function checkForActivityChanges() {
    $.post('/app/Activity/refresh_if_changed');
}

function loadAllActivities() {
    var filter = getActivitiesFilter();
    $('#activity_filter_details').html('Filter: ' + filter.type + ', ' + filter.status + ', ' + filter.priority);
    var buckets = [];
    if (filter.status == 'Open') {
        buckets.push(
            {activity_method: 'past_due_activities', list_selector: '#no_date_activities', insert_before: true, next: null},
            {activity_method: 'no_date_activities', list_selector: '#today_activities', insert_before: true, next: null},
            {activity_method: 'today_activities', list_selector: '#future_activities', insert_before: true, next: null},
            {activity_method: 'future_activities', list_selector: '#completed_activities', insert_before: true, next: null}
        );
        $('#past_due_activities').show();
        $('#no_date_activities').show();
        $('#today_activities').show();
        $('#future_activities').show();
        $('#completed_activities').hide();
        $('#activity_complete_button').attr('href', 'javascript:completeSelectedActivities()').show();
    } else {
        buckets.push(
            {activity_method: 'completed_activities', list_selector: '#all_activities', insert_before: false, next: null}
        );
        $('#past_due_activities').hide();
        $('#no_date_activities').hide();
        $('#today_activities').hide();
        $('#future_activities').hide();
        $('#completed_activities').show();
        $('#activity_complete_button').attr('href', '#').hide();
    }
    loadActivities(getLinkedBucketList(buckets), 0, filter);
}

function getLinkedBucketList(bucketArray) {
	for(var i = 0; i < bucketArray.length; i++) {
		bucketArray[i].next = bucketArray[i+1]; 
	}
	return bucketArray[0];
}

function loadActivities(activityBucket, activity_page, jsonParams) {
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
                activity_filter_enabled = true;
            }
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
    else if ('completed_activities' == activity_method) {
        insertEmptyMessageIfEmpty('completed_activities', 'completed activities');
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
}

function toggleActivitiesFilter() {
    toggleCollapsible('activity_filter');
    $('#activity_filter_details').toggle();
}

function getActivitiesFilter() {
    return {
        'type': $('#activity_type_filter').val(),
        'status': $('#activity_status_filter').val(),
        'priority': $('#activity_priority_filter').val()
    };
}

function clearActivitiesFilter() {
    if (activity_filter_enabled) {
        activity_filter_enabled = false;
        $('#activity_type_filter').val('All');
        $('#activity_status_filter').val('Open');
        $('#activity_priority_filter').val('All');
        location.href = location.href.replace(/\?.*$/, '') + '?' + $.param(getActivitiesFilter());
    }
}

function filterActivities() {
    if (activity_filter_enabled) {
        activity_filter_enabled = false;
        location.href = location.href.replace(/\?.*$/, '') + '?' + $.param(getActivitiesFilter());
    }
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
