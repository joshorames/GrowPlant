import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Position;

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

    function drawCelestial(dc as Graphics.Dc, centerX as Number, centerY as Number, radius as Number, angle as Number, isSun as Boolean) as Void {
    var x = (centerX + radius * Math.cos(angle)).toNumber();
    var y = (centerY - radius * Math.sin(angle)).toNumber(); // minus so semicircle is upward
    dc.setColor(isSun ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.fillCircle(x, y, 5);
    }

    function sunAngle(currentSec as Number, sunriseSec as Number, sunsetSec as Number) as Number {
        if (currentSec < sunriseSec) {
            return (-Math.PI/2).toNumber();
        }      // before sunrise, left horizon
        if (currentSec > sunsetSec) {
            return (Math.PI/2).toNumber(); 
        }       // after sunset, right horizon
        var ratio = (currentSec - sunriseSec) / (sunsetSec - sunriseSec); // 0..1
        return (-Math.PI/2 + ratio * Math.PI).toNumber();    // maps to -90°..+90°
    }

    function moonAngle(currentSec as Number, sunriseSec as Number, sunsetSec as Number) as Number {
        var nightStart = sunsetSec;
        var nightEnd   = sunriseSec + 86400; // wrap past midnight
        var sec = (currentSec >= sunsetSec) ? currentSec : currentSec + 86400;
        var ratio = (sec - nightStart) / (nightEnd - nightStart); // 0..1
        return (-Math.PI/2 + ratio * Math.PI).toNumber();         // maps to -90°..+90° for night
    }

    function drawFlower(dc as Dc) as Void {
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
    }
    function drawBattery(dc as Dc) as Void {
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
    }

    // Load your resources here
    function drawTime(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    // --- Draw big readable time ---
    var clockTime = System.getClockTime();
    var clockTimeText = clockTime.hour%12;
    if (clockTimeText == 0) {
        clockTimeText = 12; // 12-hour format
    }
    var timeString = Lang.format("$1$:$2$ $3$", 
        [clockTimeText, clockTime.min.format("%02d"), clockTime.hour<12 ? "AM" : "PM"]);

    var cx = dc.getWidth() / 2;
    var cy = 90; // vertical center
    var font = Graphics.FONT_LARGE;

    // Auto-scale width based on digits (fake scaling)
    // Draw each digit slightly offset horizontally and vertically
    var offsets = [-1, -1, 0, 1, 1]; // wider spacing for boldness
    for (var i = 0; i < offsets.size(); i += 1) {
    var dx = offsets[i];
    for (var j = 0; j < offsets.size(); j += 1) {
        var dy = offsets[j];
        if (!(dx == 0 && dy == 0)) {
            dc.drawText(cx + dx, cy + dy, font, timeString, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

     // Draw main crisp text on top
    dc.drawText(cx, cy, font, timeString, Graphics.TEXT_JUSTIFY_CENTER);
    // Defensive check: day_of_week can be 0–6, month 1–12
    // ===== DATE =====
    var now = Time.now(); // "Moment" object
    var dateInfo = Gregorian.info(now, Time.FORMAT_SHORT);

    var weekdays = ["?", "Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
    var months   = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

    var weekdayName = (dateInfo.day_of_week >= 1 && dateInfo.day_of_week <= 7) 
        ? weekdays[dateInfo.day_of_week] 
        : "?";

    var monthName = (dateInfo.month >= 1 && dateInfo.month <= 12) 
        ? months[dateInfo.month-1] 
        : "?";

    var dateString = Lang.format("$1$, $2$ $3$", [
        weekdayName,
        monthName,
        dateInfo.day
    ]);


    dc.drawText(cx, cy + 30, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER);
    }}

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
    drawFlower(dc);
    drawBattery(dc);
    drawTime(dc);
    

var clockTime = System.getClockTime();

   

    
        // --- Sun & Moon ---

        var currentSec = clockTime.hour*3600 + clockTime.min*60 + clockTime.sec;
        var sunriseSec = 6*3600;   // Placeholder 6:00 AM
        var sunsetSec  = 18*3600;  // Placeholder 6:00 PM

        var centerX = dc.getWidth()/2;
        var centerY = 20;
        var radius  = 40;

        // Day: sun
        if (currentSec >= sunriseSec && currentSec <= sunsetSec) {
            drawCelestial(dc, centerX, centerY, radius, sunAngle(currentSec, sunriseSec, sunsetSec), true);
        }

        // Night: moon
        if (currentSec < sunriseSec || currentSec > sunsetSec) {
            drawCelestial(dc, centerX, centerY, radius, moonAngle(currentSec, sunriseSec, sunsetSec), false);
        }
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
