string getMACD()
{
   int MACD =  iMACD(
               NULL,           // symbol
               0,        // timeframe
               12,  // Fast EMA period
               26,  // Slow EMA period
               9,    // Signal line period
               PRICE_CLOSE,    // applied price
               MODE_MAIN,             // line index
               0             // shift
               );
               
    if (MACD > 0 ) {
         macd = "BULLISH"
    }
    
    if (MACD < 0 ) {
         macd = "BEARISH"
    }  
}