//+------------------------------------------------------------------+
//|                                                SignalManager.mq4 |
//|                                          Copyright 2021,satriyop |
//|                                        https://www.enterkode.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,satriyop"
#property link      "https://www.enterkode.com"
#property version   "1.00"
#property strict

enum TRADE_SIGNAL
{
   TRADE_SIGNAL_VOID = -1, // no trade, close all orders
   TRADE_SIGNAL_NEUTRAL, // no trade only, as initiation
   TRADE_SIGNAL_BUY,
   TRADE_SIGNAL_SELL,
   
};

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {

   
  }
//+------------------------------------------------------------------+

// combining multiple possible signals variation, returning signal
int evaluateNewSignal(int currentSignal, int newSignal, bool exit=false)
{
   if (currentSignal  == TRADE_SIGNAL_VOID)
   {
      return currentSignal;
   } else if (currentSignal == TRADE_SIGNAL_NEUTRAL)
   {
      return newSignal;
   } else // whether buy, sell, or close all orders
   {
      if (newSignal == TRADE_SIGNAL_NEUTRAL)
      {
         return currentSignal;
      } else if (newSignal == TRADE_SIGNAL_VOID)
      {
         return newSignal;
      } else if (newSignal != currentSignal && exit)
      {
         return TRADE_SIGNAL_VOID;
      } else if (newSignal != currentSignal && ! exit)
      {
         return TRADE_SIGNAL_NEUTRAL;
      }
      return newSignal;
   }

}


// evaluate entry signal from combining all possuble signals
int evaluateEntrySignal()
{
   int signal = TRADE_SIGNAL_NEUTRAL;
   
   // evaluate signals
   signal = evaluateNewSignal(signal, TRADE_SIGNAL_BUY);
   signal = evaluateNewSignal(signal, TRADE_SIGNAL_BUY); 
   // and soon
   // other function or indicators
   
   // return entry signal
   return signal;
}


// evaluating exit signal from combining signals
int evaluateExitSignal()
{
   bool isExitSignal = true;
   int signal = TRADE_SIGNAL_NEUTRAL;
   
   // evaluate signals
   signal = evaluateNewSignal(signal, TRADE_SIGNAL_BUY, isExitSignal);
   signal = evaluateNewSignal(signal, TRADE_SIGNAL_BUY, isExitSignal); 
   // and soon
   
   // return exit signal
   return signal;
}


// to avoid overlap open and close position
void signalManager(TRADE_SIGNAL &entry, TRADE_SIGNAL &exit)
{
   if (exit == TRADE_SIGNAL_VOID) entry = TRADE_SIGNAL_NEUTRAL;
   
   if (exit == TRADE_SIGNAL_BUY && entry == TRADE_SIGNAL_SELL) entry = TRADE_SIGNAL_NEUTRAL;
   
   if (exit == TRADE_SIGNAL_SELL && TRADE_SIGNAL_BUY) entry = TRADE_SIGNAL_NEUTRAL;
   
}