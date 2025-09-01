using Toybox.Application;

class GrowPlantSettings {

    static function latitude() {
        var app = Application.getApp();
        var lat = app.getProperty("lat");  // replacement for deprecated getProperty
        if (lat == null) {
            lat = 40.7128; // default
        }
        return lat;
    }

    static function longitude() {
        var app = Application.getApp();
        var lon = app.getProperty("lon");  // replacement for deprecated getProperty
        if (lon == null) {
            lon = -74.0060; // default
        }
        return lon;
    }
}
