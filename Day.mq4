#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

int getToday(){

   int theDay = DayOfWeek();
   string thisDay ="";
   string today ="";
   
   if(theDay == 0){today="Sun";}
   if(theDay == 1){today="Mon";}
   if(theDay == 2){today="Tue";}
   if(theDay == 3){today="Wed";}
   if(theDay == 4){today="Thur";}
   if(theDay == 5){today="Fri";}
   if(theDay == 6){today="Sat";}
   
   return today; 
 }