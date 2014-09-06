-- Ehab Aboudaya ehab.abbyday@gmail.com
-- Rainlendar PrayerTimes v.1.0
-- Lua script to add Islamic prayer times to Rainlendar event list
-- ported from Library Name - PrayerTimes v.2006 Ahmed Amin Elsheshtawy http://www.islamware.com

-- libya, Tripoli
--City_Longtude=13.1800;
--City_Latitude=32.8925;

-- Finland, Tampere
City_Longtude=23.75;
City_Latitude=61.5;

City_Zone=3;  -- 3 GMT

City_Fajir_Angle=12;  -- 12 , norm 18 or 19
City_Asir_Calculation = 1;  -- 1 Shafi or Omalqrah , 2 Henfy
CategoriesName = "PRAYER"    -- can be used to hide if needed
CONSOLEPRINT=nil; --- if set 1 printfs , nil RL will add the events

-- TODO isha is +1.5 needs fixing
-------------------------------------------------------------------------------
DToR=(math.pi / 180.0);
RToH=(12.0 / math.pi);

function printf(...)
	io.write(string.format(...))
end

function Prayer_CreateEvent(name,yg,mg,dg,h,m,s)
	local strEvent = "BEGIN:VEVENT\n"
	strEvent = strEvent .. string.format("UID:{23ee3ea0-111-%02d-%02d-%02d}", dg,h,m,s) .. "\n"
	strEvent = strEvent .. "SUMMARY:" .. name .."\n"
	strEvent = strEvent .. "DESCRIPTION:\n"
	strEvent = strEvent .. "DTSTART;VALUE=DATE:" .. string.format("%04d%02d%02dT%02d%02d%02d", yg,mg,dg,h,m,s) .. "\n"
	strEvent = strEvent .. "TRANSP:TRANSPARENT\n"
	strEvent = strEvent .. "CATEGORIES:[" .. CategoriesName .. "]\n"
	strEvent = strEvent .. "END:VEVENT"
	Rainlendar_CreateComponent(strEvent)
end

function GTJD(Y,M,D) -- return JulianDate date from geo
	local jd=0;

	if ((Y > 1582) or ((Y == 582) and (M > 10))
		or ((Y == 1582) and (M == 10) and (D>14))) then
		jd = math.modf((1461 * (Y + 4800 + math.modf((M - 14)/12)))/4) +
				math.modf((367 * (M - 2 - 12 * (math.modf((M - 14)/12))))/12) -
				math.modf((3 * (math.modf((Y + 4900 + math.modf((M - 14)/12))/100)))/4) + D - 32075;
	else
		jd = 367 * Y - math.modf((7 * (Y + 5001 + math.modf((M - 9)/7)))/4)
			+ math.modf((275 * M)/9) + D + 1729777;
	end;
	return jd;
end

-- Computation for the Sun
function atanxy(x,y)
    local argm;
	if(x==0) then 
		argm=0.5*math.pi
	else 
		argm=math.atan(y/x)
	end

   if (x>0 and y<0) then argm=2.0*math.pi+argm end;
   if(x<0) then argm=math.pi+argm end;
   return argm;
end

function EclipToEquator(lmdr, betar)
	--[[ Convert Ecliptic to Equatorial Coordinate p.40 No.27, Peter Duffett-Smith book
		input: lmdr,betar  in radians output: alph,dltr in radians ]]

	local eps=23.441884;  -- (in degrees) this changes with time
	local rad=DToR;--0.017453292;  -- =math.pi/180.0

	local epsr=eps*rad;  -- convert to radians
	local sdlt=math.sin(betar)*math.cos(epsr)+math.cos(betar)*math.sin(epsr)*math.sin(lmdr);
	local dltr=math.asin(sdlt);
	local y=math.sin(lmdr)*math.cos(epsr)-math.tan(betar)*math.sin(epsr);
	local x=math.cos(lmdr);
	local alph=atanxy(x,y);
	return alph, dltr
end

function RoutinR2(M,e)
	-- Routine R2: Calculate the value of E p.91, Peter Duffett-Smith book
	local dt=1;
	local Ec=M;
	local dE=0;
	while(math.abs(dt)>1e-9) do
		dt=Ec-e*math.sin(Ec)-M;
		dE=dt/(1-e*math.cos(Ec));
		Ec=Ec-dE;
	end
	return Ec;
