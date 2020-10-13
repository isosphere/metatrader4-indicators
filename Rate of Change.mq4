//+------------------------------------------------------------------+
//|                                               Rate of Change.mq4 |
//|                                                 Matthew Scheffel |
//|                                           https://www.weeoak.com |
//+------------------------------------------------------------------+
#property copyright "Matthew Scheffel"
#property link      "https://www.weeoak.com"
#property version   "1.00"
#property strict

#property indicator_separate_window

//--- plot ROC
#property indicator_buffers 2

#property indicator_label1  "ROC"
#property indicator_type1   DRAW_LINE 
#property indicator_color1  clrDeepPink 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 

#property indicator_label2  "ROCMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrAqua
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- indicator buffers
double ROCBuffer[];
double ROCMABuffer[];

int OnInit() {
    SetIndexBuffer(0, ROCBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, ROCMABuffer, INDICATOR_DATA);

    return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[],
                const double &high[], const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {

    int i = Bars - prev_calculated - 1;
    
    double average_now, average_then;
    int time_delta;
    
    // reverse the indexing, backwards arrays confuse me
    if (ArrayGetAsSeries(high)) {
        ArraySetAsSeries(high, false);
    }
    
    if (ArrayGetAsSeries(low)) {
        ArraySetAsSeries(low, false);
    }
    
    if (ArrayGetAsSeries(time)) {
        ArraySetAsSeries(time, false);
    }
   
    if (ArrayGetAsSeries(ROCBuffer)) {
        ArraySetAsSeries(ROCBuffer, false);
    }
    
    if (ArrayGetAsSeries(ROCMABuffer)) {
        ArraySetAsSeries(ROCMABuffer, false);
    }
       
    while (i > 1) {
        //time_delta = ((int) time[i]) - ((int) time[i-1]);
        time_delta = 1;
        average_now = (high[i] + low[i])/2;
        average_then = (high[i-1] + low[i-1])/2;
      
        ROCBuffer[i] = (average_now - average_then)/time_delta;
        
        i--;
    }
    
    i = Bars - prev_calculated - 1;
    
    while (i > 1) {
        ROCMABuffer[i] = iMAOnArray(ROCBuffer, 0, 5, 0, MODE_EMA, i);
        i--;
    }
   
    return(rates_total);
}