//+------------------------------------------------------------------+
//|                                               RiskManagement.mq4 |
//|                                          Copyright 2021,satriyop |
//|                                        https://www.enterkode.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,satriyop"
#property link      "https://www.enterkode.com"
#property version   "1.00"
#property strict

double minLotAllowed = MarketInfo(NULL, MODE_MINLOT);

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {

  }
//+------------------------------------------------------------------+


double calculateLotByLossInPips(double maxLossPerTradePercentage, int maxLossInPips)
{
   // tick value based on current graph
   double tickValue = MarketInfo(NULL, MODE_TICKVALUE);
   if (Digits <= 3)
   {
      tickValue = tickValue / 100;
   }

   double contractSize = MarketInfo(NULL, MODE_LOTSIZE);

   // max loss in dollar
   double maxLossInDollar = AccountBalance() * maxLossPerTradePercentage;
   
   // if counter currency is USD than it will be the same. eg : EUR/USD
   double maxLossInDollarInQuoteCurrency = maxLossInDollar / tickValue;
   
   // get the optimal lot size based on percentage of loss per trade and max loss in pips
   double lot = maxLossInDollarInQuoteCurrency / (maxLossInPips * getValueInPips()) / contractSize;
   
   return NormalizeDouble(lot, 2);
}


double calculateLotByEntryPriceAndStopLoss(double maxLossPerTradePercentage, double entryPrice, double stopLossPrice)
{
   
   // maxLossBasedOnPips
   int maxPips = MathAbs(entryPrice - stopLossPrice) / getValueInPips();
   
   double lot = calculateLotByLossInPips(maxLossPerTradePercentage, maxPips );
   
   return NormalizeDouble(lot, 2);
}


double calculateLotByFixedRiskPercentage(string symbol, double riskPercentage, double stoploss)
{
   double balance  = AccountBalance();
   double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
   double lot;
   if (stoploss > 0)
   {
      lot = ((balance * riskPercentage) / stoploss) / tickValue;
   }
   
   return NormalizeDouble(lot, 2);
}


// ratio of money per lot 
// the larger balance, the larger lot and vv
double calculateLotByFixedRatio(string symbol, double lotSize, double tradePerLot)
{
   double balance  = AccountBalance();;
   
   double lot = balance * (lotSize / tradePerLot);

   return NormalizeDouble(lot, 2);
}

// fix risk in currency
double calculateLotByFixedRisk(string symbol, double fixRisk, double stoploss)
{
   double balance  = AccountBalance();
   double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
   double lot =0;
   
   if (stoploss > 0)
   {
      lot = (fixRisk / tickValue) / stoploss;
   }
  

   return NormalizeDouble(lot, 2);
}


// seldom, large lot
double calculateLotByFixedRiskPerPoint(string symbol, double fixRisk, double stoploss)
{
   double balance  = AccountBalance();
   double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
   
   double lot = fixRisk / tickValue;

   return NormalizeDouble(lot, 2);
}

double getValueInPips()
{
   if (Digits >= 5)
   {
      return 0.0001;
   } else return 0.001;
}