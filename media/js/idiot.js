window.addEvent('domready', function() {

  $('login_form').setStyle('display', 'none');

	$('show_login').addEvent('click', function(event) {
					$('not_logged').setStyle('display', 'none');
					$('login_form').setStyle('display', 'block');
	});
});

