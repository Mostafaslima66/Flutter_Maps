Uri getGeocodeUrl(String query) {
  return Uri.parse(
      'https://api.geoapify.com/v1/geocode/search?text=$query&apiKey=5b3ce3597851110001cf6248450a76d8a03f41e8b7cecefcdd86d6ec');
}

Uri getRouteUrl(String start, String end) {
  return Uri.parse(
      'https://api.geoapify.com/v1/routing?waypoints=$start|$end&mode=drive&apiKey=5b3ce3597851110001cf6248450a76d8a03f41e8b7cecefcdd86d6ec');
}
