using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Position;
using Toybox.Weather;
using Toybox.ActivityMonitor;

class GrowPlantView extends WatchUi.WatchFace {

    // Cached resources
    var digits;
    var weatherIcons;

    var _sunriseSec = 6 * 3600;
    var _sunsetSec  = 18 * 3600;
    var _sunDateKey = -1;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) {
        // Load digit resources
        digits = {
            "0" => Rez.Drawables.digit_0,
            "1" => Rez.Drawables.digit_1,
            "2" => Rez.Drawables.digit_2,
            "3" => Rez.Drawables.digit_3,
            "4" => Rez.Drawables.digit_4,
            "5" => Rez.Drawables.digit_5,
            "6" => Rez.Drawables.digit_6,
            "7" => Rez.Drawables.digit_7,
            "8" => Rez.Drawables.digit_8,
            "9" => Rez.Drawables.digit_9,
            ":" => Rez.Drawables.digit_colon
        };

        // Weather icons
        weatherIcons = {
            "CLEAR"        => null,
            "MOSTLY_CLEAR" => Rez.Drawables.weather_mostly_clear,
            "PARTLY_CLEAR" => Rez.Drawables.weather_partly,
            "CLOUDY"       => Rez.Drawables.weather_cloudy,
            "RAIN"         => Rez.Drawables.weather_rain,
            "SNOW"         => Rez.Drawables.weather_snow,
            "STORM"        => Rez.Drawables.weather_storm
        };
    }

    function onUpdate(dc as Graphics.Dc) {
        dc.clear();

        // Draw flower stage based on steps
        drawFlower(dc);

        // Draw battery
        drawBattery(dc);

        // Draw time
        drawTime(dc);

        // Draw bitmap time
        var clockTime = System.getClockTime();
        var hour12 = clockTime.hour % 12;
        if (hour12 == 0) {
            hour12 = 12;
        }
        var timeString = Lang.format("$1$:$2$", [hour12, clockTime.min.format("%02d")]);
        drawBitmapTime(dc, timeString);

        // Draw sun/moon
        updateSunTimes();
        var currentSec = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
        var centerX = dc.getWidth()/2;
        var centerY = 5;
        var radius  = 40;

        if (currentSec >= _sunriseSec && currentSec <= _sunsetSec) {
            drawCelestial(dc, centerX, centerY, radius, sunAngle(currentSec, _sunriseSec, _sunsetSec), true);
        } else {
            drawCelestial(dc, centerX, centerY, radius, moonAngle(currentSec, _sunriseSec, _sunsetSec), false);
        }

        // Draw weather
        drawWeather(dc, 110, 18);
    }

    function updateSunTimes() {
        var nowMoment = Time.now();
        var nowInfo = Gregorian.info(nowMoment, Time.FORMAT_SHORT);
        var todayKey = nowInfo.year * 10000 + nowInfo.month * 100 + nowInfo.day;

        if (todayKey == _sunDateKey) {
            return; // already computed
        }

        var loc = null;
        var wc = Weather.getCurrentConditions();
        if (wc != null && wc.observationLocationPosition != null) {
            loc = wc.observationLocationPosition;
        } else {
            var act = Activity.getActivityInfo();
            if (act != null && act.currentLocation != null) {
                loc = act.currentLocation;
            } else {
                var pinfo = Position.getInfo();
                if (pinfo != null && pinfo.position != null) {
                    loc = pinfo.position;
                }
            }
        }

        if (loc != null) {
            var sunRiseMoment = Weather.getSunrise(loc, nowMoment);
            var sunSetMoment  = Weather.getSunset(loc, nowMoment);
            if (sunRiseMoment != null) {
                var rinfo = Gregorian.info(sunRiseMoment, Time.FORMAT_SHORT);
                _sunriseSec = rinfo.hour * 3600 + rinfo.min * 60 + rinfo.sec;
            } else {
                _sunriseSec = 6*3600;
            }
            if (sunSetMoment != null) {
                var sinfo = Gregorian.info(sunSetMoment, Time.FORMAT_SHORT);
                _sunsetSec = sinfo.hour*3600 + sinfo.min*60 + sinfo.sec;
            } else {
                _sunsetSec = 18*3600;
            }
        } else {
            _sunriseSec = 6*3600;
            _sunsetSec = 18*3600;
        }

        _sunDateKey = todayKey;
    }

    function drawBitmapTime(dc as Graphics.Dc, timeStr) {
        var screenW = dc.getWidth();
        var totalWidth = 0;

        for (var i = 0; i < timeStr.length(); i++) {
            var ch = timeStr.substring(i,i+1);
            if (digits.hasKey(ch) && digits[ch] != null) {
                var bmp = WatchUi.loadResource(digits[ch]);
                totalWidth += bmp.getWidth();
            }
        }

        var startX = (screenW - totalWidth)/2;
        var y = 90;
        var curX = startX;

        for (var i = 0; i < timeStr.length(); i++) {
            var ch = timeStr.substring(i,i+1);
            if (digits.hasKey(ch) && digits[ch] != null) {
                var bmp = WatchUi.loadResource(digits[ch]);
                dc.drawBitmap(curX, y, bmp);
                curX += bmp.getWidth();
            }
        }
    }

    function drawWeather(dc as Graphics.Dc, x, y) {
        var wc = Weather.getCurrentConditions();
        if (wc == null) {return;}

        var cond = null;
        try {
            cond = wc.condition;
        } catch (e) {
            cond = null;
        }

        var iconRes = weatherIconForCondition(cond);
        if (iconRes != null) {
            var bmp = WatchUi.loadResource(iconRes);
            if (bmp != null) {
                dc.drawBitmap(x, y, bmp);
            }
        }
    }

    function weatherIconForCondition(cond) as Toybox.Lang.ResourceId? {
    if (cond == null) {return null;}

    switch (cond) {
        case Weather.CONDITION_CLEAR:
            return weatherIcons["CLEAR"];
        case Weather.CONDITION_PARTLY_CLOUDY:
            return weatherIcons["CLOUDY"];
        case Weather.CONDITION_MOSTLY_CLOUDY:
            return weatherIcons["CLOUDY"];
        case Weather.CONDITION_RAIN:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_SNOW:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_THUNDERSTORMS:
            return weatherIcons["STORM"];
        case Weather.CONDITION_WINTRY_MIX:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_SCATTERED_SHOWERS:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            return weatherIcons["STORM"];
        case Weather.CONDITION_LIGHT_RAIN:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_HEAVY_RAIN:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_LIGHT_SNOW:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_HEAVY_SNOW:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_LIGHT_RAIN_SNOW:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_HEAVY_RAIN_SNOW:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_CLOUDY:
            return weatherIcons["CLOUDY"];
        case Weather.CONDITION_RAIN_SNOW:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_PARTLY_CLEAR:
            return weatherIcons["CLOUDY"];
        case Weather.CONDITION_MOSTLY_CLEAR:
            return weatherIcons["CLEAR"];
        case Weather.CONDITION_LIGHT_SHOWERS:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_SHOWERS:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_HEAVY_SHOWERS:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_DRIZZLE:
            return weatherIcons["RAIN"];
        case Weather.CONDITION_TORNADO:
            return weatherIcons["STORM"];
        case Weather.CONDITION_FLURRIES:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_FREEZING_RAIN:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_SLEET:
            return weatherIcons["SNOW"];
        case Weather.CONDITION_ICE_SNOW:
            return weatherIcons["SNOW"];
        default:
            return null;
    }
    }

    function drawCelestial(dc as Graphics.Dc, centerX, centerY, radius, angle, isSun) {
        var x = (centerX + radius * Math.cos(angle)).toNumber();
        var y = (centerY - radius * Math.sin(angle)).toNumber();
        dc.setColor(isSun ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y, 5);
    }

    function sunAngle(currentSec, sunriseSec, sunsetSec) {
    if (currentSec < sunriseSec) {
        return (-Math.PI/2).toNumber();
    }
    if (currentSec > sunsetSec) {
        return (Math.PI/2).toNumber();
    }
    var ratio = (currentSec - sunriseSec) / (sunsetSec - sunriseSec);
    return (-Math.PI/2 + ratio * Math.PI).toNumber();
    }

    function moonAngle(currentSec, sunriseSec, sunsetSec) {
    var nightStart = sunsetSec;
    var nightEnd = sunriseSec + 86400;
    var sec = (currentSec >= sunsetSec) ? currentSec : currentSec + 86400;
    var ratio = (sec - nightStart) / (nightEnd - nightStart);
    return (-Math.PI/2 + ratio * Math.PI).toNumber();
    }

    function drawFlower(dc as Graphics.Dc) as Void {
    var info = ActivityMonitor.getInfo();
    var steps = info.steps;
    var goal = info.stepGoal;
    var percent = (goal > 0) ? steps * 1.0 / goal : 0.0;

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
    var stepView = View.findDrawableById("StepLabel") as WatchUi.Text;
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


    function drawBattery(dc as Graphics.Dc) {
        var batteryPct = System.getSystemStats().battery;
        var barWidth = dc.getWidth() - 100;
        var barHeight = 6;
        var bx = 50;
        var by = dc.getHeight() - barHeight - 25;
        var fillWidth = Math.floor(barWidth * batteryPct / 100.0);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        dc.drawLine(bx, by, bx+barWidth, by);
        dc.drawLine(bx, by+barHeight, bx+barWidth, by+barHeight);
        dc.drawLine(bx, by, bx, by+barHeight);
        dc.drawLine(bx+barWidth, by, bx+barWidth, by+barHeight);

        if (fillWidth > 2) {
            for (var fy = by+1; fy < by+barHeight; fy++) {
                dc.drawLine(bx+1, fy, bx+fillWidth-1, fy);
            }
        }

        dc.drawText(105, dc.getHeight() - barHeight - 18, Graphics.FONT_SYSTEM_XTINY, Math.round(batteryPct).toNumber().toString()+"%", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawTime(dc as Graphics.Dc) {
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_SHORT);

        var weekdays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
        var months   = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

        var weekdayName = (dateInfo.day_of_week >=1 && dateInfo.day_of_week <=7) ? weekdays[dateInfo.day_of_week - 1] : "?";
        var monthName   = (dateInfo.month >=1 && dateInfo.month <=12) ? months[dateInfo.month-1] : "?";

        var dateString = Lang.format("$1$, $2$ $3$", [weekdayName, monthName, dateInfo.day]);
        dc.drawText(105, 125, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function getClockTimeResolution() {
        return 60; // update once per minute
    }

    function onHide() {}
    function onEnterSleep() {}
    function onExitSleep() {}
}
