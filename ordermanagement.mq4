//+------------------------------------------------------------------+
//|                                              OrderManagement.mq4 |
//|                                          Copyright 2021,satriyop |
//|                                        https://www.enterkode.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,satriyop"
#property link      "https://www.enterkode.com"
#property version   "1.00"
#property strict



enum ORDER_SET
{
   ORDER_SET_ALL = -1,
   ORDER_SET_BUY,
   ORDER_SET_SELL,
   ORDER_SET_BUY_LIMIT,
   ORDER_SET_SELL_LIMIT,
   ORDER_SET_BUY_STOP,
   ORDER_SET_SELL_STOP,
   ORDER_SET_LONG,
   ORDER_SET_SHORT,
   ORDER_SET_LIMIT,
   ORDER_SET_STOP,
   ORDER_SET_MARKET,
   ORDER_SET_PENDING
};

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {         
      
  }
//+------------------------------------------------------------------+


// ----------------------------------//
// ENTRY ORDER MANAGEMENT            //
// ----------------------------------//

bool isThereAnyOrder(int strategyId)
{
   for (int i = 0; i < OrdersTotal(); i++)
   {
     if (OrderSelect(i, SELECT_BY_POS))
     {
         if (OrderMagicNumber() == strategyId)
         {
            return true;
         }
         
     }
   }
   return false;
}

// pending order distance must > 0, expire > 0
int sendOrderByPips(string symbol, int cmd, double volume, double distance, int slippage, double stoplossInPips, 
              double takeprofitInPips, string comment = NULL, int magic = 888, int expireInSecond = 0, int a_clr = clrGreen)
{
   double price = 0;
   double stoplossPrice = 0;
   double takeprofitPrice = 0;
   double point = MarketInfo(symbol, MODE_POINT);
   datetime expiration = 0;
   
   if (expireInSecond > 0 && distance > 0) // pending order
   {
      expiration = MarketInfo(symbol, MODE_TIME) + expireInSecond;
   }
   
   // refresh price based on latest tick
   RefreshRates();
   
   
   if (cmd == OP_BUY || cmd == OP_BUYLIMIT || cmd == OP_BUYSTOP) //long
   {
      price = MarketInfo(symbol, MODE_ASK) + distance * point;
      
      if (stoplossInPips > 0)    stoplossPrice     = price - stoplossInPips * point;
      if (takeprofitInPips > 0)  takeprofitPrice   = price + takeprofitInPips * point;
   
   } else if (cmd == OP_SELL || cmd == OP_SELLLIMIT || cmd == OP_SELLSTOP) //short
   {
      price = MarketInfo(symbol, MODE_BID) + distance * point;
      
      if (stoplossInPips > 0)    stoplossPrice     = price + stoplossInPips * point;
      if (takeprofitInPips > 0)  takeprofitPrice   = price - takeprofitInPips * point;
   }
  
   // sending the order to broker
   return OrderSend(symbol, cmd, volume, price, slippage, stoplossPrice, takeprofitPrice, comment, magic, expiration, a_clr);

}

// send order by position
int sendOrderByPosition(string symbol, int cmd, double volume, double distance, int slippage, double stoplossInPips, 
                        double takeprofitInPips, string comment = NULL, int magic = 888, int expire = 0, int a_clr = clrGreen)
{

   double price = 0;
   double stoplossPrice = 0;
   double takeprofitPrice = 0;
   double point = MarketInfo(symbol, MODE_POINT);
   int orderType = -1; // not sending any order
   int orderId;
   
   RefreshRates();
   
   switch(cmd)
   {
      case OP_BUY:
         // order type based on distance
         if (distance > 0)       orderType = OP_BUYSTOP;
         else if (distance < 0)  orderType = OP_BUYLIMIT;
         else                    orderType = OP_BUY;
         
         // distance and expiration
         if (orderType == OP_BUY)
         {
            distance = 0;
            expire = 0;
         } else
         {
            distance = distance;
            expire = MarketInfo(symbol, MODE_TIME) + expire;
         }
       
         
         // price entry calculation
         price = MarketInfo(symbol, MODE_ASK) + distance * point;
         
         if (stoplossInPips > 0)    stoplossPrice     = price - stoplossInPips * point;
         if (takeprofitInPips > 0)  takeprofitPrice   = price + takeprofitInPips * point;
         
         orderId = OrderSend(symbol, orderType, volume, price, slippage, stoplossPrice, takeprofitPrice, comment, magic, expire, a_clr);
         return orderId;
         break;
      case OP_SELL:
         // order type based on distance
         if (distance > 0)       orderType = OP_SELLLIMIT;
         else if (distance < 0)  orderType = OP_SELLSTOP;
         else                    orderType = OP_SELL;
         
         // distance and expiration
         if (orderType == OP_SELL)
         {
            distance = 0;
            expire = 0;
         } else
         {
            distance = distance;
            expire = MarketInfo(symbol, MODE_TIME) + expire;
         }
         
         price = MarketInfo(symbol, MODE_BID) + distance * point;   
         
         if (stoplossInPips > 0)    stoplossPrice     = price - stoplossInPips * point;
         if (takeprofitInPips > 0)  takeprofitPrice   = price + takeprofitInPips * point;    
         
         orderId = OrderSend(symbol, orderType, volume, price, slippage, stoplossPrice, takeprofitPrice, comment, magic, expire, a_clr); 
         return orderId;          
         break;
      default:
         if (orderType < 0)
         {
            orderId = -1;
         }
         
   }   
   return orderId;
}


