(function($) {
    $.widget("mobile.jqlistview", $.mobile.widget, {
        options: {
            filterselector: null,
            pagesize: 30,
            autoinitialize: true
        },
        _create: function() {
            var $this = this,
                $list = this.element.addClass("list-view"),
                $document = $(document),
                $window = $(window),
                loadUrl = $list.jqmData("loadurl"),
                o = this.options,
                pageSize = $list.jqmData("pagesize") || o.pagesize,
                autoInitialize = $list.jqmData("autoinitialize") || o.autoinitialize,
                requestData, currentPage, loadNext, loading, lastPos, proc_id, ldiv,
                $filter = $list.jqmData("filterselector") || o.filterselector,
                $filterTxt, filterTxt;
            $list.delegate("a.btn", "tap", function() {
                var $t = $(this);
                $t.addClass("btn-clicked");
                setTimeout(function() {
                    $t.removeClass("btn-clicked");
                }, 500);
            });
            function getContent(pageSize, resetFlag) {
                if (!loading) {
                    loading = true;
                    requestData.page = currentPage++;
                    requestData.pageSize = pageSize;
                    requestData.reset = resetFlag;
                    $.ajax({
                        url: loadUrl,
                        data: requestData,
                        success: function(data) {
                            var records = 0;
                            var pos = data.indexOf("<");
                            if (pos > 0) {
                                records = data.substr(0, pos);
                                data = data.substr(pos);
                            }
                            if (data.length > 0)
                                ldiv.before(data);
                            if (records < pageSize) {
                                loadNext = false;
                                ldiv.remove();
                            }
                            loading = false;
                        },
                        error: function() {
                            currentPage--;
                            loading = false;
                        }
                    });
                }
            }
            function clearProcId() {
                if (proc_id !== null) {
                    clearTimeout(proc_id);
                    proc_id = null;
                }
            }
            function checkScrolling() {
                proc_id = null;
                var top = $window.scrollTop();
                if (top >= ldiv.offset().top - $window.height())
                    getContent(pageSize, false);
                else if (top > lastPos)
                    proc_id = setTimeout(checkScrolling, 100);
                lastPos = top;
            }
            $list.parent().bind({
                scrollstop: function() {
                    if ($list.is(":visible") && loadNext) {
                        clearProcId();
                        checkScrolling();
                    }
                }
            });
            this._reset = function() {
                clearProcId();
                currentPage = 0;
                loadNext = true;
                loading = false;
                lastPos = 0;
                $.mobile.silentScroll(0);
                $list.empty().append("<div class='list-view-loading'>Loading...</div>"),
                ldiv = $list.find("div");
                if ($filter) {
                    requestData = getFilterData();
                    var txt = getFilterText();
                    if (txt.length > 0)
                        txt = " " + txt;
                    $filterTxt.text(filterTxt + txt);
                }
                else
                    requestData = {};
                getContent(pageSize, true);
            }
            if ($filter) {
                $filter = $($filter);
                $filterTxt = $filter.find(".list-filter-txt").find("span.ui-btn-text");
                filterTxt = $filterTxt.html();
                var index = filterTxt.indexOf("<");
                if (index > 0)
                    filterTxt = filterTxt.substr(0, index);
                filterTxt = $.trim(filterTxt);
                $filter.find(".list-filter-find").click(function() {
                    $filter.trigger("collapse");
                    $this._reset();
                });
                $filter.find(".list-filter-clear").click(function() {
                    if (clearFilter()) {
                        $filter.trigger("collapse");
                        $this._reset();
                    }
                });
            }
            if (autoInitialize)
                this._reset();
        },
        reset: function() {
            this._reset();
        }
    });
    $(document).bind("pagecreate", function(e) {
        $(":jqmData(role='jqlistview')", e.target).jqlistview();
    });
})(jQuery);
