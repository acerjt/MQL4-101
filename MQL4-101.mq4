#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>


enum SESSION  {
    ASIA,
    EUROPE,
    AMERICA,
    PACIFIC
};

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
        double candleHeigh;
};


class Zone {
    public:
        static Zone* instance;
        Zone() {
            isZeroChartClick = false;
            isFirstChartClick = false;
            isSecondChartClick = false;
        }
    public:
        string objectName;
        datetime firstDate;
        datetime secondDate;
        double firstPrice;
        double secondPrice;
        string rectType;
        bool isZeroChartClick;
        bool isFirstChartClick;
        bool isSecondChartClick;


    public:
        static Zone * getInstance() {
            if (!instance) instance = new Zone();
                return instance;
        }   
        static void Release() {
            delete instance;
            instance = NULL;
    }
};

class Session {
    public:
        datetime openSession;
        datetime closeSession;
        double sessionLowestPrice;
        double sessionHighestPrice;
        string name;
        int sessionColor;
        int count;
        int shift;
        Session() {
        }


        void createSessionZone(SESSION session) {
            datetime Today = TimeCurrent() - (TimeCurrent() % (PERIOD_D1 * 60));  // Today at midnight
            switch (session) {
                case ASIA:
                    this.openSession = Today + 3600 * 9;
                    this.closeSession = Today + 3600 * 16;
                    this.count = Bars(symbol, period, openSession, closeSession);
                    this.shift = iBarShift(symbol,period, closeSession);
                    this.sessionHighestPrice = iHighest(symbol,period,MODE_HIGH,count,shift);
                    this.sessionLowestPrice = iLowest(symbol,period,MODE_HIGH,count,shift);
                    this.name = "ASIA_SESSION";
                    this.sessionColor = 62768;
                break;
                ObjectDelete(this.name);
                ObjectCreate(handle, this.name , OBJ_RECTANGLE, 0, this.openSession, this.sessionLowestPrice, this.closeSession, this.sessionHighestPrice);
                ObjectSet(this.name, OBJPROP_COLOR, this.sessionColor);
            }
        }
};

Zone * Zone::instance = NULL; 

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
string symbol = NULL;
int period  = PERIOD_M15;
string drawSellZoneButton="drawSellZoneButton";
bool isClickedSellBtn = false;
string drawBuyZoneButton="drawBuyZoneButton";
bool isClickedBuyBtn = false;
int broadcastEventID=5000;
Session asia;
bool isMetQuansimodo = false;
bool isOrder = true;

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
        ChartSetSymbolPeriod(handle, symbol, period);
        //ChartRedraw(handle);
    }
}

bool checkNewDate() {
    bool isNewDay = false;
    int dow = TimeDayOfWeek(Time[0]);
    static int day;
    
    if (dow != day)
    {
        isNewDay = true;
    }
    else 
    {
        dow = day;
    }
    return isNewDay;
}

int OnInit() {
    ChartConfig();
    //LoadTemplate();
    CreateButtonForDrawZone();
    int bars = Bars(symbol, period) - 2;
    lastHighestIndex = lastLowestIndex = numOfBarsToCalculate = lastFirstAnchorPoint = lastSecondAnchorPoint = bars;
    createRectangle();


    for(int i = bars; i > 0; i--) {
        calculate(i);
    }

    bool isNewBar = NewBar();
    
    return(INIT_SUCCEEDED);
}



void OnDeinit(const int reason) {
    ObjectsDeleteAll(handle,0,OBJ_RECTANGLE);
    Zone::Release();
}

