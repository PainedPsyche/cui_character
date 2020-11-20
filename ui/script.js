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
        else if (event.data.action == 'enableTabs') {
            for (const value of Object.values(event.data.tabs)) {
                $('button' + '#tab-' + value + '.tablinks').show()
                loadTabContent(value, event.data.character)
            }
        }
        else if (event.data.action == 'activateTab') {
            $('#tab-' + event.data.tab).addClass('active');
            $('#' + event.data.tab).show()
        }
        else if (event.data.action == 'reloadTab') {
            $('div#' + event.data.tab + '.tabcontent').empty();
            loadTabContent(event.data.tab, event.data.character)
        }
    });
});

/*  content loading     */
function loadTabContent(tabName, charData) {
    $.get('pages/' + tabName + '.html', function(data) {
        let tab =  $('div#' + tabName + '.tabcontent');
        tab.html(data);
        if (tabName == 'style') {
            loadOptionalContent(tab, charData.sex);
        }
        refreshTabData(tab, charData);
        if (tabName == 'identity') {
            updatePortrait('mom');
            updatePortrait('dad');
        }
    });
}

function loadOptionalContent(element, gender) {
    let hair = element.find('#hair');
    let facialhair = element.find('#facialhair')
    let blusher = element.find('#blusher')

    hair.empty()
    facialhair.empty()
    blusher.empty()

    if (facialhair.hasClass('group')) {
        facialhair.removeClass('group')
    }

    if (blusher.hasClass('group')) {
        blusher.removeClass('group')
    }

    let hairpage = 'pages/optional/hair_';
    // male
    if (gender == 0) {
        hairpage = hairpage + 'male.html'
        facialhair.addClass('group')
        $.get('pages/optional/facialhair.html', function(data) {
            facialhair.html(data)
        });
    }
    // female
    else if (gender == 1) {
        hairpage = hairpage + 'female.html'
        blusher.addClass('group')
        $.get('pages/optional/blusher.html', function(data) {
            blusher.html(data)
        });
    }

    $.get(hairpage, function(data) {
        hair.html(data)
    });
}

var accept = false;

var popupCallback = null;
var popupVal = false

/*  window controls   */
function openPopup(data, callback, val) {
    $('.popup .title').text(data.title)
    $('.popup .message').text(data.message)
    $('.popup').fadeIn(100);
    $('.overlay').fadeIn(100);
    $('#main').css('pointer-events', 'none');
    popupCallback = callback
    popupVal = val
}

function closePopup() {
    $('.popup').fadeOut(100);
    $('.overlay').fadeOut(100);
    $('#main').css('pointer-events', 'auto');

    if (popupCallback) {
        popupCallback = null;
    }
    popupVal = false
}

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

    let action = accept ? 'save' : 'discard';
    let message = 'Are you sure you want to ' + action + ' your changes and exit?';
    let popupData = { 
        title: 'confirmation', 
        message: message
    };
    openPopup(popupData, closeWindow, accept);
});

$('.popup #no').on('click', function(evt) {
    evt.preventDefault();
    closePopup();
});

