$(document).ready(function() {

    //   $('a.fast-button').each(function() {
    //   var element = $(this).get(0);
    //   var href = $(this).attr('href');
    //   var button = $(this)
    //   new FastButton(element, function(){
    // 	  alert("fast anchor");
    // 	  // window.location.href = href;
    // 	  button.click();
    // 	});
    // });
    // make all submits fast buttons

    $('input:submit, a').each(function() {
        var element = $(this).get(0);
        var button = $(this);
        var href = $(this).attr('href');
        new FastButton(element,
        function() {
            if (href && href != '') {
                window.location.href = href;
            }
            else {
                button.click();
            }
        });
    });

});

function FastButton(element, handler) {
    this.element = element;
    this.handler = handler;
    element.addEventListener('touchstart', this, false);
};

FastButton.prototype.handleEvent = function(event) {
    switch (event.type) {
    case 'touchstart':
        this.onTouchStart(event);
        break;
    case 'touchmove':
        this.onTouchMove(event);
        break;
    case 'touchend':
        this.onClick(event);
        break;
    case 'click':
        this.onClick(event);
        break;
    }
};

FastButton.prototype.onTouchStart = function(event) {
    event.stopPropagation();
    this.element.addEventListener('touchend', this, false);
    document.body.addEventListener('touchmove', this, false);
    this.startX = event.touches[0].clientX;
    this.startY = event.touches[0].clientY;
    this.element.style.backgroundColor = "rgba(0,0,0,.7)";
};

FastButton.prototype.onTouchMove = function(event) {
    if (Math.abs(event.touches[0].clientX - this.startX) > 10 || Math.abs(event.touches[0].clientY - this.startY) > 10) {
        this.reset();
    }
};

FastButton.prototype.onClick = function(event) {
    event.stopPropagation();
    this.reset();
    this.handler(event);
    if (event.type == 'touchend') {
        preventGhostClick(this.startX, this.startY);
    }
    this.element.style.backgroundColor = "";
};

FastButton.prototype.reset = function() {
    this.element.removeEventListener('touchend', this, false);
    document.body.removeEventListener('touchmove', this, false);
    this.element.style.backgroundColor = "";
};

function preventGhostClick(x, y) {
    coordinates.push(x, y);
    window.setTimeout(gpop, 2500);
};

function gpop() {
    coordinates.splice(0, 2);
};

function gonClick(event) {
    for (var i = 0; i < coordinates.length; i += 2) {
        var x = coordinates[i];
        var y = coordinates[i + 1];
        if (Math.abs(event.clientX - x) < 25 && Math.abs(event.clientY - y) < 25) {
            event.stopPropagation();
            event.preventDefault();
        }
    }
};

document.addEventListener('click', gonClick, true);
var coordinates = [];