void OnTick() {
    

    // double sellZonePrice1 = ObjectGet("SELLZONE", OBJPROP_PRICE1);   
    // double sellZonePrice2 = ObjectGet("SELLZONE", OBJPROP_PRICE2);   
    // double sellZoneFloorPrice = sellZonePrice1 < sellZonePrice2 ? sellZonePrice1 : sellZonePrice2;

    // double buyZonePrice1 = ObjectGet("BUYZONE", OBJPROP_PRICE1);   
    // double buyZonePrice2 = ObjectGet("BUYZONE", OBJPROP_PRICE2);   
    // double buyZoneCeilPrice = buyZonePrice1 > buyZonePrice2 ? buyZonePrice1 : buyZonePrice2;

    bool isNewBar = NewBar();
    if(isNewBar) {
        //for(int i = 0; i < currentRect + 1; i++) {
        //    rectangles[currentRect].firstAnchorIndexPoint +=1 ;
        //    rectangles[currentRect].secondAnchorIndexPoint += 1;
        //    rectangles[currentRect].highestIndex += 1;
        //    rectangles[currentRect].lowestIndex += 1;
        //    rectangles[currentRect].lastHighIndex += 1;
        //    rectangles[currentRect].lastLowIndex += 1;
        //}
        calculate(1);
    }
    if(Hour()>=16 && Hour()<20) {
        bool isNewDay = checkNewDate();
        if(isNewDay) {
            asia.createSessionZone(SESSION::ASIA);
            isOrder = true;
            isMetQuansimodo = false;
        }
        string rectA = rectangles[currentRect - 2].rectType;
        string rectB = rectangles[currentRect - 1].rectType;
        string rectC = rectangles[currentRect].rectType;
        
        double lengthA = rectangles[currentRect - 2].candleHeigh;
        double lengthB = rectangles[currentRect - 1].candleHeigh;
        double lengthC = rectangles[currentRect].candleHeigh;

        if(rectA == "BuyBias" && rectB == "SellBias" && rectC == "BuyBias") {
            if(lengthA < lengthB && lengthC > lengthB) {
                isMetQuansimodo = true;
                if(isMetQuansimodo && isOrder) {
                    if(isNewBar && Close[1] > asia.sessionHighestPrice) {
                        double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
                        double price=Bid;
                        //--- calculated SL and TP prices must be normalized
                        double stoploss=NormalizeDouble(Ask-minstoplevel*Point,Digits);
                        double takeprofit=NormalizeDouble(Ask+minstoplevel*Point,Digits);
                        //--- place market order to buy 1 lot
                        int ticket=OrderSend(Symbol(),OP_BUY,1,price,3,stoploss,takeprofit,"My order",16384,0,clrGreen);
                        isOrder = false;
                    }
                }
            }
        } else if(rectA == "SellBias" && rectB == "BuyBias" && rectC == "SellBias") {
            if(lengthA < lengthB && lengthC > lengthB) {
                isMetQuansimodo = true;
                if(isMetQuansimodo && isOrder) {
                    if(isNewBar && Close[1] < asia.sessionLowestPrice) {
                        double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
                        double price=Ask;
                        //--- calculated SL and TP prices must be normalized
                        double stoploss=NormalizeDouble(Bid-minstoplevel*Point,Digits);
                        double takeprofit=NormalizeDouble(Bid+minstoplevel*Point,Digits);
                        //--- place market order to buy 1 lot
                        int ticket=OrderSend(Symbol(),OP_BUY,1,price,3,stoploss,takeprofit,"My order",16384,0,clrGreen);
                        isOrder = false;
                    }
                }
            }
        }
    }
    ChartRedraw();
}


