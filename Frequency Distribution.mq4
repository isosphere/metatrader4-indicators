//#property copyright "David Alfonsi" // code has been substantially changed. D. Alfonsi credit left here to attribute starting point.
#property copyright "Matthew Scheffel"

extern int NumOfBands=300;
extern color BandColour=clrSalmon;

#property indicator_chart_window

#define ObjectLabel "Distribution_"

double InternalBuffer[];

datetime first_click = NULL;
datetime second_click = NULL;

void Clear() { 
    ObjectDelete(ObjectLabel+"first_click");
    ObjectDelete(ObjectLabel+"second_click");
    for (int k=0; k <= NumOfBands; k++) {
        if (ObjectFind(ObjectLabel+k) >= 0) { 
            ObjectDelete(ObjectLabel+k);
        }
    }
}

void CreateBlock(int i, int block_count, int maximum_count, datetime click1, datetime click2) {   
    double BandSize = (WindowPriceMax() - WindowPriceMin()) / NumOfBands;
    int BarsTotal = WindowBarsPerChart();
    
    datetime earliest;
    datetime latest;
    
    if (click1 > click2) {
        latest = click1;
        earliest = click2;
    } else {
        latest = click2;
        earliest = click1;
    }
    
    float block_range = 1.00-((float) block_count)/((float) maximum_count);  // this block count divided by the maximum count
    int full_range = latest - earliest;
        
    ObjectCreate(ObjectLabel+i, OBJ_RECTANGLE, 0, earliest, WindowPriceMin()+(i+1)*BandSize, latest-round(block_range*full_range), WindowPriceMin()+i*BandSize);
    ObjectSet(ObjectLabel+i, OBJPROP_COLOR, BandColour);
}

int OnInit() {
    Clear();
    SetIndexBuffer(1, InternalBuffer, INDICATOR_CALCULATIONS);
    ArrayResize(InternalBuffer, NumOfBands);
    return(INIT_SUCCEEDED);
}

// Recalculates the price distribution into InternalBuffer and returns the maximum frequency observed.
int CalculateBands(datetime click1, datetime click2) {
    double high_price = WindowPriceMax();
    double low_price = WindowPriceMin();
    double BandSize = (high_price - low_price) / NumOfBands; // scale bands
    
    datetime earliest;
    datetime latest;
    
    if (click1 > click2) {
        latest = click1;
        earliest = click2;
    } else {
        latest = click2;
        earliest = click1;
    }
    
    int earliest_bar = iBarShift(Symbol(), 0, earliest, false);
    int latest_bar = iBarShift(Symbol(), 0, latest, false);
    
    int Count = 0;
    int maximum_count = 0;
    
    // Iterate across distribution bands (vertically)
    for (int band_count=0; band_count <= NumOfBands; band_count++) {
        // Iterate across bars on the chart (horizontally)
        for (int bar_count=latest_bar; bar_count <= earliest_bar; bar_count++) {
            double LR = low_price+band_count*BandSize;      // find low price coordinate for band
            double HR = low_price+(band_count+1)*BandSize;  // find high price coordinate for band
               
            //double average = (iLow(Symbol(), NULL, bar_count) + iHigh(Symbol(), NULL, bar_count))/2.0;
            
            if (iLow(Symbol(), NULL, bar_count) >= LR && iLow(Symbol(), NULL, bar_count) <= HR) {
                Count++;
            }
            else if (iHigh(Symbol(), NULL, bar_count) >= LR && iHigh(Symbol(), NULL, bar_count) <= HR) {
                Count++;
            }
            else if (iHigh(Symbol(), NULL, bar_count) > HR && iLow(Symbol(), NULL, bar_count) < LR) {
                Count++;
            }
        }

        InternalBuffer[band_count] = Count;
        if (Count > maximum_count) {
            maximum_count = Count;
        }
        Count=0;
    }
    
    return maximum_count;
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) {

    if (id == CHARTEVENT_CLICK) {
    
        // x = lparam, y = dparam
        
        datetime click_time;
        double price;
        int window = 0;
        
        if (ChartXYToTimePrice(0, (int)lparam, (int)dparam, window, click_time, price)) {
            if (first_click == NULL && second_click == NULL) {
                Clear();
                first_click = click_time;
                ObjectCreate(ObjectLabel+"first_click", OBJ_VLINE, 0, first_click, 0);
            }
            else if (first_click != NULL && second_click == NULL) {
                second_click = click_time;
                ObjectCreate(ObjectLabel+"second_click", OBJ_VLINE, 0, second_click, 0);
                
                double BandSize = (WindowPriceMax() - WindowPriceMin()) / NumOfBands; // scale bands
                
                int maximum_count;
                
                maximum_count = CalculateBands(first_click, second_click);
                for (int i=0; i < NumOfBands; i ++) {
                    if (InternalBuffer[i] > 0) {
                        CreateBlock(i, InternalBuffer[i], maximum_count, first_click, second_click);
                    }
                }
                ChartRedraw();
                first_click = NULL;
                second_click = NULL;
            }
        }
       
    }

}


int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[],
                const double &high[], const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) { 
    //CalculateBands();
    return rates_total;
}

void OnDeinit(const int reason) {
    Clear();
}