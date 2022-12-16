function navigateToPage(page) {
  let url = new URL(window.location.href).href;
  window.location.href = url.substring(0, url.lastIndexOf('/')) + '/' + page;
}

function commonShortcuts(e) {
  if (e.key === "f") {
    navigateToPage('find');
  } else if (e.key === "h") {
    navigateToPage('FrontPage');
  } else if (e.key === "r") {
    navigateToPage('recent');
  }
}

$(document).keydown(function (e) {
  const anyModifiers = (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey);
  if (anyModifiers) {
    return;
  }

  if (window.location.href.endsWith("/edit")) {
  } else if (window.location.href.endsWith("/find")) {
  } else if (window.location.href.endsWith("/login")) {
    // this is important otherwise typing `e` while logging in refreshes the
    // page - doh!
  } else if (window.location.href.endsWith("/recent")) {
    commonShortcuts(e);
  } else {
    if (e.key === "e") {
      window.location.href = window.location.href + "/edit";
    } else {
      commonShortcuts(e);
    }
  }
});
