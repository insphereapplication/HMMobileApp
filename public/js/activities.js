function loadAllActivities() {
    var buckets = getLinkedBucketList([
        {activity_method: 'past_due_activities', list_selector: '#no_date_activities', insert_before: true, next: null},
        {activity_method: 'completed_activities', list_selector: '#all_activities', next: null}
    ]);
    loadActivities(buckets, 0);
}

//link the buckets. 
function getLinkedBucketList(bucketArray) {
	for(var i = 0; i < bucketArray.length; i++) {
		bucketArray[i].next = bucketArray[i+1]; 
	}
	return bucketArray[0];
}

function loadActivities(activityBucket, activity_page, jsonParams, initLoad) {
    if (jsonParams == undefined) {
        jsonParams = {page: activity_page};
    } else {
        jsonParams.page = activity_page;
    }

    if (initLoad == undefined) {
        jsonParams.init_load = false;
    } else {
        jsonParams.init_load = initLoad;
    }

    var jsonString = "{";
    for (var index in jsonParams) {
        jsonString += index + " : " + jsonParams[index] + ",";
    }
    jsonString = jsonString.replace( /,$/, "" );
    jsonString += "}";

    $.post('/app/Activity/' + activityBucket.activity_method, jsonParams, // {page: page_number, filter: filter, search: search}
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
                enableFilters();
            }
        });
}

function disableFilters() {
}

function enableFilters() {
}

function filteringEnabled() {
}

function checkForNoActivities(activity_method) {
}
