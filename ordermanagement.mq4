//+------------------------------------------------------------------+
//|                                               OrderOperation.mq4 |
//|                                          Copyright 2021,satriyop |
//|                                        https://www.enterkode.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,satriyop"
#property link      "https://www.enterkode.com"
#property version   "1.00"
#property strict

bool isAutoTradeOn;


const int strategyId = 888;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
      
      // Market Open or Close
      
      // Check Auto Order Function
      isAutoTradeOn = IsTradeAllowed();
      if (!isAutoTradeOn)
      {
         Alert("Please enable Auto Trading");
      }
         
      
      
      
  }
//+------------------------------------------------------------------+

// ENTRY ORDER MANAGEMENT
// ----------------------------------

bool isPositionOpened(int magicNumber)
{
   int totalPositionOpened = OrdersTotal();
   
   for (int i = 0; i < totalPositionOpened; i++)
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
int sendOrder(string symbol, int cmd, double volume, double distance, int slippage, double stoplossInPips, 
              double takeprofitInPips, string comment = NULL, int magic = 888, int expire = 0, int a_clr = clrGreen)
{
   double price = 0;
   
   double stoplossPrice = 0;
   
   double takeprofitPrice = 0;
   
   double point = MarketInfo(symbol, MODE_POINT);
   
   // datetime expire = 0;
   
   if (expire > 0 && distance > 0) // pending order
   {
      expire = MarketInfo(symbol, MODE_TIME) + expire;
   }
   
   
   if (cmd == OP_BUY || cmd == OP_BUYLIMIT || cmd == OP_BUYSTOP)
   {
      price = MarketInfo(symbol, MODE_ASK) + distance * point;
      
      if (stoplossInPips > 0)    stoplossPrice     = price - stoplossInPips * point;
      if (takeprofitInPips > 0)  takeprofitPrice   = price + takeprofitInPips * point;
   
   } else if (cmd == OP_SELL || cmd == OP_SELLLIMIT || cmd == OP_SELLSTOP)
   {
      price = MarketInfo(symbol, MODE_BID) + distance * point;
      
      if (stoplossInPips > 0)    stoplossPrice     = price + stoplossInPips * point;
      if (takeprofitInPips > 0)  takeprofitPrice   = price - takeprofitInPips * point;
   }
   

   return OrderSend(symbol, cmd, volume, price, slippage, stoplossPrice, takeprofitPrice, comment, magic, expire, a_clr);

}

// EXIT ORDER MANAGEMENT
// --------------------------------

// exit order based on order type
int exitOrder(int orderId, color aClr = clrNONE,  int slippage = 30)
{
   int result = 0;
   
   if (OrderSelect(orderId, SELECT_BY_TICKET))
   {
      RefreshRates();
      if (OrderType() <= 1) // buy or sell with market order
      {
         result = OrderClose(orderId, OrderLots(), OrderClosePrice(), slippage, aClr);
      } else if (OrderType() > 1) // pending order
      {
         result = OrderDelete(orderId, aClr);
      }
   }
   
   return result;
}

// exit order with defined retry times
int exitOrderWithRetry(int orderId,  color aClr = clrNONE,  int slippage = 30, int retries = 3, int sleep = 500)
{
   int result;
   
   // check condition before closing
   if (!IsConnected())              Print("No Internet connection");
   else if (!IsExpertEnabled())     Print("EA not enabled");
   else if (!IsTradeContextBusy())  Print("Trade Context Busy");
   else if (!IsTradeAllowed())      Print("Trade is not allowed in trading platform");
   else 
   
   result = exitOrder(orderId, aClr, slippage);
   for (int i = 0; i <= retries; i++)
   {
      
      
      if (result)
      {
         Print("Closing order " + OrderTicket() + " Successful");
         break;
      } else
      {
         Print("Closing order " + OrderTicket() + " Failed "  + GetLastError());
         Sleep(sleep);
      }
      
   }
   
   return result;
}

// order type -1 will close all orders
void exitOrderAll(int orderType = -1, int strategyId = -1)
{
   for (int i = OrdersTotal(); i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS))
      {
         if ((orderType == -1 || orderType == OrderType()) && (strategyId == -1 || strategyId == OrderMagicNumber()))
         exitOrderWithRetry(OrderTicket());
      }
   }
}
