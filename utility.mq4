//+------------------------------------------------------------------+
//|                                                      Utiilty.mq4 |
//|                                          Copyright 2021,satriyop |
//|                                        https://www.enterkode.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,satriyop"
#property link      "https://www.enterkode.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   
  }
//+------------------------------------------------------------------+


int compareDouble(double aDouble, double bDouble, int precision)
{
   double point = MathPow(10, -precision);
   
   int aInt = (int) aDouble/point;
   int bInt = (int) bDouble/point;
   
   if (aInt > bInt)        return 1;
   else if (aInt < bInt)   return -1;
   
   return 0;
}


double getPipValueFromDigits()
{
   if (_Digits >= 4) {
      // it is not trading Japanese Yen
      return 0.0001;
   
   } else {
      // it is a japanese yen pair
      return 0.01;
   }
}

double getStopLossPrice(bool isLongPosition, double entryPrice, int maxLossInPips)
{
   double stopLossPrice;
   
   if (isLongPosition) {
      // expect price will goes up. 
      // Stop loss when lower than entry price at x PIPs
      stopLossPrice = entryPrice - ( maxLossInPips * 0.0001 );
      
   } else {
      // then it is a sell / short position, expect profit at lower
      // stop loss will be higher than entry price at x PIPs
      stopLossPrice = entryPrice + ( maxLossInPips * 0.0001 );
   }
   
   return stopLossPrice; 
}

double getTakeProfitPrice(bool isLongPosition, double entryPrice, int profitInPips)
{
   double takeProfit;
   
   if (isLongPosition) 
   {
      // entry Price is Ask
      // double entryPrice = Ask;
      takeProfit = entryPrice + profitInPips * 0.0001;
      
   } else 
   {
      // entry Price is Bid
      // double entryPrice = Bid;
      takeProfit = entryPrice - profitInPips * 0.0001;
   }
   
   return takeProfit;
}