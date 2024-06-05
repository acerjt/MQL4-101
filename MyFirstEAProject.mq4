#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


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
MyCustomRectangle rectangles[1000];
double lowestPrice = Low[lastLowestIndex];
double highestPrice = High[lastHighestIndex];

int OnInit() {
    lastHighestIndex = lastLowestIndex = numOfBarsToCalculate = lastFirstAnchorPoint = lastSecondAnchorPoint = 1000;
    createRectangle();

    int bars = Bars(_Symbol, PERIOD_H1, startDate, stopDate);

    for(int i = numOfBarsToCalculate - 1; i > -1; i--) {
        calculate(i);
    }
    
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {

}

bool IsExistRectangle() {


    return false;
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
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            rectangles[currentRect].lastHighPrice = High[index];
            rectangles[currentRect].lastHighIndex = index;
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
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            currentRect++;
            lastHighestIndex = lastLowestIndex = lastFirstAnchorPoint = lastSecondAnchorPoint = index;
            createRectangle();
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }

        
        
        // if(isCurrentLowGreaterThanRectLow && isCurrentHighGreaterThanRectHigh) {
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
        //     rectangles[currentRect].highPrice = High[index];
        //     rectangles[currentRect].highIndex = index;
        // }

        // if(isCurrentLowGreaterThanRectLow && isCurrentHighLessThanRectHigh) {
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        // }
    
        // if(isCurrentLowLessThanRectLow && isCurrentHighGreaterThanRectHigh) {
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        //     rectangles[currentRect].highPrice = High[index];
        //     rectangles[currentRect].highIndex = index;
        //     rectangles[currentRect].lowPrice = Low[index];
        //     rectangles[currentRect].lowIndex = index;
        // }
    
        // if(isCurrentLowLessThanRectLow && isCurrentHighLessThanRectHigh) {
        //     currentRect++;
        //     lastHighestIndex = lastLowestIndex = lastFirstAnchorPoint = lastSecondAnchorPoint = index;
        //     createRectangle();
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        //     rectangles[currentRect].lowPrice = Low[index];
        //     rectangles[currentRect].lowIndex = index;
        // }
    } else  if(rectangles[currentRect].rectType == "SellBias") {
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            currentRect++;
            lastHighestIndex = lastLowestIndex = lastFirstAnchorPoint = lastSecondAnchorPoint = index;
            createRectangle();
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
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
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }

        // if(isCurrentLowGreaterThanRectLow && isCurrentHighGreaterThanRectHigh) {
        //     currentRect++;
        //     lastHighestIndex = lastLowestIndex = lastFirstAnchorPoint = lastSecondAnchorPoint = index;
        //     createRectangle();
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
        //     rectangles[currentRect].highPrice = High[index];
        //     rectangles[currentRect].highIndex = index;
        // }

        // if(isCurrentLowGreaterThanRectLow && isCurrentHighLessThanRectHigh) {
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        // }
    
        // if(isCurrentLowLessThanRectLow && isCurrentHighGreaterThanRectHigh) {
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        //     rectangles[currentRect].highPrice = High[index];
        //     rectangles[currentRect].highIndex = index;
        //     rectangles[currentRect].lowPrice = Low[index];
        //     rectangles[currentRect].lowIndex = index;
        // }
    
        // if(isCurrentLowLessThanRectLow && isCurrentHighLessThanRectHigh) {
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
        //     ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        //     rectangles[currentRect].lowPrice = Low[index];
        //     rectangles[currentRect].lowIndex = index;
        // }
    } else {
        if(isCurrentLowGreaterThanRectLowest && isCurrentHighGreaterThanRectHighest) {
            rectangles[currentRect].highestPrice = High[index];
            rectangles[currentRect].highestIndex = index;
        }

        if(isCurrentLowGreaterThanRectLastLow && isCurrentHighGreaterThanRectLastHigh) {
            rectangles[currentRect].rectType = "BuyBias";
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrLightGreen);
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
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE2, High[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
        }
    
        if(isCurrentLowLessThanRectLowest && isCurrentHighLessThanRectHighest) {
            rectangles[currentRect].lowestPrice = Low[index];
            rectangles[currentRect].lowestIndex = index;
        }

        if(isCurrentLowLessThanRectLastLow && isCurrentHighLessThanRectLastHigh) {
            rectangles[currentRect].rectType = "SellBias";
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_PRICE1, Low[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_TIME2, Time[index]);
            ObjectSet(rectangles[currentRect].objectName, OBJPROP_COLOR, clrCrimson);
        }
    }

    rectangles[currentRect].lastHighPrice = High[index];
    rectangles[currentRect].lastHighIndex = index;
    rectangles[currentRect].lastLowPrice = Low[index];
    rectangles[currentRect].lastLowIndex = index;
    // ObjectCreate("Rectangle", OBJ_RECTANGLE, 0, Time[lastFirstAnchorPoint], High[lastHighestIndex], Time[lastSecondAnchorPoint], Low[lastLowestIndex]);
}