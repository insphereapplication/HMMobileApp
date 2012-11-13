function ScrollView(page, url, pageSize) {
    var $page = $(page),
        $filter = $page.find(".scrollable-list-filter"),
        $filterTxt = $filter.find(".scrollable-list-filter-txt")
                            .find("span.ui-btn-text"),
        $scroll = $page.find(".iscroll-wrapper"),
        scroll = $scroll.jqmData("iscrollview"),
        $list = $scroll.find(".scrollable-listview"),
        splitConstant = "<div class=\"ui-li ",
        $loading = $scroll.find(".iscroll-pullup"), loadingEnabled = true, loadingContent = "",
        filterTxt, requestData, currentpage, pages, $this = this;

    function adjustScrollView() {
        scroll.resizeWrapper();
        scroll.refresh();
    }

    $filter.bind({
        collapse: adjustScrollView,
        expand: adjustScrollView
    });

    $filter.find(".scrollable-list-filter-find").click(function() {
        $filter.trigger("collapse");
        $this.reset();
    });

    $filter.find(".scrollable-list-filter-clear").click(function() {
        if (clearFilter()) {
            $filter.trigger("collapse");
            $this.reset();
        }
    });

    function getContent(pageNum, pageSize, resetFlag, fnc) {
        requestData.page = pageNum;
        requestData.pageSize = pageSize;
        requestData.reset = resetFlag;
        $.ajax({
            url: url,
            data: requestData,
            success: fnc
        });
    }

    $scroll.bind({
        iscroll_onpullup: function() {
            if (pages[0].length > 0) {
                $list.append(pages[0]);
                pages[0] = pages[1];
                getContent(currentpage++, pageSize, false, function(data) {
                    pages[1] = data;
                });
                checkLoading(pages[0].length > 0);
            }
            scroll.refresh();
        }
    });

    function checkLoading(enable) {
        if (enable) {
            if (!loadingEnabled) {
                $loading.html(loadingContent);
                loadingEnabled = true;
            }
        } else {
            if (loadingEnabled) {
                if (loadingContent === "")
                    loadingContent = $loading.html();
                $loading.empty();
                loadingEnabled = false;
            }
        }
    }

    this.reset = function() {
        requestData = getFilterData();
        var txt = getFilterText();
        if (txt.length > 0)
            txt = " " + txt;
        $filterTxt.text(filterTxt + txt);
        currentpage = 3;
        pages = ["", ""];
        $list.empty();
        getContent(0, pageSize * 3, true, function(data) {
            var rows = data.split(splitConstant);
            if (rows.length > 1)
                $list.append(splitConstant + rows.splice(1, pageSize).join(splitConstant));
            if (rows.length > 1)
                pages[0] = splitConstant + rows.splice(1, pageSize).join(splitConstant);
            if (rows.length > 1)
                pages[1] = splitConstant + rows.splice(1, pageSize).join(splitConstant);
            checkLoading(pages[0].length > 0);
            scroll.refresh();
        });
    }

    filterTxt = $filterTxt.html();
    var index = filterTxt.indexOf("<");
    if (index > 0)
        filterTxt = filterTxt.substr(0, index);
    filterTxt = $.trim(filterTxt);

    $list.delegate("a.btn", "tap", function() {
        var $this = $(this);
        $this.addClass("btn-clicked");
        setTimeout(function() {
            $this.removeClass("btn-clicked");
        }, 500);
    })

    this.reset();
}
