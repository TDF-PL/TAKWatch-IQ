import Toybox.Application;
import Toybox.Communications;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Sensor;
import Toybox.Attention;
import Toybox.PersistedContent;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Timer;

var page = 0;
var crashOnMessage = false;
var hasDirectMessagingSupport = true;
var hr;
var messageText;
var connectionValid;
var statsSentTimestamp;

var _timer;

var VIBPROF_500ms = new Attention.VibeProfile(50, 500);
var VIBPROF_200ms = new Attention.VibeProfile(50, 200);
var VIB = [VIBPROF_500ms];
var VIB_ERROR = [VIBPROF_200ms, VIBPROF_200ms, VIBPROF_200ms];


class MsgListener extends Communications.ConnectionListener {
    public function initialize() {
        Communications.ConnectionListener.initialize();
    }

    public function onComplete() as Void {
        if (connectionValid == null || connectionValid == false) {
            connectionValid = true;
            Toybox.Attention.vibrate(VIB);
            WatchUi.pushView(new TAKMsgView("Phone connection\nOK.", false), new TAKDataDelegate(), WatchUi.SLIDE_UP);
        }
    }

    public function onError() as Void {
        if (connectionValid == null || connectionValid == true) {
            connectionValid = false;
            Toybox.Attention.vibrate(VIB_ERROR);
            WatchUi.pushView(new TAKMsgView("Phone connection\nFAILED.", true), new TAKDataDelegate(), WatchUi.SLIDE_UP);
        }
    }
}

class TAKWatch extends Application.AppBase {

    private var view as TAKMapView;
    public var listener;

    function getApp() as TAKWatch {
        return Application.getApp() as TAKWatch;
    }

    function toggleHRSensor() {
        if (Properties.getValue("sendhr")) {
            Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE] );
            Sensor.enableSensorEvents( method( :onSensor ) );
        } else {
            Sensor.disableSensorType( Sensor.SENSOR_HEARTRATE );
        }
    }

    function initialize() {
        Application.AppBase.initialize();
        statsSentTimestamp = Time.now().value();
        toggleHRSensor();
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition)); 
        view = new TAKMapView();
        listener = new MsgListener();
        _timer = new Timer.Timer();
    }

    function onStart(params) {
        if(Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(method(:onMessage) as  Toybox.Communications.PhoneMessageCallback);
        } else {
            hasDirectMessagingSupport = false;
        }
        sync();
        _timer.start(method(:sync), 300000, true);
    }

    function sync() as Void {
        sendMessageToApp(["ready"]);
    }

    function onPosition(loc as Toybox.Position.Info)  as Void {
        if (view.vectorTarget != null) {
            view.drawVector(view.vectorTarget);
        }
    }

    function sendMessageToApp(msg) {
        Communications.transmit(msg, null, listener);
    }

    function onSensor(sensorInfo as Sensor.Info) as Void {    

        if (statsSentTimestamp != null && Time.now().value() - statsSentTimestamp < 5) {
                return;
        }

        hr = sensorInfo.heartRate;

        if (hr != null) {

            
            try {
                var msg = [];
                msg.add("stats");
                msg.add(hr.toString());
                var stats = System.getSystemStats();
                if (stats != null) {
                    var pwr = stats.battery;
                    var batStr = Lang.format( "$1$", [ pwr.format( "%2d" ) ] );
                    msg.add(batStr);
                }
                sendMessageToApp(msg);
                statsSentTimestamp = Time.now().value();
            } catch (e) {
                
            }


        }
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    public function getInitialView() as Array<Views or InputDelegates>? {
        return [view, new $.TAKMapDelegate(view)] as Array<Views or InputDelegates>;
    }

    /* This is called when the TAKWatch plugin sends a message via 
    /  connectIQ.sendMessage(device,app, String[])   
    /
    */
    function onMessage(msg)  {

        //Toybox.Attention.vibrate(VIB);
        if (msg == null || msg.data == null || msg.data.size() < 1) {
            // Empty message
            return;
            }

        // When data[0] = waypoint
        // Create waypoint on the watch (permanent)
        if (msg.data[0].equals("waypoint")) {
            var lat = msg.data[1].toDouble();
            var lon = msg.data[2].toDouble();
            var location = new Toybox.Position.Location(
                {
                :latitude => lat,
                :longitude => lon,
                :format => :degrees
                }
            );

            Toybox.PersistedContent.saveWaypoint(location, {:name => msg.data[3]});

            // TODO: Make vibrations optional
            Toybox.Attention.vibrate(VIB);

        // When data[0] = marker
        // Create marker on the MapView (transient) 
        } else if (msg.data[0].equals("marker")){
            view.addMarker(msg.data);

        // When data[0] = maparea
        // adjust the visible area of our MapView  
        // This is not currnetly used and probably won't work due to CIQ limitations
        } else if (msg.data[0].equals("maparea")){
            var lat1 = msg.data[1].toDouble();
            var lon1 = msg.data[2].toDouble();
            var lat2 = msg.data[3].toDouble();
            var lon2 = msg.data[4].toDouble();

            var top_left = new Toybox.Position.Location(
                {
                :latitude => lat1,
                :longitude => lon1,
                :format => :degrees
                }
            );

            var bottom_right = new Toybox.Position.Location(
                {
                :latitude => lat2,
                :longitude => lon2,
                :format => :degrees
                }
            );

            view.setMapVisibleArea(top_left, bottom_right);        

        } else if (msg.data[0].equals("vector")){
            var uid = msg.data[1];
            view.drawVector(uid);

        } else if (msg.data[0].equals("remove")){
            view.removeMarker(msg.data[1]);

        } else if (msg.data[0].equals("route")){
            view.drawRoute(msg.data);

        }

        // TODO: Add option to add gpx

        // TODO: Add option to draw polylines
       
    }

}