function findFocus() {
  if (window.location.href.endsWith('/find')) {
    $(".findForm input[type='text']")[0].focus();
  }
}

// to cope with rails 4 turbolinks
$(document).ready(findFocus);
$(document).on('page:change', findFocus);