// entry send order function with retry
int entryOrder (string symbol, int cmd, double volume, double distance, int slippage, double stoplossInPips, 
                double takeprofitInPips, string comment = NULL, int magic = 888, int expire = 0, 
                int a_clr = clrGreen, int retries = 3, int sleep = 500)

{
   int orderId = 0;
   for (int i = 0; i < retries; i++)
   {
      // check condition before entry
      if (!IsConnected())              Print("No Internet connection");
      else if (!IsExpertEnabled())     Print("EA not enabled");
      else if (!IsTradeContextBusy())  Print("Trade Context Busy");
      else if (!IsTradeAllowed())      Print("Trade is not allowed in trading platform");
      else 
      
      orderId = sendOrderByPips(symbol, cmd, volume, distance, slippage, stoplossInPips, takeprofitInPips, comment, magic, expire, a_clr);
      
      if (orderId > 0) break;
      else Print("Error sending order (" + IntegerToString(GetLastError(),0) + "), retry : " + IntegerToString(i, 0) + "/" + IntegerToString(retries));
      
      Sleep(sleep);
   }
   return orderId;
   
}



//----------------------------------//
// EXIT ORDER MANAGEMENT            //
// ---------------------------------//

// exit order based on order type
bool exitOrderById(int orderId, color aClr = clrNONE,  int slippage = 30)
{
   bool isOrderExited = false;
   
   if (OrderSelect(orderId, SELECT_BY_TICKET))
   {
      RefreshRates();
      if (OrderType() <= 1) // market order
      {
         isOrderExited = OrderClose(orderId, OrderLots(), OrderClosePrice(), slippage, aClr);
      } else if (OrderType() > 1) // pending order
      {
         isOrderExited = OrderDelete(orderId, aClr);
      }
   }
   
   return isOrderExited;
}


// exit order with defined retry times
bool exitOrder(int orderId,  color aClr = clrNONE,  int slippage = 30, int retries = 3, int sleep = 500)
{
   bool isOrderExited = false;
   
   // check condition before closing
   if (!IsConnected())              Print("No Internet connection");
   else if (!IsExpertEnabled())     Print("EA not enabled");
   else if (!IsTradeContextBusy())  Print("Trade Context Busy");
   else if (!IsTradeAllowed())      Print("Trade is not allowed in trading platform");
   else 
   
   isOrderExited = exitOrderById(orderId, aClr, slippage);
   
   for (int i = 0; i <= retries; i++)
   {     
      if (isOrderExited)
      {
         Print("Closing order " + OrderTicket() + " Successful");
         break;
      } else
      {
         Print("Closing order " + OrderTicket() + " Failed "  + GetLastError());
         Sleep(sleep);
      }
   }
   
   return isOrderExited;
}


// order type -1 will close all orders else call with OP_BUY/OP_SELL enum for type
void exitOrdersByType(int type = -1, int strategyId = -1)
{
   for (int i = OrdersTotal(); i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if ((type == -1 || type == OrderType()) &&(strategyId == -1 || strategyId == OrderMagicNumber()))
         
         exitOrder(OrderTicket());
      }   
   }
}


