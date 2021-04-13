//+------------------------------------------------------------------+
//|                                                 BollingerRsi.mq4 |
//|                                          Copyright 2021,satriyop |
//|                                        https://www.enterkode.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,satriyop"
#property link      "https://www.enterkode.com"
#property version   "1.00"
#property strict

#property  show_inputs

// signal propery
input int bbPeriod = 50;
input int bbStandardDevTakeProfit = 1;
input int bbStandardDevEntry = 2;
input int bbStandardDevStopLoss = 6;

input int rsiLower = 40;
input int rsiUpper = 60;
input int rsiPeriod = 14;

// order property
int orderId;
double contractSize = MarketInfo(NULL, MODE_LOTSIZE);

// bot property
int strategyId = 888;


// risk management 2%
input double maxPercentageLoss = 0.02;
extern double orderVolume;

input int minTakeProfitPips = 50;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      // Check AutoTrading is Allowed      
      bool isAutoTradeOn = IsTradeAllowed();
      if (!isAutoTradeOn)
      {
         Alert("Please enable Auto Trading");
         
      }    
      
  
      Alert("Autobot has started....");   
//---
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
  
      // SIGNAL ENTRY, EXIT
      // SIGNAL FROM Bollinger
      double bbLowerBandEntryBuy = iBands(NULL, PERIOD_CURRENT, bbPeriod, bbStandardDevEntry , 0, PRICE_CLOSE, MODE_LOWER, 0);
      double bbUpperBandEntrySell = iBands(NULL, PERIOD_CURRENT, bbPeriod, bbStandardDevEntry , 0, PRICE_CLOSE, MODE_UPPER, 0);

      // use this band as take profit price
      double bbLowerBandTakeProfitSell = iBands(NULL, PERIOD_CURRENT, bbPeriod, bbStandardDevTakeProfit , 0, PRICE_CLOSE, MODE_LOWER, 0);
      double bbUpperBandTakeProfitBuy = iBands(NULL, PERIOD_CURRENT, bbPeriod, bbStandardDevTakeProfit , 0, PRICE_CLOSE, MODE_UPPER, 0);

      // use lowerband with std4 as support & resistance 
      double bbLowerBandStoplossBuy = iBands(NULL, PERIOD_CURRENT, bbPeriod, bbStandardDevStopLoss , 0, PRICE_CLOSE, MODE_LOWER, 0);
      double bbUpperBandStoplossSell = iBands(NULL, PERIOD_CURRENT, bbPeriod, bbStandardDevStopLoss , 0, PRICE_CLOSE, MODE_UPPER, 0);
      
      // SINGAL FROM RSI
      double rsi = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);
      
      
      
      // check if there any opened position
      bool isOrderOpened = isPositionOpened(strategyId);
      
      if (!isOrderOpened)
      {
         if (Ask < bbLowerBandEntryBuy && Open[0] > bbLowerBandEntryBuy && rsi < rsiLower) //buy
         {
            // calculate SL & TP and then open long position
            double stoplossPrice = NormalizeDouble(bbLowerBandStoplossBuy, Digits);
            double takeprofitPrice = NormalizeDouble(bbUpperBandTakeProfitBuy, Digits);
            
            openLongPosition(stoplossPrice, takeprofitPrice);
            
         } else if (Bid > bbUpperBandEntrySell && Open[0] < bbUpperBandEntrySell && rsi > rsiUpper) // sell
         {
            // calculate SL & TP and then open short position
            double stoplossPrice = NormalizeDouble(bbUpperBandStoplossSell, Digits);
            double takeprofitPrice = NormalizeDouble(bbLowerBandTakeProfitSell, Digits);  
            
            openShortPosition(stoplossPrice, takeprofitPrice);         
         }
      
      } else
      {
         // updating order
         if (OrderSelect(orderId, SELECT_BY_TICKET)) 
         {
            int orderType = OrderType(); // 0 long, 1 short
            
            double currentTakeProfitPrice = OrderTakeProfit();
            double currentStopLossPrice = OrderStopLoss();
            
            // get new take profit as band move to right
            double entryToTakeprofitDistance;
            double entryToStoplossDistance;
            double newTakeprofitPrice;
            double newStopLossPrice;
            
            if (orderType == 0) 
            {
               newTakeprofitPrice = NormalizeDouble(bbUpperBandTakeProfitBuy, Digits);
               newStopLossPrice = NormalizeDouble(bbLowerBandStoplossBuy, Digits);
                
            } else if (orderType == 1)
            {
               newTakeprofitPrice = NormalizeDouble(bbLowerBandTakeProfitSell, Digits);
               newStopLossPrice = NormalizeDouble(bbUpperBandStoplossSell, Digits);
            }
            
            // if band if moving then modify the order
            double takeprofitDistance = MathAbs(newTakeprofitPrice - currentTakeProfitPrice);
            double stoplossDistance = MathAbs(newStopLossPrice - currentStopLossPrice);
            
            if (currentTakeProfitPrice != newTakeprofitPrice && currentStopLossPrice != newStopLossPrice && takeprofitDistance > 0.0001 && stoplossDistance > 0.0001)
            {

                  bool isOrderModified = OrderModify(orderId, OrderOpenPrice(), newStopLossPrice, newTakeprofitPrice, 0);
                  
                  if (isOrderModified)
                  {
                     Alert("Order Modified");
                  } else Alert("Unable to modify order");  
                 

            } 
         }
      }
  }
//+------------------------------------------------------------------+

bool isPositionOpened(int magicNumber)
   {
      int totalPositionOpened = OrdersTotal();
      
      for (int i = 0; i < totalPositionOpened; i++)
      {
        if (OrderSelect(i, SELECT_BY_POS) == true)
        {
            if (OrderMagicNumber() == strategyId)
            {
               return true;
            }
            
        }
      }
      return false;
   }
   

void openLongPosition(double stopLossPrice, double takeProfitPrice)
{
   // calculate optimal lot size
   //orderVolume = calculateOptimalLotPositionSizeByEntryPrice(maxPercentageLoss, Ask, stopLossPrice);
   orderVolume = 0.1;
      
   // order to Buy at Ask     
   Alert("Sending Buy Order");
   //double entryPrice = Ask + 20 * MarketInfo(NULL, MODE_POINT);
   Print("Entry Price = " + Ask + ". StopLoss = " + stopLossPrice + ". TakeProfit = " + takeProfitPrice);
   orderId = OrderSend(NULL, OP_BUYLIMIT, orderVolume, Ask-20, 10, stopLossPrice, takeProfitPrice, "", strategyId);
         
   if (orderId < 1)
   {
      Alert("Order Rejected : ", GetLastError());
   } else
   {         
      Alert("Order Succeed, Order Id : " + orderId);
   }
   
}


void openShortPosition(double stopLossPrice, double takeProfitPrice)
{    
   // calculate optimal lot size
   //orderVolume = calculateOptimalLotPositionSizeByEntryPrice(maxPercentageLoss, Bid, stopLossPrice);      
   orderVolume = 0.1;
   // order to Sell at Bid

   Alert("Sending Sell Order");

    
   orderId = OrderSend(NULL, OP_SELLLIMIT, orderVolume, Bid + 20 * Point, 10, stopLossPrice , takeProfitPrice  , "", strategyId);
         
   if (orderId < 1)
   {
      Alert("Order Rejected : ", GetLastError());
   } else
   {
      Alert("Order Succeed, Order Id : " + orderId);
   } 
   
}