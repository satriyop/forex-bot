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