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
bool exitOrderById(int orderId, color aClr = clrNONE,  int slippage = 30)
{
   bool result = false;
   
   if (OrderSelect(orderId, SELECT_BY_TICKET))
   {
      RefreshRates();
      if (OrderType() <= 1) // market order
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
bool exitOrder(int orderId,  color aClr = clrNONE,  int slippage = 30, int retries = 3, int sleep = 500)
{
   bool result = false;
   
   // check condition before closing
   if (!IsConnected())              Print("No Internet connection");
   else if (!IsExpertEnabled())     Print("EA not enabled");
   else if (!IsTradeContextBusy())  Print("Trade Context Busy");
   else if (!IsTradeAllowed())      Print("Trade is not allowed in trading platform");
   else 
   
   result = exitOrderById(orderId, aClr, slippage);
   
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
         if (strategyId = - 1 || strategyId == OrderMagicNumber())
         {
            int orderType = OrderType();
            int orderId = OrderTicket();
            
            switch(type)
            {
               case ORDER_SET_BUY:
                  if (orderType == OP_BUY) exitOrder(orderId);
                  break;
               case ORDER_SET_SELL:
                  if (orderType == OP_SELL) exitOrder(orderId);
                  break;
               case ORDER_SET_BUY_LIMIT:
                  if (orderType == OP_BUYLIMIT) exitOrder(orderId);               
                  break;
               case ORDER_SET_SELL_LIMIT:
                  if (orderType == OP_SELLLIMIT) exitOrder(orderId);               
                  break;
               case ORDER_SET_BUY_STOP:
                  if (orderType == OP_BUYSTOP) exitOrder(orderId);               
                  break;
               case ORDER_SET_SELL_STOP:
                  if (orderType == OP_SELLSTOP) exitOrder(orderId);               
                  break;
               case ORDER_SET_LONG:
                  if (orderType == OP_BUY || orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT) exitOrder(orderId);               
                  break;
               case ORDER_SET_SHORT:
                  if (orderType == OP_SELL || orderType == OP_SELLSTOP || orderType == OP_SELLLIMIT) exitOrder(orderId);               
                  break;
               case ORDER_SET_LIMIT:
                  if (orderType == OP_BUYLIMIT || orderType == OP_SELLLIMIT) exitOrder(orderId);               
                  break;
               case ORDER_SET_STOP:
                  if (orderType == OP_BUYSTOP || orderType == OP_SELLSTOP) exitOrder(orderId);               
                  break;
               case ORDER_SET_MARKET:
                  if (orderType <= 1) exitOrder(orderId);               
                  break;
               case ORDER_SET_PENDING:
                  if (orderType > 1) exitOrder(orderId);               
                  break;
               default:
                  exitOrder(orderId);

            }
         }
      }
   }  
}