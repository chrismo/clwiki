$(document).keydown(function (e) {
  if (window.location.href.endsWith("/edit")) {

  } else if (window.location.href.endsWith("/find")) {

  } else {
    if (e.key === "e") {
      window.location.href = window.location.href + "/edit";
    } else if (e.key === "f") {
      let url;
      let findPath;
      url = new URL(window.location.href).href;
      findPath = url.substring(0, url.lastIndexOf('/')) + '/find';
      window.location.href = findPath;
    }
  }
});
