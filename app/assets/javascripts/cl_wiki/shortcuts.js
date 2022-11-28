function navigateToFind() {
  let url = new URL(window.location.href).href;
  window.location.href = url.substring(0, url.lastIndexOf('/')) + '/find';
}

$(document).keydown(function (e) {
  if (window.location.href.endsWith("/edit")) {
  } else if (window.location.href.endsWith("/find")) {
  } else if (window.location.href.endsWith("/login")) {
    // this is important otherwise typing `e` while logging in refreshes the
    // page - doh!
  } else if (window.location.href.endsWith("/recent")) {
    if (e.key === "f") {
      navigateToFind();
    }
  } else {
    if (e.key === "e") {
      window.location.href = window.location.href + "/edit";
    } else if (e.key === "f") {
      navigateToFind();
    }
  }
});