void CreateButtonForDrawZone() {
//--- Create a button to send custom events
    ObjectCreate(handle, drawSellZoneButton,OBJ_BUTTON,0,0,0);
    ObjectSetInteger(handle,drawSellZoneButton,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
    ObjectSetInteger(handle,drawSellZoneButton,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
    ObjectSetInteger(handle, drawSellZoneButton,OBJPROP_XSIZE,100);
    ObjectSetInteger(handle, drawSellZoneButton,OBJPROP_YSIZE,30);
    ObjectSetInteger(handle,drawSellZoneButton,OBJPROP_XDISTANCE,100);
    ObjectSetInteger(handle,drawSellZoneButton,OBJPROP_YDISTANCE,20);
    ObjectSetString(handle, drawSellZoneButton,OBJPROP_FONT,"Arial");
    ObjectSetString(handle, drawSellZoneButton,OBJPROP_TEXT,"SELL ZONE");
    ObjectSetInteger(handle, drawSellZoneButton,OBJPROP_FONTSIZE,10);
    ObjectSetInteger(handle, drawSellZoneButton,OBJPROP_SELECTABLE,0);
    ObjectSetInteger(handle, drawSellZoneButton,OBJPROP_COLOR,clrWhite);
    ObjectSetInteger(handle, drawSellZoneButton,OBJPROP_BGCOLOR,clrRed);
    
    ObjectCreate(handle, drawBuyZoneButton,OBJ_BUTTON,0,0,0);
    ObjectSetInteger(handle,drawBuyZoneButton,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
    ObjectSetInteger(handle,drawBuyZoneButton,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
    ObjectSetInteger(handle, drawBuyZoneButton,OBJPROP_XSIZE,100);
    ObjectSetInteger(handle, drawBuyZoneButton,OBJPROP_YSIZE,30);
    ObjectSetInteger(handle,drawBuyZoneButton,OBJPROP_XDISTANCE,100);
    ObjectSetInteger(handle,drawBuyZoneButton,OBJPROP_YDISTANCE,60);
    ObjectSetString(handle, drawBuyZoneButton,OBJPROP_FONT,"Arial");
    ObjectSetString(handle, drawBuyZoneButton,OBJPROP_TEXT,"BUY ZONE");
    ObjectSetInteger(handle, drawBuyZoneButton,OBJPROP_FONTSIZE,10);
    ObjectSetInteger(handle, drawBuyZoneButton,OBJPROP_SELECTABLE,0);
    ObjectSetInteger(handle, drawBuyZoneButton,OBJPROP_COLOR,clrWhite);
    ObjectSetInteger(handle, drawBuyZoneButton,OBJPROP_BGCOLOR,clrTeal);
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
        rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
        ObjectCreate(handle, rectangles[currentRect].objectName , OBJ_RECTANGLE, 0, Time[rectangles[currentRect].firstAnchorIndexPoint], Low[rectangles[currentRect].lowestIndex], Time[rectangles[currentRect].secondAnchorIndexPoint], High[rectangles[currentRect].highestIndex]);
        ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrDeepSkyBlue);
        //ChartRedraw(handle);
    }
}

void mergeRect() {
    return;
    if(currentRect == 0)
        return;

    bool isMetLow = false;
    bool isMetHigh = false;

    if(rectangles[currentRect].rectType == rectangles[currentRect - 1].rectType) {
        if(rectangles[currentRect].lowestPrice < rectangles[currentRect - 1].lowestPrice) {
            rectangles[currentRect - 1].lowestIndex = rectangles[currentRect].lowestIndex;
            rectangles[currentRect - 1].lowestPrice = rectangles[currentRect].lowestPrice;
            rectangles[currentRect - 1].secondAnchorIndexPoint = rectangles[currentRect].secondAnchorIndexPoint;
            rectangles[currentRect - 1].lastLowPrice = rectangles[currentRect].lastLowPrice;
            rectangles[currentRect - 1].lastHighPrice = rectangles[currentRect].lastHighPrice;
            rectangles[currentRect - 1].candleHeigh = rectangles[currentRect - 1].highestPrice - rectangles[currentRect - 1].lowestPrice;
            ObjectDelete(rectangles[currentRect].objectName);
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_PRICE1, Low[rectangles[currentRect - 1].lowestIndex]);
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_TIME2, Time[rectangles[currentRect - 1].secondAnchorIndexPoint]);
            isMetLow = true;
        }

        if(rectangles[currentRect].highestPrice > rectangles[currentRect - 1].highestPrice) {
            rectangles[currentRect - 1].highestIndex = rectangles[currentRect].highestIndex;
            rectangles[currentRect - 1].highestPrice = rectangles[currentRect].highestPrice;
            rectangles[currentRect - 1].secondAnchorIndexPoint = rectangles[currentRect].secondAnchorIndexPoint;
            rectangles[currentRect - 1].lastLowPrice = rectangles[currentRect].lastLowPrice;
            rectangles[currentRect - 1].lastHighPrice = rectangles[currentRect].lastHighPrice;
            rectangles[currentRect - 1].candleHeigh = rectangles[currentRect - 1].highestPrice - rectangles[currentRect - 1].lowestPrice;
            ObjectDelete(rectangles[currentRect].objectName);
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_PRICE2, High[rectangles[currentRect - 1].highestIndex]);
            ObjectSet(rectangles[currentRect - 1].objectName, OBJPROP_TIME2, Time[rectangles[currentRect - 1].secondAnchorIndexPoint]);
            isMetHigh = true;
        }

        if(isMetHigh || isMetLow) {
            rectangles[currentRect].objectName = NULL;
            rectangles[currentRect].rectType = NULL;  
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
        // current candle higher than current rect
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            rectangles[currentRect].secondAnchorIndexPoint = index;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
        }


        // current candle lower than current rect
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            mergeRect();
            currentRect++;
            lastHighestIndex = index + 1;
            lastSecondAnchorPoint  = index;
            lastLowestIndex = index;
            lastFirstAnchorPoint = index + 1;
            createRectangle();
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            rectangles[currentRect].rectType = "SellBias";
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrRed);
        }

        // current candle inner current rect
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighLessThanRectHighest) {    
            // current candle greater than current rect last candle 
            if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
                rectangles[currentRect].secondAnchorIndexPoint = index;
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            }

            // current candle less than current rect last candle 
            if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
                mergeRect();
                currentRect++;
                lastHighestIndex = index + 1;
                lastSecondAnchorPoint  = index;
                lastLowestIndex = index;
                lastFirstAnchorPoint = index + 1;
                createRectangle();
                rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
                rectangles[currentRect].rectType = "SellBias";
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrRed);
            }

            if(isCurrentLowGreaterThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
                rectangles[currentRect].secondAnchorIndexPoint = index;
            }

            if(isCurrentLowLessThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
                rectangles[currentRect].secondAnchorIndexPoint = index;
            }
        }

        // current candle outer current rect
        if(isCurrentLowLessThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            rectangles[currentRect].secondAnchorIndexPoint = index;
        }

    } else if(rectangles[currentRect].rectType == "SellBias") {
         // current candle higher than current rect
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            mergeRect();
            currentRect++;
            lastHighestIndex = index;
            lastSecondAnchorPoint  = index;
            lastLowestIndex = index + 1;
            lastFirstAnchorPoint = index + 1;
            createRectangle();
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            rectangles[currentRect].rectType = "BuyBias";
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrTeal);
        }


         // current candle lower than current rect
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            rectangles[currentRect].secondAnchorIndexPoint = index;
        }

        // current candle inner current rect
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighLessThanRectHighest) {    
            // current candle greater than current rect last candle 
            if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
                mergeRect();
                currentRect++;
                lastHighestIndex = index;
                lastSecondAnchorPoint  = index;
                lastLowestIndex = index + 1;
                lastFirstAnchorPoint = index + 1;
                createRectangle();
                rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
                rectangles[currentRect].rectType = "BuyBias";
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrTeal);
            }

            // current candle less than current rect last candle 
            if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
                rectangles[currentRect].lowestPrice = Low[index];
                rectangles[currentRect].lowestIndex = index;
                rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
                rectangles[currentRect].secondAnchorIndexPoint = index;
            }

            if(isCurrentLowGreaterThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
                rectangles[currentRect].secondAnchorIndexPoint = index;
            }

            if(isCurrentLowLessThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
                rectangles[currentRect].secondAnchorIndexPoint = index;
            }
        }

        // current candle outer current rect
        if(isCurrentLowLessThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            rectangles[currentRect].secondAnchorIndexPoint = index;
        }
    } else {
        // current candle higher than current rect
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            rectangles[currentRect].rectType = "BuyBias";
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            rectangles[currentRect].secondAnchorIndexPoint = index;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrTeal);
        }


        // current candle lower than current rect
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            rectangles[currentRect].rectType = "SellBias";
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            rectangles[currentRect].secondAnchorIndexPoint = index;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrRed);
        }


        // current candle inner current rect
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighLessThanRectHighest) {    
            // current candle greater than current rect last candle 
            if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
                rectangles[currentRect].rectType = "BuyBias";
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
                rectangles[currentRect].secondAnchorIndexPoint = index;
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrTeal);
            }

            // current candle less than current rect last candle 
            if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
                rectangles[currentRect].rectType = "SellBias";
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
                rectangles[currentRect].secondAnchorIndexPoint = index;
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrRed);
            }

            if(isCurrentLowGreaterThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
                rectangles[currentRect].secondAnchorIndexPoint = index;
            }

            if(isCurrentLowLessThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
                ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);    
                rectangles[currentRect].secondAnchorIndexPoint = index;
            }
        }

        // current candle outer current rect
        if(isCurrentLowLessThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
            rectangles[currentRect].candleHeigh = rectangles[currentRect].highestPrice - rectangles[currentRect].lowestPrice;
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            rectangles[currentRect].secondAnchorIndexPoint = index;
        }
    }

    if(!(isCurrentLowLessThanRectLowest && isCurrentHighGreaterThanRectHighest)) {
        rectangles[currentRect].lastHighPrice = High[index];
        rectangles[currentRect].lastHighIndex = index;
        rectangles[currentRect].lastLowPrice = Low[index];
        rectangles[currentRect].lastLowIndex = index;
    }
    
    // ObjectCreate("Rectangle", OBJ_RECTANGLE, 0, Time[lastFirstAnchorPoint], High[lastHighestIndex], Time[lastSecondAnchorPoint], Low[lastLowestIndex]);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