// exit order based on : market orders, pending orders, limit orders, etc
void exitOrders(ORDER_SET type = -1, int strategyId = -1)
{
   for (int i = OrdersTotal(); i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (strategyId == - 1 || strategyId == OrderMagicNumber())
         {
            int orderType = OrderType();
            int orderId = OrderTicket();
            
            switch(type)
            {
               case ORDER_SET_BUY:
                  if (orderType == OP_BUY) 
                  exitOrder(orderId);
                  break;
               case ORDER_SET_SELL:
                  if (orderType == OP_SELL) 
                  exitOrder(orderId);
                  break;
               case ORDER_SET_BUY_LIMIT:
                  if (orderType == OP_BUYLIMIT) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_SELL_LIMIT:
                  if (orderType == OP_SELLLIMIT) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_BUY_STOP:
                  if (orderType == OP_BUYSTOP) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_SELL_STOP:
                  if (orderType == OP_SELLSTOP) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_LONG:
                  if (orderType == OP_BUY || orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_SHORT:
                  if (orderType == OP_SELL || orderType == OP_SELLSTOP || orderType == OP_SELLLIMIT) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_LIMIT:
                  if (orderType == OP_BUYLIMIT || orderType == OP_SELLLIMIT) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_STOP:
                  if (orderType == OP_BUYSTOP || orderType == OP_SELLSTOP) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_MARKET:
                  if (orderType <= 1) 
                  exitOrder(orderId);               
                  break;
               case ORDER_SET_PENDING:
                  if (orderType > 1) 
                  exitOrder(orderId);               
                  break;
               default:
                  exitOrder(orderId);

            }
         }
      }
   }  
}


bool modifyOrder(int orderId, double newPrice, double newStoploss, double newTakeprofit, datetime newExpire = 0, color a_clr = clrNONE)
{
   bool isModified = false;
   
   if (OrderSelect(orderId, SELECT_BY_TICKET))
   {
      if (OrderType() == OP_BUY || OrderType() == OP_SELL) // market order 
      {
         // check if there is no changes in order      
         if (compareDouble(newStoploss, OrderStopLoss() == 0) && compareDouble(newTakeprofit, OrderTakeProfit()) == 0 ) 
         {
            Print("Stoploss and Profit are the same, Nothing todo");
            return true;
         } 
         newPrice = OrderOpenPrice(); // market order can not change the entry price
      
      } else if (OrderType() > 1) // pending order LIMIT/STOP
      {
      
         if (compareDouble(newPrice, OrderOpenPrice()) == 0 && compareDouble(newStoploss, OrderStopLoss() == 0) 
               && compareDouble(newTakeprofit, OrderTakeProfit()) == 0 
               && newExpire == OrderExpiration()) 
               
         {
            Print("New price, new stoploss,  new take profit, expiration are the same as old order, Nothing todo");
            return true;
         }       
      
         newPrice    = NormalizeDouble(newPrice, MarketInfo(OrderSymbol(), MODE_DIGITS));
         newExpire   = OrderExpiration();
      }
      
      newStoploss     = NormalizeDouble(newStoploss, MarketInfo(OrderSymbol(), MODE_DIGITS));
      newTakeprofit   = NormalizeDouble(newTakeprofit, MarketInfo(OrderSymbol(), MODE_DIGITS));
     
      isModified = OrderModify(orderId, newPrice, newStoploss, newTakeprofit,newExpire, a_clr);
      
   }
   
   return isModified;
}


bool modifyOrderWithRetry(int orderId, double newPrice, double newStoploss, double newTakeprofit, datetime newExpire = 0, 
                           color a_clr = clrNONE, int retries = 3, int sleep = 500)
{
   bool isModified = false;
   
   if (orderId < 0) 
   {
      Print("Invalid Order ID");
      return false;
   }
   
   for (int i = 0; i < retries; i++)
   {
   
      // check condition before modify
      if (!IsConnected())              Print("No Internet connection");
      else if (!IsExpertEnabled())     Print("EA not enabled");
      else if (!IsTradeContextBusy())  Print("Trade Context Busy");
      else if (!IsTradeAllowed())      Print("Trade is not allowed in trading platform");
      else 
         
      isModified  = modifyOrder(orderId, newPrice, newStoploss, newTakeprofit, newExpire, a_clr);
      
      if (isModified)
      {
         break;
      } else
      Sleep(sleep);
   }
   
   return isModified;
}


