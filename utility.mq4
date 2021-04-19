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



// calculate stop loss price based on expected pips
double getStopLossPriceByPips(string symbol, bool isBuy, double entryPrice, int maxLossInPips)
{
   double stopLossPrice;
   
   if (isBuy) { 
      // Stop loss when lower than entry price at x PIPs
      stopLossPrice = entryPrice -  maxLossInPips * MarketInfo(symbol, MODE_POINT);    
      
      
   } else {
      // then it is a sell / short position, expect profit at lower
      // stop loss will be higher than entry price at x PIPs
      stopLossPrice = entryPrice +  maxLossInPips * MarketInfo(symbol, MODE_POINT);
   }
   
   return stopLossPrice; 
}

// calculate take profit price based on expected pips
double getTakeProfitPrice(string symbol, bool isLongPosition, double entryPrice, int profitInPips)
{
   double takeProfit;
   
   if (isLongPosition) 
   {
      // entry Price is Ask
      // double entryPrice = Ask;
      takeProfit = entryPrice + profitInPips * MarketInfo(symbol, MODE_POINT);
      
   } else 
   {
      // entry Price is Bid
      // double entryPrice = Bid;
      takeProfit = entryPrice - profitInPips * MarketInfo(symbol, MODE_POINT);
   }
   
   return takeProfit;
}




// check if there is any order in place based on strategy Id
bool isThereAnyOrder(int strategyId = -1)
{
   
   for (int i = 0; i < OrdersTotal(); i++)
   {
     if (OrderSelect(i, SELECT_BY_POS))
     {
         if (strategyId == -1 || OrderMagicNumber() == strategyId)
         {
            return true;
         }
         
     }
   }
   return false;
}

// check if there is any order in place based on order Id
bool isThereAnyOrderById(int orderId)
{
   
   for (int i = 0; i < OrdersTotal(); i++)
   {
     if (OrderSelect(orderId, SELECT_BY_TICKET))
     {
         return true;
         
     }
   }
   return false;
}


bool isNewBar(string symbol, int timeframe, bool loadAtNewBar = false)
{
   static datetime barTime = 0;
   static double openPrice = 0;
   
   datetime currentBarTime       = iTime(symbol, timeframe, 0);
   double   currentBarOpenPrice  = iOpen(symbol, timeframe, 0);
   
   int digits = (int) MarketInfo(symbol, MODE_DIGITS);
   
   if (barTime == 0 && openPrice == 0) // first time bot enter chart
   {
      barTime     = currentBarTime;
      openPrice   = currentBarOpenPrice;
      
      if (loadAtNewBar)
      {
         return false;
      }
      return true;
   } else 
   if (currentBarTime > barTime && compareDouble(currentBarOpenPrice, openPrice, digits) != 0) //  new bar formed
   {
      barTime     = currentBarTime;
      openPrice   = currentBarOpenPrice;     
      return true;
   }

   return false;
}

// check if a certain datetime is between human hour and minutes time
bool isTimeBetween(datetime time, int startHour, int startMinute,  int endHour, int endMinute, int gmt = 0)
{

   if (gmt != 0)
   {
      startHour += gmt;
      endHour   += gmt;
   }
   
   if (startHour > 23)     startHour = (startHour - 23) - 1;
   else if (startHour < 0) startHour = (startHour + 23) + 1;
   
   if (endHour > 23)     endHour = (startHour - 23) - 1;
   else if (endHour < 0) endHour = (startHour + 23) + 1;   

   int hour = TimeHour(time);
   int minutes = TimeMinute(time);

   int timeInSeconds       = (hour * 3600) + (minutes * 60);
   int timeStartInSeconds  = (startHour * 3600) + (startMinute * 60);
   int timeEndInSeconds    = (endHour * 3600) + (endMinute * 60);
   
   if (timeStartInSeconds == timeEndInSeconds) return true; // INTERPRET as different day
   
   // check if 1000 is between 9 am and 3 pm
   else if (timeStartInSeconds < timeEndInSeconds)
   {
      // t: 1000 s : 900 e : 1100 
      if (timeInSeconds >= timeStartInSeconds && timeInSeconds < timeEndInSeconds ) // within same day
      return true;
      
   }
   else if (timeStartInSeconds < timeEndInSeconds) 
   {
      if (timeEndInSeconds >= timeStartInSeconds || timeEndInSeconds < timeEndInSeconds)// does not belong to same day
      return true;
   }
   
   return false;
}