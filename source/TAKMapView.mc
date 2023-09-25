import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Communications;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity;

class CustomMapMarker extends WatchUi.MapMarker {
    private var _label;

    public function initialize(loc) {
        MapMarker.initialize(loc);
    }

    public function setLabel(label) {
        MapMarker.setLabel(label);
        _label = label;
    }

    public function getLabel() {
        return _label;
    }
}

class TAKMapView extends WatchUi.MapTrackView {
    var vectorTarget = null; 
    var markers = {};
    var distance = null;
    var session;
    

    var screenHeight;
    var screenWidth;

    function showMarker(uid) {
        var diff = 0.01;
        if (markers == null || markers.hasKey(uid) == false) {
            return;
        }

        var marker = markers.get(uid);
        var ownPosition = marker.getLocation().toDegrees();
        var top_left = new Position.Location({:latitude => ownPosition[0]+diff, :longitude =>ownPosition[1]-diff, :format => :degrees});
        var bottom_right = new Position.Location({:latitude => ownPosition[0]-diff, :longitude =>ownPosition[1]+diff, :format => :degrees});

        setMapMode(WatchUi.MAP_MODE_BROWSE);
        setMapVisibleArea(top_left, bottom_right);     
    }

   function initialize() {
        WatchUi.MapTrackView.initialize();

        var pos = Position.getInfo().position;
        var ownPosition = pos.toDegrees();
        var diff = 0.005;
        var top_left = new Position.Location({:latitude => ownPosition[0]+diff, :longitude =>ownPosition[1]-diff, :format => :degrees});
        var bottom_right = new Position.Location({:latitude => ownPosition[0]-diff, :longitude =>ownPosition[1]+diff, :format => :degrees});

        setMapMode(WatchUi.MAP_MODE_PREVIEW);
        setMapVisibleArea(top_left, bottom_right);        
        setScreenVisibleArea(0, 0, Toybox.System.getDeviceSettings().screenWidth, Toybox.System.getDeviceSettings().screenHeight/2+40);

        screenHeight = System.getDeviceSettings().screenHeight;
        screenWidth = System.getDeviceSettings().screenWidth;
    }

    function onUpdate(dc) {
        if (distance != null) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([[0,screenHeight-40], [screenWidth,screenHeight-40],  [screenWidth,screenHeight], [0,screenHeight]]);
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT); 
            dc.drawText(screenWidth / 2, screenHeight - 40 ,  Graphics.FONT_TINY, distance, Graphics.TEXT_JUSTIFY_CENTER);
        }      

        if (session != null && session.isRecording() && Activity.getActivityInfo().elapsedDistance != null) {
            var elapsedDistance = Activity.getActivityInfo().elapsedDistance;
            if (elapsedDistance < 1000) {
                elapsedDistance = elapsedDistance.format("%.0f") + " m";
            } else {
                elapsedDistance = (elapsedDistance/1000).format("%.2f") + " km";
            }
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([[0,screenHeight-40], [screenWidth,screenHeight-40],  [screenWidth,screenHeight], [0,screenHeight]]);
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT); 
            dc.drawText(screenWidth / 2, screenHeight - 40 ,  Graphics.FONT_TINY, elapsedDistance, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }


    function addMarker(data) {
        if (data.size()<6) {
            return;
        }
        var uid = data[1];
        var lat = data[2].toDouble();
        var lon = data[3].toDouble();
        var label = data[4];
        var type = data[5];

        if (uid == null || lat == null || lon == null || label == null || type == null) {
            return;
        }
        
        var location = new Toybox.Position.Location(
            {
            :latitude => lat,
            :longitude => lon,
            :format => :degrees
            }
        );

        
        var marker = new CustomMapMarker(location);

        // It's a type we don't support (yet)
        if (TAKConst.icon.hasKey(type) == false) {
            return;
        }

        var icon = WatchUi.loadResource(TAKConst.icon.get(type));

        marker.setIcon(icon, icon.getWidth()/2, icon.getHeight()/2);
        marker.setLabel(label);
        markers.put(uid, marker);

        setMapMarker(markers.values());  
        
        if (uid.equals(vectorTarget)) {
            // Redraw vector if vector target was updated changed
            drawVector(uid);
        }
 
    }

    function drawVector(uid) {
        if (markers == null || markers.hasKey(uid) == false) {
            // We do not currently have an object with this UID in our markers
            // This should not happen if plugin sends us the data first
            return;
        }

        vectorTarget = uid;

        var marker = markers.get(uid);
        var poly = new WatchUi.MapPolyline();   
        poly.setWidth(4);
        poly.setColor(Graphics.COLOR_RED);
        poly.addLocation(Position.getInfo().position);   
        poly.addLocation(marker.getLocation());
        setPolyline(poly);

        var metres = calc_distance(Position.getInfo().position, marker.getLocation());
        if (metres < 1000) {
            distance = metres.format("%.0f") + " m";
        } else {
            distance = (metres/1000).format("%.2f") + " km";
        }
        
    }

    function drawRoute(data) {
        // data[1] is the objects UID, 
        // not storing it on the watch since we can only show only one polyline anyway
        // var uid = data[1];      

        var poly = new WatchUi.MapPolyline();   
        poly.setWidth(4);
        poly.setColor(Graphics.COLOR_RED);

        for (var i = 2; i < data.size(); i++) {  
            var coord = data[i];          
            var lat = coord.substring(0, coord.find(";"));
            var lon = coord.substring(coord.find(";")+1, coord.length());
            poly.addLocation(new Position.Location({:latitude => lat.toDouble(), :longitude =>lon.toDouble(), :format => :degrees}));
        }   
        
        setPolyline(poly);

  
    }

    function removeMarker(uid) {
        if (markers == null) {
            return;
        }

        markers.remove(uid);
        if (markers.size() > 0) {
            setMapMarker(markers.values());
        }  

    }

    function clear() {
        distance = null;
        vectorTarget = null;
        if (markers != null && markers.size() > 0) {
            setMapMarker(markers.values());
        }  
    }

    function calc_distance(loc1, loc2) {
        var lr1 = loc1.toRadians();
        var lr2 = loc2.toRadians();

        var lat1 = lr1[0];
        var lon1 = lr1[1];
        var lat2 = lr2[0];
        var lon2 = lr2[1];
      
        return Geodetic_distance_rad(lat1, lon1, lat2, lon2);
    }
    
    function Geodetic_distance_rad(lat1, lon1, lat2, lon2) {
        var dy = (lat2-lat1);
        var dx = (lon2-lon1);

        var sy = Math.sin(dy / 2);
        sy *= sy;

        var sx = Math.sin(dx / 2);
        sx *= sx;

        var a = sy + Math.cos(lat1) * Math.cos(lat2) * sx;

        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        var R = 6371000; 
        return R * c;
    }


}