end

function SunParamr( yg, mg,  dg, ObsLon, ObsLat, TimeZone)
	-- p.99 of the Peter Duffett-Smith book
	local RiseSetFlags=0;
	local JD=GTJD(yg,mg,dg);
	local T=(JD+ TimeZone/24.0 - 2451545.0) / 36525.0;
	local L=279.6966778+36000.76892*T+0.0003025*T*T;  -- in degrees
	while(L>360) do L=L-360 end;
	while(L<0) do L=L+360 end;
	L=L*DToR; -- math.pi/180.0;  -- radians

	local M=358.47583+35999.04975*T-0.00015*T*T-0.0000033*T*T*T;
	while(M>360) do M=M-360 end;
	while(M<0) do M=M+360 end;
	M=M*math.pi/180.0;

	local e=0.01675104-0.0000418*T-0.000000126*T*T;
	local Ec=23.452294-0.0130125*T-0.00000164*T*T+0.000000503*T*T*T;
	Ec=Ec*DToR;--math.pi/180.0;

	local y=math.tan(0.5*Ec);
	y=y*y;
	local ET=y*math.sin(2*L)-2*e*math.sin(M)+4*e*y*math.sin(M)*math.cos(2*L)-0.5*y*y*math.sin(4*L)-5*0.25*e*e*math.sin(2*M);
	local UT=ET*180.0/(15.0*math.pi);   -- from radians to hours

	Ec=RoutinR2(M,e);
	local tnv=math.sqrt((1+e)/(1-e))*math.tan(0.5*Ec);
	local v=2.0*math.atan(tnv);
	local tht=L+v-M;
	local RA,Decl=EclipToEquator(tht,0);

	local K=12-UT-TimeZone+ObsLon*12.0/math.pi;  -- (Noon)
	local Transit=K;

	--  Sunrise and Sunset
	local angl=(-0.833333)*DToR;  -- Meeus p.98
	local T1=(math.sin(angl)-math.sin(Decl)*math.sin(ObsLat));
	local T2=(math.cos(Decl)*math.cos(ObsLat));  -- p.38  Hour angle for the Sun
	local cH=T1/T2;
	if(cH>1)  then
		RiseSetFlags=16;
		cH=1;  --At this day and place the sun does not rise or set
	end
	local H=math.acos(cH);
	H=H*12.0/math.pi;
	local Rise=K-H;	-- Sunrise
	local Setting=K+H; -- SunSet
	return Rise,Transit, Setting, RA, Decl, RiseSetFlags,JD;
end

--[[ For international prayer times see Islamic Fiqah Council of the Muslim
	World League:  Saturday 12 Rajeb 1406H, concerning prayer times and fasting
	times for countries of high latitudes. This program is based on the above.
/*****************************************************************************/
/* Name:    PrayerTimes                                                         */
/* Type:    Procedure                                                        */
/* Purpose: Compute prayer times and sunrise                                 */
/* Arguments:                                                                */
/*   yg,mg,dg : Date in Greg                                                 */
/*   param[1]: Safety time  in hours should be 0.016383h                     */
/*   longtud,latud: param[1],[2] : The place longtude and latitude in radians*/
/*   HeightdifW : param[3]: The place western herizon height difference in meters */
/*   HeightdifE : param[4]: The place eastern herizon height difference in meters */
/*   Zonh :param[5]: The place zone time dif. from GMT  West neg and East pos*/
/*          in decimal hours                                                 */
/*  fjrangl: param[6]: The angle (radian) used to compute                    */
/*            Fajer prayer time (OmAlqrah  -19 deg.)                         */
/*  ashangl: param[7]: The angle (radian) used to compute Isha  prayer time  */
/*          ashangl=0 then use  (OmAlqrah: ash=SunSet+1.5h)                  */
/*  asr  : param[8]: The Henfy (asr=2) Shafi (asr=1, Omalqrah asr=1)         */
/*  param[9]: latude (radian) that should be used for places above -+65.5    */
/*            should be 45deg as suggested by Rabita                         */
/*   param[10]: The Isha fixed time from Sunset                              */
/*  Output:                                                                  */
/*  lst[]: lst[n], 1:Fajer 2:Sunrise 3:Zohar 4:Aser  5:Magreb  6:Ishe        */
/*                 7:Fajer using exact Rabita method for places >48          */
/*                 8:Ash   using exact Rabita method for places >48          */
/*                 9: Eid Prayer Time                                        */
/*          for places above 48 lst[1] and lst[6] use a modified version of  */
/*          Rabita method that tries to eliminate the discontinuity          */
/*         all in 24 decimal hours                                           */
/*         returns flag:0 if there are problems, flag:1 no problems          */
/*****************************************************************************/
 ]]
