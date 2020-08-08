//+------------------------------------------------------------------+
//|                                    STOCASTIC_MACD_BOLLINGER_v1.0 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

extern double global_LotSize = 0.01; 
extern int global_TakeProfit = 50;
extern int global_StopLoss = 200;
extern int MagicNumber = 345507;

static int buyTicket=0;
static int sellTicket=0;


void OnTick()
  {
//---
   double spread = MarketInfo(Symbol(), MODE_SPREAD);
   string Today = getToday();
   string Market = getMarket();
   string Bollinger = getBollingerBand(0);
   string Stochastic =  getStocastic(0);
   string Macd = getMACD();
   
   
   runTradeAlgo();
   modifyOrder();
   
   Comment (
   "\n",
   
   "TODAY : ",Today,"\n",
   "MARKET : ",Market,"\n",
   "BOLLINGER : ",Bollinger,"\n",
   "STOCASTIC : ", Stochastic,"\n",
   "MACD : ",Macd,"\n",
   "SPREAD : ", DoubleToStr(spread,0),"\n"
   );
   
  }
//+------------------------------------------------------------------+


static string confirmationMacd = "";
static string confirmationStochastic = "";

void runTradeAlgo() {
   
   double spread = MarketInfo(Symbol(), MODE_SPREAD);
   string Today = getToday();
   string Market = getMarket();
   
   string Stochastic =  getStocastic(0);
   string Macd = getMACD();
   string Bollinger = getBollingerBand(0);

   if ( spread > 10 ){
      return ;
   }
   
   if ( Today == "Sat" || Today == "Sun"){
      return ;
   }
   
   if ( Market == "CLOSE"){
      return ;
   }
   
   
   
   if ( Macd == "BULL"){
      confirmationMacd = "BULL";
   }
   if ( Macd == "BEAR"){
      confirmationMacd = "BEAR";
   }
   
   
   if ( Stochastic == "OVERSOLD"){
      confirmationStochastic = "OVERSOLD";
   }
   if ( Stochastic == "OVERBOUGHT"){
      confirmationStochastic = "OVERBOUGHT";
   }
   
   
   Print(Bollinger);
   //--- Ready to buy/sell
   if (confirmationMacd == "BULL" && confirmationStochastic == "OVERBOUGHT" )
   {  
      
      if ( Bollinger == "SELL"){
         sell(global_LotSize, global_TakeProfit, global_StopLoss);
      }
   }
   
   if (confirmationMacd == "BEARISH" && confirmationStochastic == "OVERSOLD" )
   {
      if ( Bollinger == "BUY"){
         buy(global_LotSize, global_TakeProfit, global_StopLoss);
      }
   }
}


//-----------------------------------------------
//                                 Modify Order// 
//-----------------------------------------------
extern bool UseTrailingStop = true;
extern bool UseAdvanceTrailingStop = false;
extern int WhenToTrail=50;
extern int TrailAmount = 15;

extern bool UseCandleTrail=false;
extern int PadAmount = 50;
extern int LastCandle = 5;

static int BarsOnChart=0;

static int buyStopCandle=0;
static int sellStopCandle=0;

extern bool UseMoveToBreakeven = true;
extern int WhenToMoveToBE = 50;
extern int PipsToLockedInBE = 5;

double pips = 0;


void modifyOrder(){
  Print(UseMoveToBreakeven);
  if(OpenOrdersThisPair(Symbol())>=1)
   {
      if(UseMoveToBreakeven)
      {
         Print("MBE");
         MoveToBreakEven();
      }
      
      if(UseTrailingStop)
      {
         Print("TS");
         AdjustTrail();
      }
   }
   
   return;
}


//+------------------------------------------------------------------+
//|                                                Read Total Trades |
//|                                              Author Masso Dasuki |
//+------------------------------------------------------------------+


int OpenOrdersThisPair(string pair)
{
   double minlot = MarketInfo(Symbol(), MODE_MINLOT);
   
   int total = 0;
      for (int i=OrdersTotal()-1; i>=0;i--)
      { 
      //select trade
         if (OrderSelect(i, SELECT_BY_POS)==true)
         {
            //check if trade belongs to current chart
            if(OrderSymbol()== pair)
            {
                  total++;;
                  
            }
         }
      }
   return (total);
}

