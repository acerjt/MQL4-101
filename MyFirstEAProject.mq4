//+------------------------------------------------------------------+
//|                                             MyFirstEAProject.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
   
   lastHighestIndex = lastLowestIndex = numOfBarsToCalculate = lastFirstAnchorPoint = lastSecondAnchorPoint = 400;



   double lowestPrice = Low[lastLowestIndex];
   double highestPrice = High[lastHighestIndex];
   ObjectDelete("Rectangle");
   ObjectCreate("Rectangle", OBJ_RECTANGLE, 0, Time[lastFirstAnchorPoint], High[lastHighestIndex], Time[lastSecondAnchorPoint], Low[lastLowestIndex]);
   

   int bars = Bars(_Symbol, PERIOD_H1, startDate, stopDate);
   
   for(int i = numOfBarsToCalculate - 1; i > -1; i--) {
      double low = Low[i];
      double high = High[i];
      
      if(low <= lowestPrice) {
         lastLowestIndex = i;
         lowestPrice = low;
         isRedraw = true;
      }
      
      if(high >= highestPrice) {
         lastHighestIndex = i;
         highestPrice = high;
         isRedraw = true;
      }
      lastFirstAnchorPoint = i;
      
      
      ObjectCreate("Rectangle", OBJ_RECTANGLE, 0, Time[lastFirstAnchorPoint], High[lastHighestIndex], Time[lastSecondAnchorPoint], Low[lastLowestIndex]);
   }

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
void OnTick()
  {
 
  }
//+------------------------------------------------------------------+
int getCurrentRectangle() {
   
}