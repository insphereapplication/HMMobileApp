function showSpin(message) {
    $.mobile.savingMessage = message;
    $.mobile.pageSaving();
    $(":input").attr("disabled", true);
    setTimeout("hideSpin()", 5000);
}

function hideSpin() {
    $.mobile.pageSaving(true);
    return true;
}

var offline_bar_selector = ".ui-offline-bar",
    sync_spinner_selector = "#syncSpinner";

function updateConnectionStatusIndicator() {
    var $offline_bar_selector = $(offline_bar_selector);
    if ($offline_bar_selector.length > 0)
        $.post('/app/Settings/get_connection_status', function(ajax_result) {
            var result = ajax_result.split(",");
            var connection_status = result[0];
            var sync_status = result[1];
            if (connection_status === "Offline")
                $offline_bar_selector.show();
            else
                $offline_bar_selector.hide();
            $sync_spinner_selector = $(sync_spinner_selector);
            if ($sync_spinner_selector.length > 0)
                if (sync_status === "Syncing")
                    $sync_spinner_selector.show();
                else
                    $sync_spinner_selector.hide();
        });
}

var timeoutID = null;

function pollConnectionStatus() {
    updateConnectionStatusIndicator();
    // update connection status every 30000 ms
    timeoutID = setTimeout("pollConnectionStatus()", 30000);
}

function setAppActive() {
    if (timeoutID === null)
        pollConnectionStatus();
}

function setAppDeactive() {
    if (timeoutID !== null) {
        clearTimeout(timeoutID);
        timeoutID = null;
    }
}

$(document).bind("pageinit", function() {
    if (timeoutID === null)
        pollConnectionStatus();
});
