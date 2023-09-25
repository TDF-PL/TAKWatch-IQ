import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Communications;
import Toybox.System;

class TAKMsgView extends WatchUi.View {
    var _msg;
    var _error;
    var cnt = 5;
    var timer;

    function initialize(msg, error) {
        WatchUi.View.initialize();
        _msg = msg;
        _error = error;
        if (error) {
            cnt = 10;
        }
        timer = new Timer.Timer();
        timer.start(self.method(:onTimer), 1000, true);
    }

    function onHide(){
        if (timer != null) {
            timer.stop();
            timer = null;
        }
    }

    function onTimer() as Void{       
        if (cnt == 0) 
        {
            if (timer != null) {
                timer.stop();
                timer = null;
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        WatchUi.requestUpdate();
        cnt--;
    }


    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        var screenHeight = System.getDeviceSettings().screenHeight;
        var screenWidth = System.getDeviceSettings().screenWidth;
        if (_error) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT); 
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT); 
        }

        dc.drawText(screenWidth / 2, screenHeight / 2 ,  Graphics.FONT_MEDIUM, _msg, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(screenWidth / 2, screenHeight-40 ,  Graphics.FONT_MEDIUM, cnt.toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }

} 