import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class GrowPlantView extends WatchUi.WatchFace {
    var flowerStage1 as Graphics.Bitmap;
    var flowerStage2 as Graphics.Bitmap;
    var flowerStage3 as Graphics.Bitmap;
    var flowerStage4 as Graphics.Bitmap;
    var flowerStage5 as Graphics.Bitmap;
    var flowerStage6 as Graphics.Bitmap;

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
    if (percent < 0.17) {
        setLayout(Rez.Layouts.FlowerStage1Layout(dc));
    } else if (percent < 0.34) {
        setLayout(Rez.Layouts.FlowerStage2Layout(dc));
    } else if (percent < 0.51) {
        setLayout(Rez.Layouts.FlowerStage3Layout(dc));
    } else if (percent < 0.68) {
        setLayout(Rez.Layouts.FlowerStage4Layout(dc));
    } else if (percent < 0.85) {
        setLayout(Rez.Layouts.FlowerStage5Layout(dc));
    } else {
        setLayout(Rez.Layouts.FlowerStage6Layout(dc));
    }

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
// Battery bar at bottom
var batteryPct = System.getSystemStats().battery; // 0-100
var barWidth = dc.getWidth() - 100; // leave 10px padding
var barHeight = 6;
var bx = 50;               
var by = dc.getHeight() - barHeight -25; // 5px padding from bottom
var fillWidth = Math.floor(barWidth * (batteryPct / 100.0));

dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);

// Draw outline (top, bottom, left, right)
dc.drawLine(bx, by, bx + barWidth, by);                   // top
dc.drawLine(bx, by + barHeight, bx + barWidth, by + barHeight); // bottom
dc.drawLine(bx, by, bx, by + barHeight);                 // left
dc.drawLine(bx + barWidth, by, bx + barWidth, by + barHeight); // right

// Fill battery bar with horizontal lines
if (fillWidth > 2) { // avoid negative width
    for (var fy = by + 1; fy < by + barHeight; fy += 1) {
        dc.drawLine(bx + 1, fy, bx + fillWidth - 1, fy);
    }
}
  dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    // --- Draw big readable time ---
    var clockTime = System.getClockTime();
    var timeString = Lang.format("$1$:$2$", 
        [clockTime.hour, clockTime.min.format("%02d")]);

    var cx = dc.getWidth() / 2;
    var cy = 90; // vertical center
    var font = Graphics.FONT_LARGE;

    // Auto-scale width based on digits (fake scaling)
    // Draw each digit slightly offset horizontally and vertically
    var offsets = [-2, -1, 0, 1, 2]; // wider spacing for boldness
    for (var i = 0; i < offsets.size(); i += 1) {
    var dx = offsets[i];
    for (var j = 0; j < offsets.size(); j += 1) {
        var dy = offsets[j];
        if (!(dx == 0 && dy == 0)) {
            dc.drawText(cx + dx, cy + dy, font, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}


    // Draw main crisp text on top
    dc.drawText(cx, cy, font, timeString, Graphics.TEXT_JUSTIFY_CENTER);


    
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
