// Display estimates only. The processor must revalidate and recalculate.
TravelDays = DateDiff(DateValue(d.departure),DateValue(d.returnDate))+1;
ActivePolicy = LookUp(GTASPolicyV2,ProgramKey=d.programKey && Enabled=true);
DraftIssue =
 If(IsBlank(Trim(d.traveler)) || IsBlank(Trim(d.supervisor)) || IsBlank(Trim(d.programKey)) || IsBlank(Trim(d.purpose)) || IsBlank(Trim(d.categories)),"Complete the traveler, supervisor, program, categories and purpose.",
 !IsMatch(d.ownerEmail,Match.Email) || (!IsBlank(d.contactEmail) && !IsMatch(d.contactEmail,Match.Email)),"Check the traveler sign-in and contact emails.",
 d.organization="Subcontractor" && IsBlank(Trim(d.company)),"Enter the subcontractor company.",
 IsBlank(d.departure) || IsBlank(d.returnDate) || TravelDays<1 || (d.tripType="Same-Day" && TravelDays<>1) || (d.tripType="Overnight" && TravelDays<2),"Check departure and return dates.",
 IsEmpty(stops) || First(SortByColumns(stops,"start")).start<>d.departure || CountIf(stops,start>d.returnDate)>0,"Check the itinerary dates.",
 IsBlank(ActivePolicy),"The coordinator must configure the program policy.",
 IsBlank(EstimateTotal),"Review missing rates, effective dates, mileage policy or above-rate justification.",
 Blank());
TransportCost = If(d.air,d.airfare+If(d.airportMethod="Dropped Off",d.dropMiles*ActivePolicy.MileageRate,d.airportCost),0)+If(d.rental,d.rentalCost+d.fuel,0)+If(d.pov,d.miles*ActivePolicy.MileageRate,0)+If(d.rail,d.railCost,0)+If(d.pov || d.rental,d.tolls,0);
EstimateTotal =
 If(IsBlank(ActivePolicy) || IsEmpty(stops) ||
 ((d.pov || (d.air && d.airportMethod="Dropped Off")) && IsBlank(ActivePolicy.MileageRate)) ||
 (d.tripType="Overnight" && CountIf(stops,quote<0)>0) ||
 Min(d.registration,d.misc)<0 ||
 (d.air && (d.airfare<0 || If(d.airportMethod="Dropped Off",d.dropMiles<0,d.airportCost<0))) ||
 (d.pov && d.miles<0) || (d.rental && Min(d.rentalCost,d.fuel)<0) ||
 ((d.pov || d.rental) && d.tolls<0) || (d.rail && d.railCost<0) ||
 (d.tripType="Overnight" && Min(d.hotelParking,d.resortFees)<0) ||
 (d.tripType="Overnight" && CountIf(stops As s,
 With({rate:LookUp(GTASRatesV2,ID=s.rateId),lastDay:DateValue(Coalesce(First(SortByColumns(Filter(stops,start>s.start),"start")).start,Text(DateValue(d.returnDate)+1,"yyyy-mm-dd")))-1},
 IsBlank(rate) || Lower(rate.City)<>Lower(s.city) || Lower(rate.Region)<>Lower(s.region) || DateValue(s.start)<rate.EffectiveFrom || lastDay>rate.EffectiveTo || (s.quote>rate.Lodging && IsBlank(Trim(s.justification)))))>0),
 Blank(),
 Round(Round(TransportCost,2)+Round(OtherCost,2)+Round(LodgingCost,2)+Round(MieCost,2),2));
OtherCost = d.registration+d.misc+If(d.tripType="Overnight",d.hotelParking+d.resortFees,0);
LodgingCost = If(d.tripType="Same-Day",0,
 Sum(stops As s,
 With({rate:LookUp(GTASRatesV2,ID=s.rateId),startDay:DateValue(s.start),nextDay:DateValue(Coalesce(First(SortByColumns(Filter(stops,start>s.start),"start")).start,Text(DateValue(d.returnDate)+1,"yyyy-mm-dd")))},
 rate.Lodging*Max(0,DateDiff(startDay,If(nextDay<DateValue(d.returnDate),nextDay,DateValue(d.returnDate)))))));
MieCost = If(d.tripType="Same-Day",If(ActivePolicy.SameDayMieAllowed,ActivePolicy.SameDayMieAmount,0),
 Sum(stops As s,
 With({rate:LookUp(GTASRatesV2,ID=s.rateId),startDay:DateValue(s.start),nextDay:DateValue(Coalesce(First(SortByColumns(Filter(stops,start>s.start),"start")).start,Text(DateValue(d.returnDate)+1,"yyyy-mm-dd")))},
 rate.Mie*(DateDiff(startDay,nextDay)-If(s.start=d.departure,0.25,0)-If(nextDay=DateValue(d.returnDate)+1,0.25,0)))));
