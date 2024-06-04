#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


class MyCustomRectangle {
    public:
        string objectName;
        int firstAnchorIndexPoint;
        int secondAnchorIndexPoint;
        int highIndex;
        int lowIndex;
        double lowPrice;
        double highPrice;
        bool rectType;
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
    lastHighestIndex = lastLowestIndex = numOfBarsToCalculate = lastFirstAnchorPoint = lastSecondAnchorPoint = 20;
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
    MyCustomRectangle myCustomRectangle = rectangles[currentRect];
    if(myCustomRectangle.objectName == NULL) {
        rectangles[currentRect].objectName = "Rectangle" + currentRect;
        rectangles[currentRect].firstAnchorIndexPoint = lastFirstAnchorPoint;
        rectangles[currentRect].secondAnchorIndexPoint = lastSecondAnchorPoint;
        rectangles[currentRect].highIndex = lastHighestIndex;
        rectangles[currentRect].lowIndex = lastLowestIndex;
        rectangles[currentRect].lowPrice = Low[lastLowestIndex];
        rectangles[currentRect].highPrice = High[lastHighestIndex];
        ObjectCreate(rectangles[currentRect].objectName , OBJ_RECTANGLE, 0, Time[rectangles[currentRect].firstAnchorIndexPoint], Low[rectangles[currentRect].lowIndex], Time[rectangles[currentRect].secondAnchorIndexPoint], High[rectangles[currentRect].highIndex]);
    }
}

void calculate(int index) {
    double low = Low[index];
    double high = High[index];

    MyCustomRectangle myCustomRectangle = rectangles[currentRect];

    bool isCurrentLowGreaterThanRectLow = false;
    bool isCurrentLowLessThanRectLow = false;
    bool isCurrentHighGreaterThanRectHigh = false;
    bool isCurrentHighLessThanRectHigh = false;




    if(low > myCustomRectangle.lowPrice) {
        isCurrentLowGreaterThanRectLow = true;
    }

    if(low < myCustomRectangle.lowPrice) {
        isCurrentLowLessThanRectLow = true;
    }

    if(high > myCustomRectangle.highPrice) {
        isCurrentHighGreaterThanRectHigh = true;
    }

    if(high < myCustomRectangle.highPrice) {
        isCurrentHighLessThanRectHigh = true;
    }

    if(isCurrentLowGreaterThanRectLow && isCurrentHighGreaterThanRectHigh) {
        ObjectSet(myCustomRectangle.objectName, OBJPROP_TIME2, Time[index]);
    }

    if(isCurrentLowGreaterThanRectLow && isCurrentHighLessThanRectHigh) {
        ObjectSet(myCustomRectangle.objectName, OBJPROP_TIME2, Time[index]);
        ObjectSet(myCustomRectangle.objectName, OBJPROP_PRICE2, High[index]);
        myCustomRectangle.highPrice = High[index];
        myCustomRectangle.highIndex = index;
    }

    // ObjectCreate("Rectangle", OBJ_RECTANGLE, 0, Time[lastFirstAnchorPoint], High[lastHighestIndex], Time[lastSecondAnchorPoint], Low[lastLowestIndex]);
}