//--- Check the event by pressing a mouse button
    if(id==CHARTEVENT_OBJECT_CLICK) {
        string clickedChartObject=sparam;
        //--- If you click on the object with the name drawSellZoneButton
        if(clickedChartObject==drawSellZoneButton) {
            //--- State of the button - pressed or not
            isClickedSellBtn=ObjectGetInteger(0,drawSellZoneButton,OBJPROP_STATE);
            //--- log a debug message
            int customEventID; // Number of the custom event to send
            string message;    // Message to be sent in the event
            //ObjectCreate(handle, "SellZone" , OBJ_RECTANGLE, 0, Time[0], Low[0], Time[30], High[iHighest(symbol,period,MODE_HIGH,20,0)]);
                //--- If the button is pressed
                //  if(selected)
                //    {
                //     message="Button pressed";
                //     customEventID=CHARTEVENT_CUSTOM+1;
                //    }
                //  else // Button is not pressed
                //    {
                //     message="Button in not pressed";
                //     customEventID=CHARTEVENT_CUSTOM+999;
                //    }
                //--- Send a custom event "our" chart
                //EventChartCustom(0,customEventID-CHARTEVENT_CUSTOM,0,0,message);
                ///--- Send a message to all open charts
                //BroadcastEvent(ChartID(),0,"Broadcast Message");
                //--- Debug message
                //Print("Sent an event with ID = ",customEventID);

                
        }
        if(clickedChartObject==drawBuyZoneButton) {
            //--- State of the button - pressed or not
            isClickedBuyBtn=ObjectGetInteger(0,drawBuyZoneButton,OBJPROP_STATE);
            //--- log a debug message
            int customEventID; // Number of the custom event to send
            string message;    // Message to be sent in the event
            //ObjectCreate(handle, "SellZone" , OBJ_RECTANGLE, 0, Time[0], Low[0], Time[30], High[iHighest(symbol,period,MODE_HIGH,20,0)]);
                //--- If the button is pressed
                //  if(selected)
                //    {
                //     message="Button pressed";
                //     customEventID=CHARTEVENT_CUSTOM+1;
                //    }
                //  else // Button is not pressed
                //    {
                //     message="Button in not pressed";
                //     customEventID=CHARTEVENT_CUSTOM+999;
                //    }
                //--- Send a custom event "our" chart
                //EventChartCustom(0,customEventID-CHARTEVENT_CUSTOM,0,0,message);
                ///--- Send a message to all open charts
                //BroadcastEvent(ChartID(),0,"Broadcast Message");
                //--- Debug message
                //Print("Sent an event with ID = ",customEventID);

                
        }
        ChartRedraw();// Forced redraw all chart objects
        return;
    }

