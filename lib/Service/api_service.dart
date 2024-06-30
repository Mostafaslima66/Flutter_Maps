Uri getGeocodeUrl(String query) {
  return Uri.parse(
      'https://api.geoapify.com/v1/geocode/search?text=$query&apiKey='Write your API key');
}

Uri getRouteUrl(String start, String end) {
  return Uri.parse(
      'https://api.geoapify.com/v1/routing?waypoints=$start|$end&mode=drive&apiKey='Write your API key');
}
