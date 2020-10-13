//+------------------------------------------------------------------+
//|                                                   RSI_Trader.mq4 |
//|                                                 Matthew Scheffel |
//|                                            http://www.weeoak.com |
//+------------------------------------------------------------------+
#property copyright "Matthew Scheffel"
#property link      "http://www.weeoak.com"
#property version   "1.00"
//#property strict

#define MAGICMA  20170902

//--- input parameters
input int      SellLevel = 77;
input int      BuyLevel = 23;
input int      TrendPeriod = 14;
input int      MaxOrders = 5;
input double   MACDSignificance = 0.005;
input double   MaximumRisk = 0.02;
input double   DecreaseFactor = 3;
input double   Lots = 0.1;

/*

Objective:

- If there is volume,
- If we are trending up
- If we are oversold, 

Buy.

*/

double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
//+----


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
void OnTick() {
   double MACDMain;
   //float MACDSignal;
   double buffer[100];
   int result;

   // only trade if we have some history and trade is allowed
   if (Bars < 100 || IsTradeAllowed() == False) {
      return;
   }
   
   // check up on our orders
   int orders_count = 0;
   for (int i=0; i < OrdersTotal(); i++) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) {
         break;
      }
      
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA) {
         orders_count++;
      }
   }
   
   // check for new trade opportunities
   if (orders_count < MaxOrders) {
   /*
      // check for volume - short-term moving average should be >= longer term
      for (int i=0; i < 100; i++) {
         buffer[i] = Volume[i];
      }
      
      if (iMAOnArray(buffer, TrendPeriod, TrendPeriod/2, 0, MODE_SMA, 0) < iMAOnArray(buffer, TrendPeriod, TrendPeriod, 0, MODE_SMA, 0)) {
         return;
      }
      */
      
      // check for an upward trend
     MACDMain = iMACD(Symbol(), PERIOD_CURRENT, 7, 14, 3, PRICE_MEDIAN, MODE_MAIN, 0);
     
     // is this insignificant?
     if (MACDMain < 0 || MACDMain/PRICE_MEDIAN < MACDSignificance) {
         return;
     }
      
     // check for a buying opportunity
     //if (iRSI(Symbol(), PERIOD_CURRENT, TrendPeriod, PRICE_LOW, 0) < 30) {
         result = OrderSend(Symbol(),OP_BUY,0.1,Ask,10,Ask - 4*MACDMain,0,"",MAGICMA,0,Red);
     //} 
     
   }
   
}
//+------------------------------------------------------------------+
