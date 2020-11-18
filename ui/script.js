$(document).ready(function() {
    window.addEventListener('message', function(event) {
        if (event.data.action == 'setVisible') {
            if (event.data.show) {
                $('body').fadeIn(100)
            }
            else {
                $('body').fadeOut(100)
            }
        }
        else if (event.data.action == 'clearAllTabs') {
            $('.tablinks').hide()
            $('.tablinks').removeClass('active');
            $('.tabcontent').hide()
            $('.tabcontent').empty()
        }
        else if (event.data.action == 'enableTab') {
            $('button' + '#tab-' + event.data.tab + '.tablinks').show()
            $.get('pages/' + event.data.tab + '.html', function(data) {
                $('div#' + event.data.tab + '.tabcontent').html(data);
            });
        }
        else if (event.data.action == 'activateTab') {
            $('#tab-' + event.data.tab).addClass('active');
            $('#' + event.data.tab).show()
        }
    });
});


/*  window controls   */
function closeWindow(save) {
    $.post('https://cui_character/close', JSON.stringify({save:save}));
}

function openTab(evt, tab) {
    let wasActive = $(evt.target).hasClass('active');

    $('.tabcontent').hide();
    $('.tablinks').removeClass('active');
    $('#' + tab).show();

    if (!wasActive) {
        $.post('https://cui_character/playSound', JSON.stringify({sound:'tabchange'}));
    }

    $(evt.target).addClass('active')
}

var accept = false;
$('.panelbottom button').on('click', function(evt) {
    evt.preventDefault();
    $.post('https://cui_character/playSound', JSON.stringify({sound:'buttonclick'}));
});

$('#main .menuclose').on('click', function(evt) {
    evt.preventDefault();
    if (evt.target.id == 'accept') {
        accept = true;
    }
    else if (evt.target.id == 'cancel') {
        accept = false;
    }
    $('.popup').fadeIn(100);
    $('.overlay').fadeIn(100);
    $('#main').css('pointer-events', 'none');
});

$('.popup button').on('click', function(evt) {
    evt.preventDefault();
    $('.popup').fadeOut(100);
    $('.overlay').fadeOut(100);
    $('#main').css('pointer-events', 'auto');
});

$('.popup #yes').on('click', function(evt) {
    evt.preventDefault();

    let save = false;
    if (accept == true) {
        save = true;
    }

    closeWindow(save)
});

/*  option/value ui controls   */

$(document).on('click', '.list .controls button', function(evt) {
    let list = $(this).siblings('select').first();
    let numOpt = list.children('option').length
    let oldVal = list.find('option:selected');
    let newVal = null;

    if ($(this).hasClass('left')) {
        if (list.prop('selectedIndex') == 0) {
            newVal = list.prop('selectedIndex', numOpt - 1);
        }
        else {
            newVal = oldVal.prev();
        }
    }
    else if ($(this).hasClass('right')) {
        if (list.prop('selectedIndex') == numOpt - 1) {
            newVal = list.prop('selectedIndex', 0);
        }
        else {
            newVal = oldVal.next();
        }
    }
    oldVal.prop('selected', false)
    newVal.prop('selected', true)
    newVal.trigger('change')
});

/*  option/value change effects     */
function updateHeadBlend(key, value) {
    $.post('https://cui_character/updateHeadBlend', JSON.stringify({
        key: key,
        value: value,
    }));
}

function updateHeadOverlay(value, opacity) {
    $.post('https://cui_character/updateHeadOverlay', JSON.stringify({
        value: value,
        opacity: opacity,
    }));
}

$(document).on('change', 'select.headblend', function(evt) {
    updateHeadBlend($(this).attr('id'), $(this).val())
});

$(document).on('input', 'input[type=range].headblend', function(evt) {
    updateHeadBlend($(this).attr('id'), $(this).val())
});

/*
$('input[type=radio]').on('change', function(evt) {
    evt.preventDefault();
    update()
});
*/

/* TODO: Possibly add more sounds (mouseover?)
$('.panelbottom button').mouseenter(function(evt) {
    console.log('hovered')
    $.post('https://cui_character/playSound', JSON.stringify({sound:'mouseover'}));
});

$('.radioitem input:radio:not(:checked) + label').hover(function(evt) {
    console.log('hovered')
    $.post('https://cui_character/playSound', JSON.stringify({sound:'mouseover'}));
});
*/