function PrayerTimes (yg,mg,dg, param)
	--[[ Main  variables:
	RA= Sun's right ascension
	Decl= Sun's declination
	H= Hour Angle for the Sun
	K= Noon time
	angl= The Sun altitude for the required time
	flagrs: sunrise sunset flags
		0:	no problem
		16: Sun always above horizon (at the ploes for some days in the year)
		32: Sun always below horizon ]]

	local flag=1;
	local problm=0;
	local SINd=0.0;
	local COSd=0.0;
	local act=0.0;
	local H=0.0;
	local angl=0.0;
	local K=0.0;
	local cH=0.0;
	local X=0.0;
	local MaxLat=0.0;
	local H0=0.0;
	local Night=0.0;
	local IshRt=0.0;
	local FajrRt=0.0;
	local HightCorWest=0.0;
	local HightCorEast=0.0;
	local IshFix=0.0;
	local FajrFix=0.0;
	local lst = {};

	-- Compute the Sun various Parameters
	local Rise,Transit, Setting, RA, Decl, flagrs,JD=
	SunParamr(yg,mg,dg,-param[2],param[3],-param[6]);
	-- Compute General Values
	SINd=math.sin(Decl)*math.sin(param[3]);
	COSd=math.cos(Decl)*math.cos(param[3]);
	-- Noon
	K=Transit;
	-- Compute the height correction
	HightCorWest=0;
	HightCorEast=0;

	if(flagrs==0 and math.abs(param[2])<0.79 and (param[4]~=0 or param[3]~=0))
	then
		-- height correction not used for problematic places above 45deg
		H0=0;
		H=0;
		angl=-0.83333*DToR;  
		-- standard value  angl=50min=0.8333deg for sunset and sunrise
		cH=(math.sin(angl)-SINd)/(COSd);
		H0=math.acos(cH);
		local EarthRadius=6378.14
		X=EarthRadius*1000.0;  -- meters
		angl=-0.83333*DToR+(0.5*math.pi-math.asin(X/(X+param[4])));
		cH=(math.sin(angl)-SINd)/(COSd);
		HightCorWest=math.acos(cH);
		HightCorWest=(H0-HightCorWest)*(RToH);
		angl=-0.83333*DToR+(0.5*math.pi-math.asin(X/(X+param[5])));
		cH=(math.sin(angl)-SINd)/(COSd);
		HightCorEast=math.acos(cH);
		HightCorEast=(H0-HightCorEast)*(RToH);
	end

	-- Modify Sunrise,Sunset and Transit for problematic places
	if(not (flagrs==0 and math.abs(Setting-Rise)>1 and math.abs(Setting-Rise)<23))
	then
		--[[ There are problems in computing sun(rise,set)  This is because of 
			places above -+65.5 at some days of the year Note param[9] 
			should be  45deg as suggested by Rabita --]]
		problm=1;
		if(param[3]<0) then
			MaxLat= -(math.abs(param[10]));
		else
			MaxLat= math.abs(param[10]);
		end
		-- Recompute the Sun various Parameters using the reference param[9]
		Rise,Transit, Setting, RA, Decl, flagrs,JD=
		SunParamr(yg,mg,dg,-param[2],MaxLat,-param[6]);
		K=Transit;  -- exact noon time
		-- ReCompute General Values for the new reference param[9]
		SINd=math.sin(Decl)*math.sin(MaxLat);
		COSd=math.cos(Decl)*math.cos(MaxLat);
	end

	if(K<0) then K=K+24; end;
	-- Sunrise - Height correction
	lst[2]=Rise-HightCorEast;
	-- Zohar time+extra time to make sure that the sun has moved from zaowal
	lst[3]=K+param[1];
	-- Magrib= SunSet + Height correction + Safety Time
	lst[5]=Setting+HightCorWest+param[1];

	-- Asr time: Henfy param[8]=2, Shafi param[8]=1, OmAlqrah asr=1
	if(problm~=0) then -- For places above 65deg
		act=param[9]+math.tan(math.abs(Decl-MaxLat));
	else -- no problem
		act=param[9]+math.tan(math.abs(Decl-param[3]));
		--[[ In the standard equations abs() is not used, 
			but it is required for -ve latitude  ]]
	end

	angl=math.atan(1.0/act);
	cH=(math.sin(angl)-SINd)/(COSd);
	if(math.abs(cH)>1.0) then
		H=3.5;
		flag=0; -- problem in compuing Asr
	else
		H=math.acos(cH);
		H=H*RToH;
	end;
	lst[4]=K+H+param[1];  --  Asr Time

	-- Fajr Time
	angl=-param[7];
	--[[ The value -19deg is used by OmAlqrah for Fajr, but it is not correct,
		   Astronomical twilight and Rabita use -18deg ]]
	cH=(math.sin(angl)-SINd)/(COSd);
	if(math.abs(param[3])<0.83776) then   --If latitude<48deg
		-- no problem
		H=math.acos(cH);
		H=H*RToH;  -- convert radians to hours
		lst[1]=K-(H+HightCorEast)+param[1];    -- Fajr time
		lst[7]=lst[1];
		-- Get fixed ratio, data depends on latitutde sign
	else
		  if(param[3]<0) then
			  IshFix,FajrFix=GetRatior(yg,12,21,param);
		  else
			  IshFix,FajrFix=GetRatior(yg,6,21,param);
		  end
		  -- A linear equation I have interoduced
		  if((math.abs(cH))>(0.45+1.3369*param[7])) then
			  -- The problem occurs for places above -+48 in the summer
			  Night=24-(Setting-Rise); -- Night Length
			  lst[1]=Rise-Night*FajrFix;  -- According to the general ratio rule
		  else
			  -- no problem
			  H=math.acos(cH);
			  H=H*RToH;  -- convert radians to hours
			  lst[1]=K-(H+HightCorEast)+param[1];    -- Fajr time
		  end
		  lst[7]=lst[1];
		  if(math.abs(cH)>1) then
			  -- The problem occurs for places above -+48 in the summer
			  IshRt,FajrRt=GetRatior(yg,mg,dg,param);
			  Night=24-(Setting-Rise); -- Night Length
			  lst[7]=Rise-Night*FajrRt; -- Accoording to Rabita Method
		  else
			  -- no problem
			  H=math.acos(cH);
			  H=H*RToH;  -- convert radians to hours
			  lst[7]=K-(H+HightCorEast)+param[1]; -- Fajr time
		  end
	end

	--   Isha prayer time
	if(param[8]~=0) then -- if Ish angle  not equal zero   -- TODO the isha is now 1.5 fix it
		angl=-param[8];
		cH=(math.sin(angl)-SINd)/(COSd);
		if(math.abs(param[3])<0.83776)  then  --If latitude<48deg
		  -- no problem
		H=math.acos(cH);
		H=H*RToH;  -- convert radians to hours
		lst[6]=K+(H+HightCorWest+param[1]);   -- Isha time, instead of  Sunset+1.5h
		lst[8]=lst[6];
		else
			if(math.abs(cH)>(0.45+1.3369*param[7])) then  -- A linear equation I have introduced
				-- The problem occurs for places above -+48 in the summer
				Night=24-(Setting-Rise); -- Night Length
				lst[6]=Setting+Night*IshFix; -- Accoording to Rabita Method
			else
				-- no problem
				H=math.acos(cH);
				H=H*RToH;  -- convert radians to hours
				lst[6]=K+(H+HightCorWest+param[1]);  -- Isha time, instead of  Sunset+1.5h
			end
			if(math.abs(cH)>1.0) then
				-- The problem occurs for places above -+48 in the summer
				IshRt,FajrRt=GetRatior(yg,mg,dg,param);
				Night=24-(Setting-Rise); -- Night Length
				lst[8]=Setting+Night*IshRt;  -- According to the general ratio rule
			else
				H=math.acos(cH);
				H=H*RToH; -- convert radians to hours
				lst[8]=K+(H+HightCorWest+param[1]); -- Isha time, instead of  Sunset+1.5h
			end
		end
	else
			lst[6]=lst[5]+param[11];  -- Isha time OmAlqrah standard Sunset+fixed time (1.5h or 2h in Romadan)
			lst[8]=lst[6];
	end
	
	--  Eid prayer time
	angl=param[12]; --  Eid Prayer time Angle is 4.2
	cH=(math.sin(angl)-SINd)/(COSd);
	if((math.abs(param[3])<1.134 or flagrs==0) and math.abs(cH)<=1.0) then --If latitude<65deg
		--no problem
		H=math.acos(cH);
		H=H*RToH; --convert radians to hours
		lst[9]=K-(H+HightCorEast)+param[1];  --Eid time
	else
		lst[9]=lst[2]+0.25;  -- If no Sunrise add 15 minutes
	end
	return flag,lst;
