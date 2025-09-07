import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Position;
using Toybox.WatchUi as WatchUi;
using Toybox.Graphics as Graphics;
using Toybox.System as System;
using Toybox.Time as Time;

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
        // Load resources once
        digit_0 = Rez.Drawables.digit_0;
        digit_1 = Rez.Drawables.digit_1;
        digit_2 = Rez.Drawables.digit_2;
        digit_3 = Rez.Drawables.digit_3;
        digit_4 = Rez.Drawables.digit_4;
        digit_5 = Rez.Drawables.digit_5;
        digit_6 = Rez.Drawables.digit_6;
        digit_7 = Rez.Drawables.digit_7;
        digit_8 = Rez.Drawables.digit_8;
        digit_9 = Rez.Drawables.digit_9;
        digit_colon = Rez.Drawables.digit_colon;

        // Build lookup table
        digits = {
            "0" => digit_0,
            "1" => digit_1,
            "2" => digit_2,
            "3" => digit_3,
            "4" => digit_4,
            "5" => digit_5,
            "6" => digit_6,
            "7" => digit_7,
            "8" => digit_8,
            "9" => digit_9,
            ":" => digit_colon
        };
    }

   function onUpdate(dc as Dc) as Void {
    dc.clear();
    // draw flower first
    drawFlower(dc);

    // draw battery
    drawBattery(dc);

    drawTime(dc);

    // get time
    var clockTime = System.getClockTime();
    var hour = clockTime.hour;
    var minute = clockTime.min;
      var clockTimeText = clockTime.hour%12;
    if (clockTimeText == 0) {
        clockTimeText = 12; // 12-hour format
    }
    var timeString = Lang.format("$1$:$2$", 
        [clockTimeText, clockTime.min.format("%02d")]);

    // draw bitmap time
    drawBitmapTime(dc, timeString);

    // sun/moon
    var currentSec = hour*3600 + minute*60 + clockTime.sec;
    var sunriseSec = 6*3600;
    var sunsetSec = 18*3600;
    var centerX = dc.getWidth()/2;
    var centerY = 20;
    var radius  = 40;

    if (currentSec >= sunriseSec && currentSec <= sunsetSec) {
        drawCelestial(dc, centerX, centerY, radius, sunAngle(currentSec, sunriseSec, sunsetSec), true);
    } else {
        drawCelestial(dc, centerX, centerY, radius, moonAngle(currentSec, sunriseSec, sunsetSec), false);
    }

    

}


// Just store resource IDs — do NOT try to make BufferedBitmap
    var digit_0 as Toybox.Lang.ResourceId?;
    var digit_1 as Toybox.Lang.ResourceId?;
    var digit_2 as Toybox.Lang.ResourceId?;
    var digit_3 as Toybox.Lang.ResourceId?;
    var digit_4 as Toybox.Lang.ResourceId?;
    var digit_5 as Toybox.Lang.ResourceId?;
    var digit_6 as Toybox.Lang.ResourceId?;
    var digit_7 as Toybox.Lang.ResourceId?;
    var digit_8 as Toybox.Lang.ResourceId?;
    var digit_9 as Toybox.Lang.ResourceId?;
    var digit_colon as Toybox.Lang.ResourceId?;

    // Lookup table
    var digits;


    function drawBitmapTime(dc as Graphics.Dc, timeStr as String) {
    var screenW = dc.getWidth();
    var screenH = dc.getHeight();

    var totalWidth = 0;
    var digitHeight = 0;

    // calculate total width
    for (var i = 0; i < timeStr.length(); i++) {
        var ch = timeStr.substring(i,i+1);
        if (digits.hasKey(ch) && digits[ch] != null) {
            var bmp = WatchUi.loadResource(digits[ch]);
            totalWidth += bmp.getWidth();
            digitHeight = bmp.getHeight();
        }
    }

    var startX = (screenW - totalWidth) / 2;
    var y = 90; // fixed Y coordinate
    var curX = startX;

    // draw digits
    for (var i = 0; i < timeStr.length(); i++) {
        var ch = timeStr.substring(i,i+1);
        if (digits.hasKey(ch) && digits[ch] != null) {
            var bmp = WatchUi.loadResource(digits[ch]);
            dc.drawBitmap(curX, y, bmp);
            curX += bmp.getWidth();
        }
    }
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


    dc.drawText(105, 125, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER);
    }

    

  function getClockTimeResolution() {
    // update once per minute
    return 60;
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
