#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>


class MyCustomRectangle {
    public:
        string objectName;
        int firstAnchorIndexPoint;
        int secondAnchorIndexPoint;
        int highestIndex;
        int lowestIndex;
        double lowestPrice;
        double highestPrice;
        int lastHighIndex;
        int lastLowIndex;
        double lastLowPrice;
        double lastHighPrice;
        string rectType;
};


datetime startDate=D'01.06.2004';     
datetime stopDate=D'04.06.2004';  

int lastHighestIndex;
int lastLowestIndex;
int numOfBarsToCalculate;
bool isRedraw = false;
bool isMerge = false;
int currentRect = 0;
int numOfRect = 0;
int lastFirstAnchorPoint;
int lastSecondAnchorPoint;
MyCustomRectangle rectangles[100000];
double lowestPrice = Low[lastLowestIndex];
double highestPrice = High[lastHighestIndex];
long handle = ChartID();

void ChartConfig() {
    
    if(handle > 0) {
        //--- Disable autoscroll
        ChartSetInteger(handle,CHART_AUTOSCROLL,false);
        //--- Set the indent of the right border of the chart
        ChartSetInteger(handle,CHART_SHIFT,true);
        //--- Display as candlesticks
        ChartSetInteger(handle,CHART_MODE,CHART_CANDLES);
        // //--- Scroll by 100 bars from the beginning of history
        // ChartNavigate(handle,CHART_CURRENT_POS,100);
        // //--- Set the tick volume display mode
        // ChartSetInteger(handle,CHART_SHOW_VOLUMES,CHART_VOLUME_TICK);
        ChartSetInteger(handle,CHART_SHOW_GRID,false);
    }
}


int OnInit() {
    ChartConfig();
    LoadTemplate();
    int bars = Bars(_Symbol, PERIOD_H1) - 1;
    bars= 200;
    lastHighestIndex = lastLowestIndex = numOfBarsToCalculate = lastFirstAnchorPoint = lastSecondAnchorPoint = bars;
    createRectangle();



    for(int i = bars - 1; i > -1; i--) {
        calculate(i);
    }
    
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {

}


void LoadTemplate() {
    if(FileIsExist("Tradingview Blue.tpl"))
        {
        Print("The file Tradingview Blue.tpl found in \Files'");
        if(ChartApplyTemplate(handle,"Tradingview Blue.tpl"))
        {
            Print("The template 'Tradingview Blue.tpl' applied successfully");
        }
        else
            Print("Failed to apply 'Tradingview Blue.tpl', error code ",GetLastError());
        }
    else
        {
            Print("File 'Tradingview Blue.tpl' not found in " + TerminalInfoString(TERMINAL_PATH)+"\\MQL4\\Files");
        }
}

void createRectangle() {
    if(rectangles[currentRect].objectName == NULL) {
        rectangles[currentRect].objectName = "Rectangle" + currentRect;
        rectangles[currentRect].firstAnchorIndexPoint = lastFirstAnchorPoint;
        rectangles[currentRect].secondAnchorIndexPoint = lastSecondAnchorPoint;
        rectangles[currentRect].highestIndex = lastHighestIndex;
        rectangles[currentRect].lowestIndex = lastLowestIndex;
        rectangles[currentRect].lowestPrice = Low[lastLowestIndex];
        rectangles[currentRect].highestPrice = High[lastHighestIndex];
        rectangles[currentRect].lastHighIndex = lastHighestIndex;
        rectangles[currentRect].lastLowIndex = lastLowestIndex;
        rectangles[currentRect].lastLowPrice = Low[lastLowestIndex];
        rectangles[currentRect].lastHighPrice = High[lastHighestIndex];
        ObjectCreate(rectangles[currentRect].objectName , OBJ_RECTANGLE, 0, Time[rectangles[currentRect].firstAnchorIndexPoint], Low[rectangles[currentRect].lowestIndex], Time[rectangles[currentRect].secondAnchorIndexPoint], High[rectangles[currentRect].highestIndex]);
    }
}

void mergeRect() {
    // return;
    if(currentRect == 0)
        return;

    bool isMetLow = false;
    bool isMetHigh = false;

    if(rectangles[currentRect].rectType == rectangles[currentRect - 1].rectType && rectangles[currentRect].rectType == "SellBias") {
        if(rectangles[currentRect].lowestPrice < rectangles[currentRect - 1].lowestPrice) {
            rectangles[currentRect - 1].lowestIndex = rectangles[currentRect].lowestIndex;
            rectangles[currentRect - 1].lowestPrice = rectangles[currentRect].lowestPrice;
            rectangles[currentRect - 1].secondAnchorIndexPoint = rectangles[currentRect].secondAnchorIndexPoint;
            rectangles[currentRect - 1].lastLowPrice = rectangles[currentRect].lastLowPrice;
            rectangles[currentRect - 1].lastHighPrice = rectangles[currentRect].lastHighPrice;
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_TIME2, Time[rectangles[currentRect - 1].secondAnchorIndexPoint]);
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_PRICE1, Low[rectangles[currentRect - 1].lowestIndex]);
            isMetLow = true;
        }

        if(rectangles[currentRect].lowestPrice > rectangles[currentRect - 1].lowestPrice) {
            rectangles[currentRect - 1].secondAnchorIndexPoint = rectangles[currentRect].secondAnchorIndexPoint;
            rectangles[currentRect - 1].lastLowPrice = rectangles[currentRect].lastLowPrice;
            rectangles[currentRect - 1].lastHighPrice = rectangles[currentRect].lastHighPrice;
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_TIME2, Time[rectangles[currentRect - 1].secondAnchorIndexPoint]);
            isMetLow = true;
        }

        if(rectangles[currentRect].highestPrice > rectangles[currentRect - 1].highestPrice) {
            rectangles[currentRect - 1].highestIndex = rectangles[currentRect].highestIndex;
            rectangles[currentRect - 1].highestPrice = rectangles[currentRect].highestPrice;
            rectangles[currentRect - 1].secondAnchorIndexPoint = rectangles[currentRect].secondAnchorIndexPoint;
            rectangles[currentRect - 1].lastLowPrice = rectangles[currentRect].lastLowPrice;
            rectangles[currentRect - 1].lastHighPrice = rectangles[currentRect].lastHighPrice;
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_TIME2, Time[rectangles[currentRect - 1].secondAnchorIndexPoint]);
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_PRICE2, High[rectangles[currentRect - 1].highestIndex]);
            isMetHigh = true;
        }

        
        if(isMetHigh || isMetLow) {
            currentRect--;
        }
    }
}