end


--[[ Function to obtain the ratio of the start time of Isha and Fajr at
  a referenced latitude (45deg suggested by Rabita) to the night length ]]
function GetRatior( yg, mg, dg, param)
	 local flagrs=0;
     local RA=0.0;
	 local Decl=0.0;
	 local Rise=0.0;
	 local Transit=0.0;
	 local Setting=0.0;
     local SINd=0.0;
	 local COSd=0.0;
     local H=0.0;
	 local angl=0.0;
	 local cH=0.0;
     local MaxLat=0.0;
	 local FjrRf=0.0;
	 local IshRf=0.0;
     local Night=0;
     local JD;

     if(param[2]<0) then
		 MaxLat= -(math.abs(param[10]));
	 else
		 MaxLat= math.abs(param[10]);
	 end

     Rise,Transit,Setting,RA,Decl,flagrs,JD=
		SunParamr(yg,mg,dg,-param[2],MaxLat,-param[6]);

     SINd=math.sin(Decl)*math.sin(MaxLat);
     COSd=math.cos(Decl)*math.cos(MaxLat);
     Night=24-(Setting-Rise);  -- Night Length

	 -- Fajr
     angl=-param[7];
     cH=(math.sin(angl)-SINd)/(COSd);
     H=math.acos(cH);
     H=H*RToH;  -- convert radians to hours
     FjrRf=Transit-H-param[1];   -- Fajr time

	 -- Isha
	 if(param[8]~=0) then  -- if Ish angle  not equal zero
	   angl=-param[8];
       cH=(math.sin(angl)-SINd)/(COSd);
       H=math.acos(cH);
       H=H*RToH;  -- convert radians to hours
       IshRf=Transit+H+param[1];    -- Isha time, instead of  Sunset+1.5h
	 else
      IshRf=Setting+param[11];  -- Isha time OmAlqrah standard Sunset+1.5h
	 end

   local IshRt=(IshRf-Setting)/Night;  -- Isha time ratio
   local FajrRt=(Rise-FjrRf)/Night;  -- Fajr time ratio

   return IshRt,FajrRt;
