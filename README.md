#Islam Prayer times for Rainlendar

##Summary
Rainlendar is a super multiplatform calender for desktop pcs and this script added Islamic prayer times events.


##Setup
* Disable rainleander2 autostart function ( options->general )
* Set new path, probably pointing to Dropbox folder, to ics file in rainleander2 optins ( options->Calendars-><calendar>->format iCalendar->file name )
* Edit program path and ics path( same path as in previous point ) in rainlendar2.vbs:

```
    program = "C:\Program Files\Rainlendar2\Rainlendar2.exe"
    ics = "C:\Users\kubenstein\Dropbox\default.ics"
```

* Put rainlendar2.vbs file in your autostart folder

##Supported systems
* Windows ( tested on winXP, win7 )


##Source
Core vbs code was taken from:

http://www.rainlendar.net/cms/index.php?option=com_kunena&Itemid=42&func=view&catid=3&id=11916
