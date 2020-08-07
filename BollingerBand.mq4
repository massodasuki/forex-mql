string getBollingerBand(int timeframe)
{
   //BollingerBand
   int BollingerPeriod = 20;
   int BollingerDeviation = 2;
   string bollinger = 1234;
   
   double MiddleBB = iBands(NULL,timeframe, BollingerPeriod, BollingerDeviation,0,0,MODE_MAIN,1);
   double LowerBB = iBands(NULL,timeframe, BollingerPeriod, BollingerDeviation, 0,0, MODE_LOWER,1);
   double UpperBB = iBands(NULL,timeframe,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,1);
   
   double PrevMiddleBB = iBands(NULL,60, BollingerPeriod, BollingerDeviation,0,0,MODE_MAIN,2);
   double PrevLowerBB = iBands(NULL,60, BollingerPeriod, BollingerDeviation, 0,0, MODE_LOWER,2);
   double PrevUpperBB = iBands(NULL,60,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,2);

    if(Close[1] > LowerBB && Close[2] < PrevLowerBB)
    {
      bollinger = "BUY";
    }
    
    if(Close[1] < UpperBB && Close[2] > PrevUpperBB)
    {
      bollinger = "SELL";
    }
    
    //-----------------------------
    
    
   return bollinger;
}