// check if order able to close at breakeven stoploss level
bool breakEvenOrder(int orderId, int threshold, int plus)
{
   if (orderId <= 0) return true; // nothing todo, check again next tick
   
   if (! OrderSelect(orderId, SELECT_BY_TICKET)) return false; // check the error if this fuc return false
   
   bool isBreakEven = true;
   
   double point = MarketInfo(OrderSymbol(), MODE_POINT);
   
   if (OrderType() == OP_BUY)
   {
      double breakEvenStoploss = OrderOpenPrice() + plus * point;
      double profitInPoints = OrderClosePrice() - OrderOpenPrice();
      
      if (OrderStopLoss() == 0 || compareDouble(breakEvenStoploss, OrderStopLoss(), Digits) > 0) 
      {
         if (compareDouble(profitInPoints, threshold * point, Digits) >= 0)
         isBreakEven = modifyOrderWithRetry(orderId, OrderOpenPrice(), breakEvenStoploss, OrderTakeProfit());
      }
      
   } else if (OrderType() == OP_SELL)
   {
      double breakEvenStoploss = OrderOpenPrice() - plus * point;
      double profitInPoints = OrderOpenPrice() - OrderClosePrice();
      
      if (OrderStopLoss() == 0 || compareDouble(breakEvenStoploss, OrderStopLoss(), Digits) < 0) 
      {
         if (compareDouble(profitInPoints, threshold * point, Digits) >= 0)
         isBreakEven = modifyOrderWithRetry(orderId, OrderOpenPrice(), breakEvenStoploss, OrderTakeProfit());
      }
   }
   
   return isBreakEven;
}


void breakEvenOrders(int threshold, int plus, int strategyId = -1)
{
   for (int i = 0; i <= OrdersTotal(); i++)
   {
   
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (strategyId == -1 || strategyId == OrderMagicNumber())
         {
            if (! breakEvenOrder(OrderTicket(), threshold, plus))
            {
               Print("Error modifiying ticket " , + GetLastError() + " Order Id " + OrderTicket());
            }
         }      
      }

   }
}


bool trailingStopOrder(int orderId, int trailStop,int threshold, int minStoplossDistance)
{
   if (orderId <= 0) return true; // nothing todo, return early, check again next tick
   
   if (!OrderSelect(orderId, SELECT_BY_TICKET)) return false; // check the error if this fuc return false
   
   double point = MarketInfo(OrderSymbol(), MODE_POINT);
 
   bool isTrailing = true;
   
   if (OrderType() == OP_BUY)
   {
      double trailStoploss          = OrderClosePrice() - trailStop * point;
      double thresholdPrice         = OrderOpenPrice() + threshold * point;
      double thresholdStoploss      = thresholdPrice - trailStop * point;
      double stoplossDistance       = trailStoploss - OrderStopLoss();
      
      if (OrderStopLoss() == 0 || compareDouble(thresholdStoploss, OrderClosePrice(), Digits) > 0)
      {
         if (compareDouble(OrderClosePrice(), thresholdPrice, Digits) >= 0) // above threshold price, modify
         {
            isTrailing = modifyOrderWithRetry(orderId, OrderOpenPrice(), thresholdStoploss, OrderTakeProfit());      
         }
      } else if (compareDouble(stoplossDistance, minStoplossDistance, Digits) >= 0) // as long as distance between SL comply, modify
      {
         isTrailing = modifyOrderWithRetry(orderId, OrderOpenPrice(), trailStoploss, OrderTakeProfit());
      }
      
   } else if (OrderType() == OP_SELL)
   {
      double trailStoploss          = OrderClosePrice() + trailStop * point;
      double thresholdPrice         = OrderOpenPrice() - threshold * point;
      double thresholdStoploss      = thresholdPrice + trailStop * point;
      double stoplossDistance    = OrderStopLoss() - trailStoploss ;
      
      if (OrderStopLoss() == 0 || compareDouble(thresholdStoploss, OrderClosePrice(), Digits) < 0)
      {
         if (compareDouble(OrderClosePrice(), thresholdPrice, Digits) <= 0) // below threshold price, modify
         {
            isTrailing = modifyOrderWithRetry(orderId, OrderOpenPrice(), thresholdStoploss, OrderTakeProfit());      
         }
      } else if (compareDouble(stoplossDistance, minStoplossDistance, Digits) >= 0) // distance between SL comply, modify
      {
         isTrailing = modifyOrderWithRetry(orderId, OrderOpenPrice(), trailStoploss, OrderTakeProfit());
      }       
   }
   
   
   return isTrailing;
         
}


void trailingStopOrders(int trailStop,int threshold, int minStoplossDistance, int strategyId = -1)
{
   for (int i = 0; i <= OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if (strategyId == -1 || strategyId == OrderMagicNumber())
         {
            trailingStopOrder(OrderTicket(), trailStop, threshold, minStoplossDistance);
         }      
      }

   }
}


//---------------
// utility
//---------------
int compareDouble(double aDouble, double bDouble, int precision = 10)
{
   double point = MathPow(10, -precision);
   
   int aInt = (int) aDouble/point;
   int bInt = (int) bDouble/point;
   
   if (aInt > bInt)        return 1;
   else if (aInt < bInt)   return -1;
   
   return 0;
}