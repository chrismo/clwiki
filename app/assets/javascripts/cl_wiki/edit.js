function editFocus() {
  let value;
  if (window.location.href.endsWith('/edit')) {
    let element = $("textarea")[0];
    element.focus();
    value = element.value;
    element.value = "";
    element.value = value;
  }
}

// to cope with rails 4 turbolinks
$(document).ready(editFocus);
$(document).on('page:change', editFocus);
