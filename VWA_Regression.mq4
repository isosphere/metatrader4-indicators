//+------------------------------------------------------------------+
//|                                               VWA_Regression.mq4 |
//|                                                 Matthew Scheffel |
//|                                           https://www.weeoak.com |
//+------------------------------------------------------------------+
#property copyright "Matthew Scheffel"
#property link      "https://www.weeoak.com"
#property version   "1.00"
#property strict

#define MAGICMA  201710

//--- Inputs
input double Lots           = 0.5;
input double MaximumRisk    = 0.1;
input double DecreaseFactor = 3;
input int  ExecuteThreshold = 20; // pips
input float ma_screen_ratio = 0.125;
input int trailing_stop = 200;

double VWA() {
    int j;
    long volume_sum = 0;
    double contribution_sum = 0.0;
    int current_bar = (Bars - 1);
    
    int ma_period = (int) round( WindowBarsPerChart() * ma_screen_ratio);
    
    ArraySetAsSeries(High, false);
    ArraySetAsSeries(Low, false);
    ArraySetAsSeries(Volume, false);    
    
    // 1. sum volume from i - ma_period to i
    for (j = current_bar - ma_period; j < current_bar + 1; j++) {
        volume_sum += Volume[j];
    }
    
    if (volume_sum == 0) {
        return ((High[current_bar] + Low[current_bar])/2);
    }
    
    // 2. find contribs
    for (j = current_bar - ma_period; j < current_bar + 1; j++) {
        contribution_sum += ((High[j] + Low[j])/2)*Volume[j];
    }
    
    // 3. calc weighted average
    return contribution_sum/volume_sum;
}

void MoveStops() {
    double ma;

    bool res;
    
    ma = VWA();

    for (int i=0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA) {

            // decided market was under valued
            if (OrderType() == OP_BUY) {
                if (Bid - OrderOpenPrice() > Point*trailing_stop) {
                    if (OrderStopLoss() < Bid - Point*trailing_stop) {
                        res = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Bid-Point*trailing_stop, Digits), OrderTakeProfit(), 0, Blue);
                        
                        if (!res) {
                            Print("Failed to modify stop.");
                        }
                    }
                }
            }
            
            // decided market was over valued
            else if (OrderType() == OP_SELL) {
                if (Ask - OrderOpenPrice() < Point*trailing_stop) {
                    if (OrderStopLoss() > Ask + Point*trailing_stop) {
                        res = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Ask+Point*trailing_stop, Digits), OrderTakeProfit(), 0, Blue);
                        
                        if (!res) {
                            Print("Failed to modify stop.");
                        }
                    }
                }
            }   
        }
    }
}


int CalculateCurrentOrders(string symbol) {
    int buys=0, sells=0;

    for (int i=0; i < OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA) {
            if (OrderType()==OP_BUY)  buys++;
            if (OrderType()==OP_SELL) sells++;
        }
    }

    if (buys > 0) {
        return(buys);
    } else {
        return(-sells);
    }
}
  
double LotsOptimized() {
    double lot = Lots;
    int    orders = HistoryTotal();     // history orders total
    int    losses = 0;                  // number of losses orders without a break
    
    lot = NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calculate number of losses orders without a break
    if (DecreaseFactor>0) {
        for (int i=orders-1;i>=0;i--) {
            if (OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) == false) {
                Print("Error in history!");
                break;
            }
            if (OrderSymbol() != Symbol() || OrderType()>OP_SELL)
                continue;
         
            if(OrderProfit()>0) break;
            if(OrderProfit()<0) losses++;
        }
        if (losses > 1)
            lot = NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
    }
//--- return lot size
    if(lot<0.1) lot=0.1;
    return(lot);
}
  
void CheckForOpen() {
    double ma, stoploss, takeprofit;
    double minstoplevel = 0;
    int    res;
    
    // check if the previous order was closed by stop loss. if it was, wait.
    if (OrderSelect(OrdersHistoryTotal()-1, SELECT_BY_POS, MODE_HISTORY)) {
        if (StringFind(OrderComment(), "[sl]", 0) != -1) {
            if (TimeCurrent() - OrderCloseTime() < 2*PeriodSeconds()*WindowBarsPerChart()*ma_screen_ratio) {
                //Print("Staying out of the way of a large market move against us, no new positions right now.");
                return;
            }
        }
    }
        
    ma = VWA(); 
    
    if (Bid - ma > ExecuteThreshold*0.0001) {
        minstoplevel = MathAbs(ma - Bid)*1e5;
    } 
    else if (ma - Ask > ExecuteThreshold*0.0001) {
        minstoplevel = MathAbs(ma - Ask)*1e5;
    }
    
    if (MarketInfo(Symbol(), MODE_STOPLEVEL) > minstoplevel) {
        minstoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    }
    
    // market overvalued
    if (Bid - ma > ExecuteThreshold*0.0001) {
        stoploss = NormalizeDouble(Bid + minstoplevel*Point, Digits);
        takeprofit = NormalizeDouble(Bid - 0.75*minstoplevel*Point, Digits);
        res = OrderSend(Symbol(), OP_SELL, LotsOptimized(), Bid, 3, stoploss, takeprofit, "", MAGICMA, 0, Red);
    }

    // market undervalued
    else if (ma - Ask > ExecuteThreshold*0.0001) {
        stoploss = NormalizeDouble(Ask - minstoplevel*Point, Digits);
        takeprofit = NormalizeDouble(Ask + 0.75*minstoplevel*Point, Digits);
        res = OrderSend(Symbol(), OP_BUY, LotsOptimized(), Ask, 3, stoploss, takeprofit, "", MAGICMA, 0, Blue);
    }
    
    return;
}

void CheckForClose() {
    double ma;
    
    //if (Volume[0]>1) return;

    ma = VWA();

    for (int i=0; i<OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderMagicNumber() != MAGICMA || OrderSymbol() != Symbol()) continue;
      
        // fairly priced now     
        if (OrderType() == OP_BUY && ma - Bid < trailing_stop*Point) {
            if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, White)) {
                Print("OrderClose error ", GetLastError());
                break;
            }
        } else if (OrderType() == OP_SELL && Ask - ma < trailing_stop*Point) {
            if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, White)) {
                Print("OrderClose error ", GetLastError());
                break;
            }
        }

    }
}  
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (Bars < 100 || IsTradeAllowed() == false) {
      return;
    } else {
        if (CalculateCurrentOrders(Symbol()) == 0) {
            CheckForOpen();
        } else {
            //CheckForClose();
            MoveStops();
        }
    }
}
