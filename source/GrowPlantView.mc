import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class GrowPlantView extends WatchUi.WatchFace {
    var flowerStage1 as Graphics.Bitmap;
    var flowerStage2 as Graphics.Bitmap;
    var flowerStage3 as Graphics.Bitmap;
    var flowerStage4 as Graphics.Bitmap;

    function initialize() {
        WatchFace.initialize();

    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.FlowerStage1Layout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
    var steps = ActivityMonitor.getInfo().steps;
    var goal  = ActivityMonitor.getInfo().stepGoal;
    var percent = (goal > 0) ? steps * 1.0 / goal : 0.0;

    // Switch layout based on step progress
    if (percent < 0.25) {
        setLayout(Rez.Layouts.FlowerStage1Layout(dc));
    } else if (percent < 0.50) {
        setLayout(Rez.Layouts.FlowerStage2Layout(dc));
    } else if (percent < 0.75) {
        setLayout(Rez.Layouts.FlowerStage3Layout(dc));
    } else {
        setLayout(Rez.Layouts.FlowerStage4Layout(dc));
    }

    // === BATTERY ===
        var charge = System.getSystemStats().battery;
        var rounded = Math.round(charge);
        var batteryString = rounded.toString() + "%";

        var batteryView = View.findDrawableById("BatteryLabel") as Text;
        if (batteryView != null) {
            batteryView.setText(batteryString);
        }


    // Update time label
    var clockTime = System.getClockTime();
    var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
    var timeView = View.findDrawableById("TimeLabel") as Text;
    timeView.setText(timeString);

     // Update step label
    //var stepString = Lang.format("$1$ / $2$ steps", [steps, goal]);
    var stepView = View.findDrawableById("StepLabel") as Text;
    // Calculate percent
        var stepPercent = (steps * 100.0 / goal).toNumber();
        if (stepPercent > 100) {
            stepPercent = 100; // cap at 100%
        }
        // Round to nearest whole number
        var percentRounded = Math.round(stepPercent);
    stepView.setText(percentRounded.toString()+"% to goal");

    View.onUpdate(dc);
}



    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
