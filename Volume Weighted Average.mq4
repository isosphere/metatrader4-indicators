//+------------------------------------------------------------------+
//|                                      Volume Weighted Average.mq4 |
//|                                                 Matthew Scheffel |
//|                                           https://www.weeoak.com |
//+------------------------------------------------------------------+
#property copyright "Matthew Scheffel"
#property link      "https://www.weeoak.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#property indicator_buffers 1
#property indicator_color1 LightSeaGreen

input float ma_screen_ratio = 0.125;

double  LineBuffer[];

int OnInit() {
   SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(0, LineBuffer, INDICATOR_DATA);
   SetIndexLabel(0, "Volume-weighted Average");
   
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[],
                const double &close[], const long &tick_volume[], const long &volume[],
                const int &spread[]) {

    int i, j;
    long volume_sum = 0;
    double contribution_sum = 0.0;
    
    int ma_period = (int) round( WindowBarsPerChart() * ma_screen_ratio);
    
    ArraySetAsSeries(high, false);
    ArraySetAsSeries(low, false);
    ArraySetAsSeries(tick_volume, false);
    ArraySetAsSeries(LineBuffer, false);
    
    for (i = prev_calculated + 1 + ma_period; i < rates_total; i++) {   
        // 1. sum volume from i - ma_period to i
        volume_sum = 0;
        for (j = i - ma_period; j < i + 1; j++) {
            volume_sum += tick_volume[j];
        }
        
        if (volume_sum == 0) {
            return(rates_total);
        }
        
        // 2. find contribs
        contribution_sum = 0.0;
        for (j = i - ma_period; j < i + 1; j++) {
            contribution_sum += ((high[j] + low[j])/2)*tick_volume[j];
        }
        
        // 3. calc weighted average
        LineBuffer[i] = contribution_sum/volume_sum;
    }
    
   return(rates_total);
}
