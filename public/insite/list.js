function ScrollView(page, url, pageNum, pageSize, lookAheadPages) {
    var $page = $(page),
        $filter = $page.find(".scrollable-list-filter"),
        $filterTxt = $filter.find(".scrollable-list-filter-txt"),
        $scroll = $page.find(".iscroll-wrapper"),
        $list = $scroll.find("ul.ui-listview"),
        scroll = $scroll.jqmData("iscrollview"),
        topPage, lastPageNum, pageCount, lastPageIndex, pages;

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
        
    });

    $filter.find(".scrollable-list-filter-clear").click(function() {
        $filter.trigger("collapse");
        
    });

    function getContent(pageNum, pageSize, fnc) {
        $.ajax({
            url: url,
            data: { page: pageNum, pageSize: pageSize },
            success: function(data) {
                var rows = data.split("<li");
                fnc((rows.length > 1) ? rows.slice(1, pageSize) : []);
            }
        });
    }

    $scroll.bind({
        iscroll_onpulldown: function() {
            if (topPage + lookAheadPages > 0) {
                updateListPages();
                for (var i = pageCount - 2; i >= 0; i--)
                    pages[i + 1] = pages[i];
                pages[0] = [];
                topPage--;
                getContent(topPage, pageSize, function(data) {
                    pages[0] = data;
                });
                showPages(false);
            }
            else
                scroll.refresh();
        },
        iscroll_onpullup: function() {
            if (pages[lookAheadPages + 2].length > 0) {
                updateListPages();
                for (var i = 1; i < pageCount; i++)
                    pages[i - 1] = pages[i];
                pages[lastPageIndex] = [];
                topPage++;
                getContent(topPage + lastPageIndex, pageSize, function(data) {
                    pages[lastPageIndex] = data;
                });
                showPages(true);
            }
            else
                scroll.refresh();
        }
    });

    $list.listview({
        autodividersSelector: autodividersSelector
    });

    function updateListPages() {
        var content = $list.html().split("<li");
        var length = content.length;
        if (length > 1) {
            content = content.splice(1, length);
            pages[lookAheadPages] = content.splice(0, pageSize);
            if (content.length > 0)
                pages[lookAheadPages + 1] = content;
        }
    }

    function showPages(isUp) {
        var content = "";
        var halfPage = pages[lookAheadPages];
        var middleIndex = halfPage.length;
        if (middleIndex > 0) {
            content = "<li" + halfPage.join("<li");
            halfPage = pages[lookAheadPages + 1];
            if (halfPage.length > 0)
                content += "<li" + halfPage.join("<li");
        }
        $list.empty().append(content).listview("refresh");
        scroll.refresh(null, null, function() {
            if (typeof(isUp) !== "undefined" && middleIndex > 5) {
                var index = isUp ? middleIndex - 5 : middleIndex - 1;
                var item = $list.find("li").eq(index);
                if (item.length > 0)
                    scroll.scrollToElement(item[0], 0);
            }
        });
    }

    function reset() {
        // initialize global variables
        topPage = pageNum - lookAheadPages;
        lastPageNum = lookAheadPages + 2;
        pageCount = lastPageNum + lookAheadPages;
        lastPageIndex = pageCount - 1;
        pages = [];
        // initial data load
        var rowCount = pageSize * lastPageNum;
        if (topPage >= 0)
            rowCount += pageSize * (topPage + 1);
        getContent((topPage >= 0) ? topPage : 0, rowCount, function(data) {
            var currPage = topPage;
            while (currPage < 0) {
                pages.push([]);
                currPage++;
            }
            while (data.length > 0) {
                pages.push(data.splice(0, pageSize));
                currPage++;
            }
            while (currPage < lastPageNum) {
                pages.push([]);
                currPage++;
            }
            showPages();
        });
    }

    reset();
}
