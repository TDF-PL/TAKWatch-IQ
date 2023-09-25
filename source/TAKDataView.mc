import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Communications;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;

class TAKDataView extends WatchUi.View {
   var timer;

    function initialize() {
        View.initialize();
        timer = new Timer.Timer();
        timer.start(self.method(:onTimer), 200, true);
    }

    function onHide(){
        timer.stop();
        timer = null;
    }

    function onTimer() as Void{
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        var screenHeight = System.getDeviceSettings().screenHeight;
        var screenWidth = System.getDeviceSettings().screenWidth;
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT); 

        var stats = System.getSystemStats();
        if (stats != null) {
            var pwr = stats.battery;
            var days = stats.batteryInDays;
            var batt = Lang.format( "BAT $1$% ($2$d)", [ pwr.format( "%2d" ), days.format( "%.0d" ) ] );
            dc.drawText(screenWidth / 2, 80 ,  Graphics.FONT_TINY, batt, Graphics.TEXT_JUSTIFY_CENTER);
        }


        // Heading
        if (Sensor.getInfo().heading != null ){
            var heading = Sensor.getInfo().heading;
            heading = Math.toDegrees(heading);

            if (heading < 0) {
                heading = 360 + heading;
            }

            var headStr = Lang.format("HDG $1$" , [ heading.format("%03d") ]);
            dc.drawText(screenWidth / 2, 40 ,  Graphics.FONT_MEDIUM, headStr, Graphics.TEXT_JUSTIFY_CENTER);
        }
  
        // Time
        var today = Gregorian.info(Time.now(), Time.FORMAT_LONG);
            var dateString = Lang.format(
                "$1$:$2$",
                [
                    today.hour.format("%02d"),
                    today.min.format("%02d")
                ]
            );       

        dc.drawText(screenWidth / 2, screenHeight - 80 ,  Graphics.FONT_MEDIUM, dateString, Graphics.TEXT_JUSTIFY_CENTER);
      
        var position = null;
        var posInfo =  Position.getInfo();
        if ( posInfo.accuracy > 2 ) {
            position = posInfo.position.toGeoString(Position.GEO_MGRS);
        } else {
            position = "NO GPS";
        }

        // MGRS
        dc.drawText(screenWidth / 2, screenHeight / 2 ,  Graphics.FONT_TINY, position, Graphics.TEXT_JUSTIFY_CENTER);  
   
    }

}