//+------------------------------------------------------------------+
//|                                                Trailing Function |
//|                                              Author Masso Dasuki |
//+------------------------------------------------------------------+

//Read New Candle
bool IsNewCandle ()
{  
   if (Bars == BarsOnChart)
   return(false);
   BarsOnChart = Bars; //How many bars
   return(true);
}


void MoveToBreakEven ()
{  
   for(int b=OrdersTotal()-1; b >=0 ; b--)
   {
      if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
         if(OrderMagicNumber() != MagicNumber) continue; //jump
            if(OrderSymbol()==Symbol())
               if(OrderType()== OP_BUY)
                  if(Bid-OrderOpenPrice()>WhenToMoveToBE*pips)
                     if(OrderOpenPrice()>OrderStopLoss())
                        modifyOrderBuyMBE();
                        //Print("Debug: BUY - Move To Break Even");
                        //OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(PipsToLockedIn*pips), OrderTakeProfit(),0,CLR_NONE); OLD MQL
   }
   for(int s=OrdersTotal()-1; s >=0 ; s--)
   {
      if(OrderSelect(s,SELECT_BY_POS,MODE_TRADES))
         if(OrderMagicNumber() != MagicNumber) continue; //jump
            if(OrderSymbol()==Symbol())
               if(OrderType()== OP_SELL)
                  if(OrderOpenPrice()-Ask>WhenToMoveToBE*pips)
                     if(OrderOpenPrice()<OrderStopLoss())
                        modifyOrderSellMBE();
                        //Print("Debug: SELL - Move To Break Even");
                        //OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(PipsToLockedIn*pips), OrderTakeProfit(),0,CLR_NONE);OLD MQL
   }
   

}