void calculate(int index) {
    double low = Low[index];
    double high = High[index];

    bool isCurrentLowGreaterThanRectLowest = false;
    bool isCurrentLowLessThanRectLowest = false;
    bool isCurrentHighGreaterThanRectHighest = false;
    bool isCurrentHighLessThanRectHighest = false;

    bool isCurrentLowGreaterThanRectLastLow = false;
    bool isCurrentLowLessThanRectLastLow = false;
    bool isCurrentHighGreaterThanRectLastHigh = false;
    bool isCurrentHighLessThanRectLastHigh = false;




    if(low > rectangles[currentRect].lowestPrice) {
        isCurrentLowGreaterThanRectLowest = true;
    }

    if(low < rectangles[currentRect].lowestPrice) {
        isCurrentLowLessThanRectLowest = true;
    }

    if(high > rectangles[currentRect].highestPrice) {
        isCurrentHighGreaterThanRectHighest = true;
    }

    if(high < rectangles[currentRect].highestPrice) {
        isCurrentHighLessThanRectHighest = true;
    }


    if(low > rectangles[currentRect].lastLowPrice) {
        isCurrentLowGreaterThanRectLastLow = true;
    }

    if(low < rectangles[currentRect].lastLowPrice) {
        isCurrentLowLessThanRectLastLow = true;
    }

    if(high > rectangles[currentRect].lastHighPrice) {
        isCurrentHighGreaterThanRectLastHigh = true;
    }

    if(high < rectangles[currentRect].lastHighPrice) {
        isCurrentHighLessThanRectLastHigh = true;
    }



    if(rectangles[currentRect].rectType == "BuyBias") {
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            if(isCurrentHighGreaterThanRectHighest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
        }

        if(isCurrentLowGreaterThanRectLowest && isCurrentHighLessThanRectHighest) {
            
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            if(isCurrentLowLessThanRectLowest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            if(isCurrentHighGreaterThanRectHighest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            mergeRect();
            currentRect++;
            lastHighestIndex = lastLowestIndex = lastFirstAnchorPoint = lastSecondAnchorPoint = index;
            createRectangle();
            if(isCurrentLowLessThanRectLowest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    } else  if(rectangles[currentRect].rectType == "SellBias") {
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            mergeRect();
            currentRect++;
            lastHighestIndex = lastLowestIndex = lastFirstAnchorPoint = lastSecondAnchorPoint = index;
            createRectangle();
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            if(isCurrentHighGreaterThanRectHighest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
        }

        if(isCurrentLowGreaterThanRectLowest && isCurrentHighLessThanRectHighest) {
            
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            if(isCurrentLowLessThanRectLowest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            if(isCurrentHighGreaterThanRectHighest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            if(isCurrentLowLessThanRectLowest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    } else {
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            rectangles[currentRect].rectType = "BuyBias";
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            if(isCurrentHighGreaterThanRectHighest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrTeal);
        }

        if(isCurrentLowGreaterThanRectLowest && isCurrentHighLessThanRectHighest) {
            
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            if(isCurrentLowLessThanRectLowest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            if(isCurrentHighGreaterThanRectHighest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            rectangles[currentRect].rectType = "SellBias";
            if(isCurrentLowLessThanRectLowest)
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrRed);
        }
    }

    rectangles[currentRect].lastHighPrice = High[index];
    rectangles[currentRect].lastHighIndex = index;
    rectangles[currentRect].lastLowPrice = Low[index];
    rectangles[currentRect].lastLowIndex = index;
    // ObjectCreate("Rectangle", OBJ_RECTANGLE, 0, Time[lastFirstAnchorPoint], High[lastHighestIndex], Time[lastSecondAnchorPoint], Low[lastLowestIndex]);
}