end

function PrayerTimes_Daily(dg,mg,yg)
--[[
/* Name:    PrayerTimes                                                      */
/* Type:    Procedure                                                        */
/* Purpose: Compute prayer times and sunrise                                 */
/* Arguments:                                                                */
/*   yg,mg,dg : Date in Greg                                                 */
/*   param[0]: Safety time  in hours should be 0.016383h                     */
/*   longtud,latud: param[1],[2] : The place longtude and latitude in radians*/
/*   HeightdifW : param[3]: The place western herizon height difference in meters */
/*   HeightdifE : param[4]: The place eastern herizon height difference in meters */
/*   Zonh :param[5]: The place zone time dif. from GMT  West neg and East pos*/
/*          in decimal hours                                                 */
/*  fjrangl: param[6]: The angle (radian) used to compute                    */
/*            Fajer prayer time (OmAlqrah  -19 deg.)                         */
/*  ashangl: param[7]: The angle (radian) used to compute Isha  prayer time  */
/*          ashangl=0 then use  (OmAlqrah: ash=SunSet+1.5h)                  */
/*  asr  : param[8]: The Henfy (asr=2) Shafi (asr=1, Omalqrah asr=1)         */
/*  param[9]: latude (radian) that should be used for places above -+65.5    */
/*            should be 45deg as suggested by Rabita                         */
/*   param[10]: The Isha fixed time from Sunset                              */
/*  Output:                                                                  */
/*  lst[]: lst[n], 1:Fajer 2:Sunrise 3:Zohar 4:Aser  5:Magreb  6:Ishe        */
/*                 7:Fajer using exact Rabita method for places >48          */
/*                 8:Ash   using exact Rabita method for places >48          */
/*                 9: Eid Prayer Time                                        */
/*          for places above 48 lst[1] and lst[6] use a modified version of  */
/*          Rabita method that tries to eliminate the discontinuity          */
/*         all in 24 decimal hours                                           */
/*         returns flag:0 if there are problems, flag:1 no problems          */
]]--

	local params = {};
	params[1]= City_Longtude * DToR;
	params[2]= City_Latitude * DToR;
	params[3]= City_Zone;
	params[4]= City_Fajir_Angle * DToR;
	params[5]= City_Asir_Calculation;

	-- param[0]=0.016388; /* 59 seconds, safety time */
    -- param[3] = 23;
    -- param[4] = 23;
    -- param[5] = Zone;
	-- param[6] = 12 * DtoR; // fjrangl
	-- param[7] = 0;
	-- param[8] = 1; // Aser=1,2
	-- param[9] = 0 * DtoR;// 45
	-- param[10] = 1.5; // Isha fixed time from sunset */
	-- param[11] = 4.2 * DtoR; // Eid Prayer Time   */

	local param = { 0.016388,params[1],params[2],23,23,
				params[3],params[4],0,params[5],0 * DToR,1.5,4.2 * DToR }; -- TODO isha is now +1.5 fix
    local _,prayerlist=PrayerTimes(yg,mg,dg,param);
	local prayername = { 'Fajer', 'Shrooq', 'Zohar', 'Aser', 'Magreb', 'Isha' };

	local ishapassed=false;

    --'prayerlist(x):
    --'1:   Fajer Sunrise Zohar Aser Magreb Isha
    --'7:   Fajer using exact Rabita method for places > 48
    --'8:   Isha using exact Rabita method for places > 48
    --'9:   Eid Prayer Time
	for i=1,6 do
	    local h= math.modf(prayerlist[i]);
	    local m= math.ceil(math.fmod(prayerlist[i] * 60,60));
	    local s= 0; --math.ceil(math.fmod(prayerlist[i] * 3600,60));
 		if h>=24 then -- happens if isha is over midnight e.g.  24:46:24
			h=h-24;
				local pnewtime = os.time({year=yg, month=mg, day=dg}) + 1 * 24 * 60 * 60
				local ptoday = os.date("*t", pnewtime);
				dg = ptoday.day
				mg = ptoday.month
				yg = ptoday.year
		end
		if CONSOLEPRINT then
			printf("%04d-%02d-%02d %6s %02d:%02d:%02d\n",yg,mg,dg,prayername[i],h,m,s);
		else
			Prayer_CreateEvent(prayername[i],yg,mg,dg,h,m,s);
		end
		-- did isha pass already
		if i==6 then
			local tmStart = os.time{year = yg, month = mg, day = dg, hour = h, min = m,sec=s};
			local TmNow = os.time();
			ishapassed=(os.difftime(tmStart,TmNow)<0); -- ishapassed=0 not yet
		end 
	end
	return ishapassed;
end

---------------------------------- --- main area
local today = os.date("*t")
local dg = today.day
local mg = today.month
local yg = today.year

local ishapassed=PrayerTimes_Daily(dg,mg,yg);

if  ishapassed then
	collectgarbage();
	local pnewtime = os.time({year=yg, month=mg, day=dg}) + 1 * 24 * 60 * 60
	local nextday = os.date("*t", pnewtime);
	local dp = nextday.day
	local mp = nextday.month
	local yp = nextday.year
	PrayerTimes_Daily(dp,mp,yp);
end

collectgarbage();

------------------------------------------------