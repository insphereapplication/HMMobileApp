var newLeadsBtn, followUpBtn, apptsBtn, scrollView, filter, followupFlt, apptsFlt, selection;

function initialize(page, url, pageSize, selected_tab) {
    var $page = $(page);
    newLeadsBtn = $page.find("#new-leads-button");
    followUpBtn = $page.find("#follow-ups-button");
    apptsBtn = $page.find("#appointments-button");
    filter = $page.find(".scrollable-list-filter");
    followupFlt = filter.find(".opp_followup_filter");
    apptsFlt = filter.find(".appts_followup_filter");
    selection = selected_tab;
    scrollView = new ScrollView($page, url, pageSize);
    setSelectedTab(selected_tab);
    newLeadsBtn.click(function() {
        if (selection !== "new-leads") {
            setSelectedTab("new-leads");
            scrollView.reset();
        }
    });
    followUpBtn.click(function() {
        if (selection !== "follow-ups") {
            setSelectedTab("follow-ups");
            scrollView.reset();
        }
    });
    apptsBtn.click(function() {
        if (selection !== "appointments") {
            setSelectedTab("appointments");
            scrollView.reset();
        }
    });
}

function setSelectedTab(selected_tab) {
    selection = selected_tab;
    if (selection === "new-leads") {
        filter.hide();
    } else {
        filter.show();
        if (selection === "follow-ups") {
            apptsFlt.hide();
            followupFlt.show();
        } else {
            followupFlt.hide();
            apptsFlt.show();
        }
    }
    scrollView.adjustScrollView();
}

function clearFilter() {
    if (selection === "follow-ups") {
        $("#followup_status_reason_filter").val("All").selectmenu("refresh");
        $("#followup_sort_by_filter").val("LastActivityDateAscending").selectmenu("refresh");
        $("#followup_created_filter").val("All").selectmenu("refresh");
        $("#followup_daily_filter").attr("checked", false).checkboxradio("refresh");
    } else {
        $("#appointments_select_filter").val("All").selectmenu("refresh");
        $("#appointments_search_input").val("");
    }
    return true;
}

function getFilterData() {
    if (selection === "new-leads")
        return {};
    if (selection === "follow-ups")
        return {
            "statusReason": $("#followup_status_reason_filter").val(),
            "sortBy": $("#followup_sort_by_filter").val(),
            "created": $("#followup_created_filter").val(),
            "isDaily": $("#followup_daily_filter").attr("checked") ? "true" : "false"
        };
    return {
        "filter": $("#appointments_select_filter").val(),
        "search": $("#appointments_search_input").val()
    };
}

function getFilterText() {
    var text = "";
    if (selection === "follow-ups") {
        text = getSelectValue("#followup_status_reason_filter") + ", " +
            getSelectValue("#followup_sort_by_filter") + ", " +
            getSelectValue("#followup_created_filter");
        if ($("#followup_daily_filter").attr("checked"))
            text += ", Daily";
    }
    else if (selection === "appointments") {
        text = getSelectValue("#appointments_select_filter");
        var txt = $("#appointments_search_input").val();
        if (txt.length > 0)
            text += ", " + txt;
    }
    return text;
}

function getSelectValue(idSelector) {
    var select = $(idSelector)[0];
    return select.options[select.selectedIndex].text;
}
