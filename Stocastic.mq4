string getStocastic(int timeframe){
  
  string stocastic = "";
  int a = 0;
  
  double mainLine;
  double prevMainLine;
  double signalLine;
  double prevSignalLine;
  int overbought_percent = 80;
  int oversold_percent = 20
  
       mainLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_MAIN,a);
       prevMainLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_MAIN,a+1);
                
       signalLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,a);
       prevSignalLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,a+1);
       
       if(prevMainLine <= oversold_percent && prevSignalLine <= oversold_percent && mainLine <= oversold_percent && signalLine <= oversold_percent )
       {
         if(prevMainLine < prevSignalLine && mainLine > signalLine){
         stocastic = "BUY";
         }
       }
       
       if(prevMainLine >= overbought_percent && prevSignalLine >= overbought_percent && mainLine >= overbought_percent && signalLine >= overbought_percent )
       {
          if(prevMainLine > prevSignalLine && mainLine < signalLine){
          stocastic = "SELL";
          }
       }
       
   return stocastic;
}