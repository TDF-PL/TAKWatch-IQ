import Toybox.WatchUi;
import Toybox.System;
import Toybox.Communications;
import Toybox.Position;
import Toybox.Application;
import Toybox.ActivityRecording;
import Toybox.Time;
import Toybox.Time.Gregorian;

class TAKDataDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
		WatchUi.BehaviorDelegate.initialize();

	}

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onPreviousPage() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onNextPage() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

class TAKMapDelegate extends WatchUi.BehaviorDelegate 
{
	var view;
	var diff = 0.005;
    var selPressTS = null;
    var selPressCount = 0;
    var backPressTS = null;
    var backPressCount = 0;

	function initialize(pView) {
		WatchUi.BehaviorDelegate.initialize();
		view = pView;
	}

    function onNextPage() {
        var dataView = new TAKDataView();
        WatchUi.pushView(dataView, new TAKDataDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onPreviousPage() {
        var dataView = new TAKDataView();
        WatchUi.pushView(dataView, new TAKDataDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    // Alert
    function onSelect() {
        view.clear();

        if (selPressTS != null) {
            var delta = Time.now().value() - selPressTS;
            if (delta <= 1) {
                selPressCount++;
            } else {
                selPressCount = 0;
            }
        }

        selPressTS = Time.now().value();

        if (selPressCount >= 5) {
            Application.getApp().sendMessageToApp(["alert"]);
            selPressCount = 0;
        }

        return true;
    }

    // Add menu
    function onMenu() {
        var customMenu = new WatchUi.Menu2({:title=>"Options"});
        customMenu.addItem(new WatchUi.MenuItem("Move/Zoom", null, :movezoom, null));
        customMenu.addItem(new WatchUi.MenuItem("Chat", null, :chat, null));
        customMenu.addItem(new WatchUi.MenuItem("Markers", null, :markers, null));
        var recLabel = "Stop recording";
        if (view.session == null) {
            recLabel = "Record";
        }
        customMenu.addItem(new WatchUi.MenuItem(recLabel, null, :record, null));
        customMenu.addItem(new WatchUi.MenuItem("Refresh", null, :refresh, null));
        customMenu.addItem(new WatchUi.MenuItem("Settings", null, :settings, null));
        WatchUi.pushView(customMenu, new $.OptionsMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() {
        if (view.getMapMode() == WatchUi.MAP_MODE_BROWSE) {
            view.setMapMode(WatchUi.MAP_MODE_PREVIEW);
            return true;
        }

        var customMenu = new WatchUi.Menu2({:title=>"Exit?"});
        customMenu.addItem(new WatchUi.MenuItem("No", null, :no, null));
        customMenu.addItem(new WatchUi.MenuItem("Yes", null, :yes, null));
        WatchUi.pushView(customMenu, new $.ExitMenuDelegate(), WatchUi.SLIDE_UP);

        if (backPressTS != null) {
            var delta = Time.now().value() - backPressTS;
            if (delta <= 1) {
                backPressCount++;
            } else {
                backPressCount = 0;
            }
        }

        backPressTS = Time.now().value();

        if (backPressCount >= 5) {
            Application.getApp().sendMessageToApp(["wipe"]);
            backPressCount = 0;
        }

        return true;
    }

}

class ExitMenuDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :no) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :yes) {
            System.exit();
        } 

        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class OptionsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;
    public function initialize(pView) {
        Menu2InputDelegate.initialize();
        view = pView;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :markers) {
            showMarkersMenu();
        } else if (id == :settings) {
            showSettingsMenu();
        } else if (id == :refresh) {
            Application.getApp().sync();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }else if (id == :chat) {
            showChatMenu();
        } else if (id == :movezoom) {
            view.setMapMode(WatchUi.MAP_MODE_BROWSE);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :record) {
            if (view.session == null) {
                var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
                var dateString = Lang.format(
                    "$1$-$2$-$3$@$4$:$5$",
                    [
                        today.day,
                        today.month,
                        today.year,
                        today.hour,
                        today.min
                    ]
                );
                view.session = ActivityRecording.createSession({:sport=>Activity.SPORT_GENERIC, :subsport=>Activity.SUB_SPORT_TRACK_ME, :name=>"TW " + dateString});
                view.session.start(); 
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                WatchUi.pushView(new TAKMsgView("Recording track.", false), new TAKDataDelegate(), WatchUi.SLIDE_UP);
            } else {
                view.session.stop();
                view.session.save();
                view.session = null; 
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                WatchUi.pushView(new TAKMsgView("Track saved.", false), new TAKDataDelegate(), WatchUi.SLIDE_UP);
            }
            
        }

        WatchUi.requestUpdate();
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    private function showChatMenu() {
        WatchUi.pushView(new $.Rez.Menus.MessageMenu(), new $.MessageDelegate(), WatchUi.SLIDE_UP);
    }

    private function showMarkersMenu() {
        var customMenu = new WatchUi.Menu2({:title=>"Select marker"});
     
        for (var i = 0; i < view.markers.size(); i++ ) {
            var marker = view.markers.values()[i];
            var uid = view.markers.keys()[i];           
            customMenu.addItem(new WatchUi.MenuItem(marker.getLabel(), null, uid, null));
        }
                
        WatchUi.pushView(customMenu, new $.MarkerMenuDelegate(view), WatchUi.SLIDE_UP);
    }

    private function showSettingsMenu() {
        var version = WatchUi.loadResource(Rez.Strings.version);
        var customMenu = new WatchUi.CheckboxMenu({:title=>"Settings (v" + version + ")"});
        customMenu.addItem(new WatchUi.CheckboxMenuItem("Send heartrate", null, :sendhr, Properties.getValue("sendhr"), null));  
        WatchUi.pushView(customMenu, new $.SettingsMenuDelegate(view), WatchUi.SLIDE_UP);
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;
    public function initialize(pView) {
        Menu2InputDelegate.initialize();
        view = pView;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :sendhr) {
            Properties.setValue("sendhr", !Properties.getValue("sendhr"));
            Application.getApp().toggleHRSensor();
        }
    }
}

class MarkerMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;
    public function initialize(pView) {
        Menu2InputDelegate.initialize();
        view = pView;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        showMarkersMenu(id);
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    private function showMarkersMenu(id) {
        var customMenu = new WatchUi.Menu2({:title=>"Select action"});
        customMenu.addItem(new WatchUi.MenuItem("Navigate", null, :vector, null));
        // Seems that setMapViewArea is not working as expected, let's comment this out for now
        //customMenu.addItem(new WatchUi.MenuItem("Show", null, :show, null));
        customMenu.addItem(new WatchUi.MenuItem("Save on watch", null, :save, null));
                
        WatchUi.pushView(customMenu, new $.MarkerDelegate(view, id), WatchUi.SLIDE_UP);
    }
}

class MarkerDelegate extends WatchUi.Menu2InputDelegate {
    var view;
    var uid;
    public function initialize(pView, pid) {
        Menu2InputDelegate.initialize();
        view = pView;
        uid = pid;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);

        if (id == :vector) {
            var posInfo =  Position.getInfo();
            if ( posInfo.accuracy > 2 ) {
                view.drawVector(uid);
            } else {
                WatchUi.pushView(new TAKMsgView("No GPS Lock.", true), new TAKDataDelegate(), WatchUi.SLIDE_UP);
            }
        } else if (id == :save) {
            var marker = view.markers.get(uid);
            Toybox.PersistedContent.saveWaypoint(marker.getLocation(), marker.getLabel());
        } else if (id == :show) {
            view.showMarker(uid);
        }

    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

}


class MessageDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var label = item.getLabel();
        sendMessage(label);      
        WatchUi.popView(WatchUi.SLIDE_DOWN);  
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    public function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function sendMessage(m) {
        Application.getApp().sendMessageToApp(["message", m]);
    }

}