void AdjustTrail()
{

   buyStopCandle = iLowest(NULL,0,1,LastCandle,0);
   sellStopCandle = iHighest(NULL,0,2,LastCandle,0);

   for(int b= OrdersTotal()-1; b>=0; b--)
   {
   if(OrderSelect(b,SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber()== MagicNumber)
         if(OrderSymbol() == Symbol())
            if(OrderType()==OP_BUY)
               if(UseCandleTrail)
                  { if (IsNewCandle())
                    if(OrderStopLoss()<Low[buyStopCandle]-PadAmount*pips)
                    modifyOrderBuyTrailCandle();
                    //Print("Debug: BUY - Adjust Trail Candle");
                    //OrderModify(OrderTicket(), OrderOpenPrice(), Low[buyStopCandle]-PadAmount*pips, OrderTakeProfit(),0,CLR_NONE);
                  }
                     else if(Bid-OrderOpenPrice()>WhenToTrail*pips)
                     if(OrderStopLoss()< Bid-TrailAmount*pips)
                     modifyOrderBuyTrail();
                     //Print("Debug: BUY - Adjust Trail");
                    // OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(TrailAmount*pips), OrderTakeProfit(),0,CLR_NONE);
   }
   
   for(int s= OrdersTotal()-1; s>=0; s--)
   {
   if(OrderSelect(s,SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber()== MagicNumber)
         if(OrderSymbol() == Symbol())
            if(OrderType()==OP_SELL)
               if(UseCandleTrail)
                  { if (IsNewCandle())
                    if(OrderStopLoss()<High[sellStopCandle]+PadAmount*pips)
                    modifyOrderSellTrailCandle();
                    //Print("Debug: SELL - Adjust Trail Candle");
                   // OrderModify(OrderTicket(), OrderOpenPrice(), High[sellStopCandle]-PadAmount*pips, OrderTakeProfit(),0,CLR_NONE);
                  }
                     else if(OrderOpenPrice()-Ask>WhenToTrail*pips)
                     if(OrderStopLoss()> Ask+pips*TrailAmount || OrderStopLoss()==0)
                     modifyOrderSellTrail();
                     //Print("Debug: SELL - Adjust Trail");
                   //  OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(TrailAmount*pips), OrderTakeProfit(),0,CLR_NONE);
   }
      
}


void AdvanceAdjustTrail()
{

   buyStopCandle = iLowest(NULL,0,1,LastCandle,0);
   sellStopCandle = iHighest(NULL,0,2,LastCandle,0);

   for(int b= OrdersTotal()-1; b>=0; b--)
   {
   if(OrderSelect(b,SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber()== MagicNumber)
         if(OrderSymbol() == Symbol())
            if(OrderType()==OP_BUY)
               if(UseCandleTrail)
                  { if (IsNewCandle())
                   if(Bid-OrderOpenPrice()>WhenToTrail*pips)
                    if(OrderStopLoss()<Low[buyStopCandle]-PadAmount*pips)
                    modifyOrderBuyTrailCandle();
                    //Print("Debug: BUY - Adjust Trail Candle");
                    //OrderModify(OrderTicket(), OrderOpenPrice(), Low[buyStopCandle]-PadAmount*pips, OrderTakeProfit(),0,CLR_NONE);
                  }
                     else if(Bid-OrderOpenPrice()>WhenToTrail*pips)
                     if(OrderStopLoss()< Bid-TrailAmount*pips)
                     modifyOrderBuyTrail();
                     //Print("Debug: BUY - Adjust Trail");
                    // OrderModify(OrderTicket(),OrderOpenPrice(),Bid-(TrailAmount*pips), OrderTakeProfit(),0,CLR_NONE);
   }
   
   for(int s= OrdersTotal()-1; s>=0; s--)
   {
   if(OrderSelect(s,SELECT_BY_POS, MODE_TRADES))
      if (OrderMagicNumber()== MagicNumber)
         if(OrderSymbol() == Symbol())
            if(OrderType()==OP_SELL)
               if(UseCandleTrail)
                  { if (IsNewCandle())
                    if(OrderOpenPrice()-Ask>WhenToTrail*pips)
                    if(OrderStopLoss()<High[sellStopCandle]+PadAmount*pips)
                    modifyOrderSellTrailCandle();
                    //Print("Debug: SELL - Adjust Trail Candle");
                   // OrderModify(OrderTicket(), OrderOpenPrice(), High[sellStopCandle]-PadAmount*pips, OrderTakeProfit(),0,CLR_NONE);
                  }
                     else if(OrderOpenPrice()-Ask>WhenToTrail*pips)
                     if(OrderStopLoss()> Ask+pips*TrailAmount || OrderStopLoss()==0)
                     modifyOrderSellTrail();
                     //Print("Debug: SELL - Adjust Trail");
                   //  OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(TrailAmount*pips), OrderTakeProfit(),0,CLR_NONE);
   }
      
}



//+------------------------------------------------------------------+
//|                                Trail Buying and Selling Function |
//|                                              Author Masso Dasuki |
//+------------------------------------------------------------------+

void modifyOrderBuyTrail()
 {
  //Print("Debug: SUCCESS - modifyOrderBuyTrail()");  
            bool res;
            
            res = OrderModify(
            buyTicket,
            OrderOpenPrice(),
            Bid-(TrailAmount*pips), 
            OrderTakeProfit(),
            0,
            CLR_NONE);
             
               
            if(res == false)
            {
                  Comment("Error modifyOrderBuyTrail Order: ", GetLastError());
                  //Print("Debug: ERROR - modifyOrderBuyTrail()");
            }
               else
            {
                  Comment("Order modifyOrderBuyTrail Successfully, Ticket # is: " + string(buyTicket));
                  //Print("Debug: SUCCESS - modifyOrderBuyTrail() Ticket #: ",string(buyTicket));
            }
            
           
}

void modifyOrderSellTrail()
 {
 //Print("Debug: SUCCESS - modifyOrderSellTrail()");  
            bool res;
            
            res = OrderModify(
            sellTicket,
            OrderOpenPrice(),
            Ask+(TrailAmount*pips), 
            OrderTakeProfit(),
            0,
            CLR_NONE);
             
               
            if(res == false)
            {
                  Comment("Error modifyOrderSellTrail Order: ", GetLastError());
                  //Print("Debug: ERROR - modifyOrderBuyTrail()");
            }
               else
            {
                  Comment("Order modifyOrderSellTrail Successfully, Ticket # is: " + string(sellTicket));
                  //Print("Debug: SUCCESS - modifyOrderSellTrail() Ticket #: ",string(buyTicket));  
            }
            
           
}

void modifyOrderBuyTrailCandle()
 { //OrderModify(OrderTicket(), OrderOpenPrice(), Low[buyStopCandle]-PadAmount*pips, OrderTakeProfit(),0,CLR_NONE);
 //Print("Debug: SUCCESS - modifyOrderBuyTrailCandle()");  
            bool res;
            
            res = OrderModify(
            buyTicket,
            OrderOpenPrice(),
            Low[buyStopCandle]-(PadAmount*pips), 
            OrderTakeProfit(),0,CLR_NONE);
             
               
            if(res == false)
            {
                  Comment("Error modifying Order: ", GetLastError());
            }
               else
            {
                  Comment("Order Buy Modifying Successfully, Ticket # is: " + string(buyTicket));
                  //Print("Debug: SUCCESS - modifyOrderBuyTrailCandle() Ticket #: ",string(buyTicket));  
            }
            
           
}

void modifyOrderSellTrailCandle()
 { // OrderModify(OrderTicket(), OrderOpenPrice(), High[sellStopCandle]-PadAmount*pips, OrderTakeProfit(),0,CLR_NONE);
  //Print("Debug: SUCCESS - modifyOrderSellTrailCandle()");  
            bool res;
            
            res = OrderModify(
            sellTicket,
            OrderOpenPrice(),
            High[sellStopCandle]+(PadAmount*pips), 
            OrderTakeProfit(),0,CLR_NONE);
             
               
            if(res == false)
            {
                  Comment("Error modifying Order: ", GetLastError());
            }
               else
            {
                  Comment("Order Buy Modifying Successfully, Ticket # is: " + string(sellTicket));
                  //Print("Debug: SUCCESS - modifyOrderSellTrailCandle() Ticket #: ",string(buyTicket)); 
            }
            
           
}


void modifyOrderBuyMBE()
 {
   //Print("Debug: SUCCESS - modifyOrderBuy()");  
            bool res;
            
            res = OrderModify(
            buyTicket,
            OrderOpenPrice(),
            OrderOpenPrice()+(PipsToLockedInBE*pips), 
            OrderTakeProfit(),0,CLR_NONE);
             
               
            if(res == false)
            {
                  Comment("Error modifying Order: ", GetLastError());
            }
               else
            {
                  Comment("Order Buy Modifying Successfully, Ticket # is: " + string(buyTicket));
                  //Print("Debug: SUCCESS - modifyOrderBuy() Ticket #: ",string(buyTicket));  
            }
            
           
}

void modifyOrderSellMBE()
 {
         //Print("Debug: SUCCESS - modifyOrderSell()");  
            bool res;
            
            res = OrderModify(
            sellTicket,
            OrderOpenPrice(),
            OrderOpenPrice()-(PipsToLockedInBE*pips), 
            OrderTakeProfit(),0,CLR_NONE);
             
               
            if(res == false)
            {
                  Comment("Error modifying Order: ", GetLastError());
                  
            }
               else
            {
                  Comment("Order Buy Modifying Successfully, Ticket # is: " + string(sellTicket));
                  //Print("Debug: SUCCESS - modifyOrderSell() Ticket #: ",string(buyTicket));  
            }           
}

//+------------------------------------------------------------------+

void buy(double LotSize, int TakeProfit, int StopLoss)
{
    // order buy
    if (OrdersTotal()==0)
    {
     buyTicket = OrderSend
    (
    Symbol(),               //currency pair on the chart
    OP_BUY,                 // buy without delay
    LotSize,                   // 10 microlot
    Ask,                    // for the market price
    3,                      //only 3 pips slippage
    Ask-StopLoss*_Point,    // Stop Loss at StopLoss point
    Ask+TakeProfit*_Point,  // Take Profit TakeProfit point
    NULL,                   // no comment text
    MagicNumber,                      // no id number magic number
    0,                      //no expiration date
    Green                   //draw green arrow
    );
               
      if(buyTicket == 0)
      {
      Comment("buy() OrderSend Error: ", GetLastError());
      //Print("buy() OrderSend Error: ", GetLastError());
      }
      else
      {
      Alert("EA BUY() || Ticket #: ",string(buyTicket)); 
      Comment("Order Sent Successfully, Ticket # is: " + string(buyTicket));
      }}
}

void sell(double LotSize, int TakeProfit, int StopLoss)
{
         // order sell 
      if (OrdersTotal()==0)
      {
      sellTicket = OrderSend
      (
      Symbol(),               //currency pair on the chart
      OP_SELL,                // sell without delay
      LotSize,                   // 10 microlot
      Bid,                    // for the market price
      3,                      //only 3 pips slippage
      Bid+StopLoss*_Point,    // Stop Loss  at StopLoss point
      Bid-TakeProfit*_Point,  // Take Profit 10 point
      NULL,                   // no comment text
      MagicNumber,                      // no id number magic number
      0,                      //no expiration date
      Yellow                    //draw blue arrow
      );
      
          if(sellTicket == 0)
          {
           Comment("sell() OrderSend Error: ", GetLastError());
           //Print("sell() OrderSend Error: ", GetLastError());
           }
           else
           {
           Alert("EA SELL()|| Ticket #: ",string(sellTicket));  
           Comment("Order Sent Successfully, Ticket # is: " + string(sellTicket));
           }}         
}

string getToday(){

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
 
 string getMarket(){
 
   string market = "";
   
   int Market = MarketInfo(Symbol(), MODE_TRADEALLOWED);
   
   if ( Market == 1) {
      market = "OPEN";
   }
   else {
      market = "CLOSE";
   }
   
   return market; 
 }



string getStocastic(int timeframe){

  string stocastic = "";
  int a = 0;
  
  double mainLine;
  double prevMainLine;
  double signalLine;
  double prevSignalLine;
  int overbought_percent = 80;
  int oversold_percent = 20;
  
       mainLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_MAIN,a);
       prevMainLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_MAIN,a+1);
                
       signalLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,a);
       prevSignalLine = iStochastic(NULL,timeframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,a+1);
       
       //Print(mainLine);
       //Print(prevMainLine);
       //Print(signalLine);
       //Print(prevSignalLine);
       
       if(prevMainLine <= oversold_percent && prevSignalLine <= oversold_percent && mainLine <= oversold_percent && signalLine <= oversold_percent )
       {
         if(prevMainLine < prevSignalLine && mainLine > signalLine){
         stocastic = "OVERSOLD";
         }
       }
       
       if(prevMainLine >= overbought_percent && prevSignalLine >= overbought_percent && mainLine >= overbought_percent && signalLine >= overbought_percent )
       {
          if(prevMainLine > prevSignalLine && mainLine < signalLine){
          stocastic = "OVERBOUGHT";
          }
       }
       
   return stocastic;
}

string getMACD()
{
   string macd;
   float MACD =  iMACD(
               NULL,           // symbol
               0,        // timeframe
               12,  // Fast EMA period
               26,  // Slow EMA period
               9,    // Signal line period
               PRICE_CLOSE,    // applied price
               MODE_MAIN,             // line index
               0             // shift
               );
               
    //Print(MACD);
               
    if (MACD > 0 ) {
         macd = "BULL";
    }
    
    if (MACD < 0 ) {
         macd = "BEAR";
    }
    
    return macd;
}

string getBollingerBand(int timeframe)
{
   //BollingerBand
   int BollingerPeriod = 20;
   int BollingerDeviation = 2;
   string bollinger = "";
   
   double MiddleBB = iBands(NULL,timeframe, BollingerPeriod, BollingerDeviation,0,0,MODE_MAIN,1);
   double LowerBB = iBands(NULL,timeframe, BollingerPeriod, BollingerDeviation, 0,0, MODE_LOWER,1);
   double UpperBB = iBands(NULL,timeframe,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,1);
   
   double PrevMiddleBB = iBands(NULL,timeframe, BollingerPeriod, BollingerDeviation,0,0,MODE_MAIN,2);
   double PrevLowerBB = iBands(NULL,timeframe, BollingerPeriod, BollingerDeviation, 0,0, MODE_LOWER,2);
   double PrevUpperBB = iBands(NULL,timeframe,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,2);

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

