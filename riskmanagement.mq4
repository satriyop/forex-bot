//+------------------------------------------------------------------+
//|                                               RiskManagement.mq4 |
//|                                          Copyright 2021,satriyop |
//|                                        https://www.enterkode.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,satriyop"
#property link      "https://www.enterkode.com"
#property version   "1.00"
#property strict

double accountEquity =  AccountEquity();

double contractSize = MarketInfo(NULL, MODE_LOTSIZE);

double minLotAllowed = MarketInfo(NULL, MODE_MINLOT);



// Priority no 1 : Not to lose capital 
// A. define max loss in pip eg 40
// B. Max Loss per trade eg 2%



// 1. Calculate dollar max loss for the position

// 2. Decide on  MaxPips,  entry price & Stop Loss Price

// 3. Calculate Position Size


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   double tickValue = MarketInfo(NULL, MODE_TICKVALUE);
   Alert (tickValue);
   // Alert(accountEquity);
   // Alert(contractSize);
   // Alert(minLotAllowed);
   // Check with broker's min Lot size allowed
  }
//+------------------------------------------------------------------+


// This works if account balance currency is USD (not GPY)
double calculateOptimalLotPositionSizeByPips(double maxLossPerTradePercentage, int maxLossInPips)
{
   // tick value based on current graph
   double tickValue = MarketInfo(NULL, MODE_TICKVALUE);
   if (Digits <= 3)
   {
      tickValue = tickValue / 100;
   }

   // max loss in dollar
   double maxLossInDollar = AccountBalance() * maxLossPerTradePercentage;
   
   // if counter currency is USD than it will be the same. eg : EUR/USD
   double maxLossInDollarInQuoteCurrency = maxLossInDollar / tickValue;
   
   // get the optimal lot size based on percentage of loss per trade and max loss in pips
   double optimalLosSize = maxLossInDollarInQuoteCurrency / (maxLossInPips * getValueInPips()) / contractSize;
   
   return NormalizeDouble(optimalLosSize, 2);
}


double calculateOptimalLotPositionSizeByEntryPrice(double maxLossPerTradePercentage, double entryPrice, double stopLossPrice)
{
   
   // maxLossBasedOnPips
   int maxPips = MathAbs(entryPrice - stopLossPrice) / getValueInPips();
   
   double optimalLosSize = calculateOptimalLotPositionSizeByPips(maxLossPerTradePercentage, maxPips );
   
   return NormalizeDouble(optimalLosSize, 2);
}


double getValueInPips()
{
   if (Digits >= 5)
   {
      return 0.0001;
   } else return 0.001;

}