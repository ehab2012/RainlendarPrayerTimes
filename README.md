#Islam Prayer times for Rainlendar

##Summary
Rainlendar is a super multiplatform calender for desktop pcs and this script added Islamic prayer times events.
This script is a port from c code by PrayerTimes v.2006 Ahmed Amin Elsheshtawy http://www.islamware.com

##Setup
* edit PrayerTimes_RL.lua top values to adjust location, zone and fajir angle
```
-- Finland, Tampere
City_Longtude=23.75;
City_Latitude=61.5;
City_Zone=3;  -- 3 GMT
City_Fajir_Angle=12;  -- 12 , norm 18 or 19
City_Asir_Calculation = 1;  -- 1 Shafi or Omalqrah , 2 Henfy
CategoriesName = "PRAYER"    -- can be used to hide if needed

CONSOLEPRINT=nil; --- if set 1 printfs , nil RL will add the events
```
* copy the script to your Rainlendar scripts folder, my path is /usr/lib/rainlendar2/scripts for windows if it was installed under program files directory it is %PROGRAMFILES%\Rainlendars\scripts\
* you can exclude event PRAYER from the calendar view and keep in event list

##Testing
you can see todays prayer times from console

```
$lua PrayerTimes_RL.lua

2014-09-06  Fajer 04:40:00
2014-09-06 Shrooq 06:25:00
2014-09-06  Zohar 13:25:00
2014-09-06   Aser 16:60:00
2014-09-06 Magreb 20:24:00
2014-09-06   Isha 21:54:00

```
##TODO
* improve lua script code.
* fix isha time, currently it is set an addition of 1.5 hours to magrib time