//--- Check the event belongs to the user events


    //if(id == CHARTEVENT_OBJECT_DRAG) {
    //    Print("Drag object",lparam);
    //}

    if(id==CHARTEVENT_CLICK) {
        //--- Prepare variables
        int      x     =(int)lparam;
        int      y     =(int)dparam;
        datetime dt    =0;
        double   price =0;
        int      window=0;
        //--- Convert the X and Y coordinates in terms of date/time
        if(isClickedSellBtn) {
            Zone::instance = Zone::getInstance();
            if(!Zone::instance.isZeroChartClick) {
                Zone::instance.isZeroChartClick = true;
            } else if(!Zone::instance.isFirstChartClick) {
                if(ChartXYToTimePrice(0,x,y,window,dt,price)) {
                    Zone::instance.firstDate = dt;
                    Zone::instance.firstPrice = price;
                }
                Zone::instance.isFirstChartClick = true;
            } else if(!Zone::instance.isSecondChartClick) {
                if(ChartXYToTimePrice(0,x,y,window,dt,price)) {
                    Zone::instance.secondDate = dt;
                    Zone::instance.secondPrice = price;
                }
                Zone::instance.isSecondChartClick = true;
            }

            if(Zone::instance.isFirstChartClick && Zone::instance.isSecondChartClick) {
                ObjectCreate(handle, "SELLZONE", OBJ_RECTANGLE, 0, Zone::instance.firstDate, Zone::instance.firstPrice, Zone::instance.secondDate, Zone::instance.secondPrice);
                ObjectSetInteger(handle, drawSellZoneButton ,OBJPROP_STATE, false);
                ObjectSet("SELLZONE", OBJPROP_COLOR, clrMaroon);
                isClickedSellBtn = false;
                Zone::Release();
                ChartRedraw();
            }
        }
        
        if(isClickedBuyBtn) {
            Zone::instance = Zone::getInstance();
            if(!Zone::instance.isZeroChartClick) {
                Zone::instance.isZeroChartClick = true;
            } else if(!Zone::instance.isFirstChartClick) {
                if(ChartXYToTimePrice(0,x,y,window,dt,price)) {
                    Zone::instance.firstDate = dt;
                    Zone::instance.firstPrice = price;
                }
                Zone::instance.isFirstChartClick = true;
            } else if(!Zone::instance.isSecondChartClick) {
                if(ChartXYToTimePrice(0,x,y,window,dt,price)) {
                    Zone::instance.secondDate = dt;
                    Zone::instance.secondPrice = price;
                }
                Zone::instance.isSecondChartClick = true;
            }

            if(Zone::instance.isFirstChartClick && Zone::instance.isSecondChartClick) {
                ObjectCreate(handle, "BUYZONE", OBJ_RECTANGLE, 0, Zone::instance.firstDate, Zone::instance.firstPrice, Zone::instance.secondDate, Zone::instance.secondPrice);
                ObjectSetInteger(handle, drawSellZoneButton ,OBJPROP_STATE, false);
                ObjectSet("BUYZONE", OBJPROP_COLOR, clrMediumAquamarine);
                isClickedBuyBtn = false;
                Zone::Release();
                ChartRedraw();
            }
        }
        Print("+--------------------------------------------------------------+");
    }


    if(id>CHARTEVENT_CUSTOM) {
    //   if(id==broadcastEventID)
    //     {
    //      Print("Got broadcast message from a chart with id = "+lparam);
    //     }
    //   else
    //     {
    //      //--- We read a text message in the event
    //      string info=sparam;
    //      Print("Handle the user event with the ID = ",id);
    //      //--- Display a message in a label
    //      ObjectSetString(0,labelID,OBJPROP_TEXT,sparam);
    //      ChartRedraw();// Forced redraw all chart objects
    //     }
    }
}

void BroadcastEvent(long lparam,double dparam,string sparam) {
    int eventID=broadcastEventID-CHARTEVENT_CUSTOM;
    long currChart=ChartFirst();
    int i=0;
    while(i<CHARTS_MAX) {                 // We have certainly no more than CHARTS_MAX open charts 
        EventChartCustom(currChart,eventID,lparam,dparam,sparam);
        currChart=ChartNext(currChart); // We have received a new chart from the previous
        if(currChart==-1) break;        // Reached the end of the charts list
        i++;// Do not forget to increase the counter
    }
}


bool NewBar() {
    static datetime lastbar;
    datetime curbar = Time[0];
    if(lastbar!=curbar) {
        lastbar=curbar;
        return (true);
    } else {
        return(false);
    }
}