$('.popup #yes').on('click', function(evt) {
    evt.preventDefault();

    if (popupCallback) {
        popupCallback(popupVal)
    }

    closePopup();
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
function updateGender(value) {
    $.post('https://cui_character/updateGender', JSON.stringify({
        value: value,
    }));
}

function updateHeadBlend(key, value) {
    $.post('https://cui_character/updateHeadBlend', JSON.stringify({
        key: key,
        value: value,
    }));
}

function updateFaceFeature(key, value, index) {
    $.post('https://cui_character/updateFaceFeature', JSON.stringify({
        key: key,
        value: value,
        index: index,
    }));
}

function updateEyeColor(value) {
    $.post('https://cui_character/updateEyeColor', JSON.stringify({
        value: value,
    }));
}

function updateHeadOverlay(key, keyPaired, value, index, isOpacity) {
    $.post('https://cui_character/updateHeadOverlay', JSON.stringify({
        key: key,
        keyPaired: keyPaired,
        value: value,
        index: index,
        isOpacity: isOpacity,
    }));
}

function updatePortrait(elemId) {
    let portraitImgId = '#parents' + elemId;
    let portraitName = $('select#' + elemId + '.headblend').find(':selected').data('portrait');
    $(portraitImgId).attr('src', 'https://nui-img/char_creator_portraits/' + portraitName);
}

// working around unintuitive/bad behavior:
// https://forum.jquery.com/topic/alert-message-when-clicked-selected-radio-button
var radioChecked = false
$(document).on('mouseenter', 'input:radio[name=sex] + label', function(evt) {
    if ($(this).prev().is(':checked')) {
        radioChecked = true;
    }
    else {
        radioChecked = false;
    }
});

$(document).on('click', 'input:radio[name=sex]', function(evt) {
    if(radioChecked == false)
    {
        let popupData = {
            title: 'confirmation', 
            message: 'Changing your character\'s gender will reset all current customizations. Are you sure you want to do this?'
        };
        openPopup(popupData, function(target) {
            target.prop('checked', true);
            updateGender(target.val());
        }, $(this));
    }
    return false;
});

$(document).on('change', 'select.headblend', function(evt) {
    updatePortrait($(this).attr('id'));
    updateHeadBlend($(this).attr('id'), $(this).val());
});

$(document).on('change', 'select.eyecolor', function(evt) {
    updateEyeColor($(this).val());
});

$(document).on('refresh', 'input[type=range].headblend', function(evt) {
    let valueLeft = $(this).parent().siblings('.valuelabel.left');
    let valueRight = $(this).parent().siblings('.valuelabel.right');
    valueLeft.text((100 - $(this).val()).toString() + '%');
    valueRight.text($(this).val().toString() + '%');
});

$(document).on('input', 'input[type=range].headblend', function(evt) {
    $(this).trigger('refresh')
    updateHeadBlend($(this).attr('id'), $(this).val());
});

$(document).on('input', 'input[type=range].facefeature', function(evt) {
    updateFaceFeature($(this).attr('id'), $(this).val(), $(this).data('index'));
});

$(document).on('change', 'select.headoverlay', function(evt) {
    // find the opacity range slider id for this feature
    let pairedId = $(this).parents().eq(2).find('.headoverlay').eq(1).attr('id');
    updateHeadOverlay($(this).attr('id'), pairedId, $(this).val(), $(this).data('index'), false);
});

$(document).on('refresh', 'input[type=range].headoverlay', function(evt) {
    let valueCenter = $(this).parent().siblings('.valuelabel.center');
    valueCenter.text($(this).val().toString() + '%');
});

$(document).on('input', 'input[type=range].headoverlay', function(evt) {
    $(this).trigger('refresh')

    // find the style select list id for which this is the opacity value
    let pairedId = $(this).parents().eq(2).find('.headoverlay').eq(0).attr('id');
    updateHeadOverlay($(this).attr('id'), pairedId, $(this).val(), $(this).data('index'), true);
});

/*  interface and current character synchronization     */
function refreshTabData(tab, data) {
    for (const [key, value] of Object.entries(data)) {
        let keyId = '#' + key;
        let control = tab.find(keyId);
        if (control.length) {
            let controltype = control.prop('nodeName');
            if (controltype == 'SELECT') { // arrow lists
                control.val(value);
            }
            else if (controltype == 'INPUT') { // range sliders
                // NOTE: Check out property 'type' (ex. range) if this isn't unique enough
                control.val(value)
                control.trigger('refresh')
            }
            else if (controltype == 'DIV') { // radio button groups
                let radio = control.find(':radio[value=' + value + ']');
                radio.prop('checked', true);
            }
        }
    }
}

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