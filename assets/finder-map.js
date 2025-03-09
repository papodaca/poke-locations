(function (window) {
  window.onload = async function () {
    let map = L.map('map').setView([39.26628442213066, -101.11816406250001], 5);

    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}' + (L.Browser.retina ? '@2x.png' : '.png'), {
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, &copy; <a href="https://carto.com/attributions">CARTO</a>',
      subdomains: 'abcd',
      maxZoom: 15,
      minZoom: 0
    }).addTo(map);

    for (let ii = 0; ii <= 21; ii++) {
      window.fetch(`/assets/places_${ii}.json`).then(async function (res) {
        let places = await res.json();

        for (let place of places) {
          if (place == null || typeof place === "undefined" || typeof place.l === "undefined") {
            continue;
          }
          L.marker(place.l).addTo(map)
            .bindPopup(`<a target="_blank" href="https://www.google.com/maps/search/${encodeURIComponent(place.d)}">${place.n}</a></br><p>${place.d}</p>`);
        }
      });
    }
  };
})(window);
