//+------------------------------------------------------------------+
//|                                        anti-martingale by MA.mq4 |
//|                                                  Angus Chiu 2015 |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+

//Preprocessor
#include <IncludeExample.mqh>
#include <stdlib.mqh>

#property copyright "Angus Chiu 2015"
#property link      "https://www.google.com"
#property version   "1.00"
#property strict

//External, variables
extern double LotSize=0.5;
extern double StopLoss=50;
extern double TrailingStopLoss=50;
extern double TrailingMinProfit=-100;
extern double AntiMartingaleStopLoss=50;
extern double TakeProfit=100;
extern double EquityRiskPercentage=4;
//extern int PendingPips = 10;

extern int Slippage=5;
extern int MagicNumber=123;

extern int FastMAPeriod = 10;
extern int SlowMAPeriod = 20;

//Global variables
int BuyTicket;
int SellTicket;
double UsePoint;
int UseSlippage;
int ErrorCode;
int Ticket;
//--- input parameters
input bool     DynamicLotSize=true;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   UsePoint=PipPoint(Symbol());
   Alert("UsePoint: ",UsePoint);
   UseSlippage=GetSlippage(Symbol(),Slippage);
   Alert("UseSlippage: ",UseSlippage);
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

//Alert("OnTick() triggered");
   double BuyStopLoss=0;
   double BuyTakeProfit=0;
//double CloseLots=0;
//double ClosePrice=0;
//bool Closed;
//bool Deleted;
   double OpenPrice=0;
   double SellStopLoss=0;
   double SellTakeProfit=0;

//Moving averages
   if(FastMAPeriod>=SlowMAPeriod)
     {
      //string ErrDesc;
      //string ErrAlert;
      string ErrLog;

      Alert("Start(): FastMAPeriod is longer than SlowMAPeriod, EA should not proceed.");
      ErrLog=StringConcatenate("FastMAPeriod is longer than SlowMAPeriod, EA should not proceed.");
      Print(ErrLog);
      return;
     }

   double FastMA = iMA(NULL,0, FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);
   double SlowMA = iMA(NULL,0, SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,1);


//Buy order
   Alert("Start(): FastMA=",FastMA,",SlowMA=",SlowMA,", BuyTicket=",BuyTicket,",SellTicket=",SellTicket);

   if(FastMA>=SlowMA && BuyTicket==0)
     {
      Alert("Start(): Buy action: FastMA=",FastMA,",SlowMA=",SlowMA,", BuyTicket=",BuyTicket,",SellTicket=",SellTicket);

      //Close existing sell position, if any
      if(SellMarketCount(Symbol(),MagicNumber)>=0)
        {
         CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage);
         Alert("Start(): SellMarketCount() now returns ",SellMarketCount(Symbol(),MagicNumber));
         if(SellMarketCount(Symbol(),MagicNumber)==0)
           {
            SellTicket=0;
            Alert("reset SellTicket to ",SellTicket);
           }
        }

      //Delete outstanding sell order, if any
      CloseAllSellStopOrders(Symbol(),MagicNumber);
      CloseAllSellLimitOrders(Symbol(),MagicNumber);

      OpenPrice=Ask;
      //Calculate stop loss and take profit
      if(StopLoss>0)
        {
         BuyStopLoss=CalcBuyStopLoss(Symbol(),StopLoss,OpenPrice);
         BuyStopLoss=AdjustBelowStopLevel(Symbol(),BuyStopLoss);
        }
      if(TakeProfit>0)
        {
         BuyTakeProfit=CalcBuyTakeProfit(Symbol(),TakeProfit,OpenPrice);
         BuyTakeProfit=AdjustAboveStopLevel(Symbol(),BuyTakeProfit);
        }

      //Calculate lot size
      LotSize=CalcLotSize(DynamicLotSize,EquityRiskPercentage,StopLoss,LotSize);
      LotSize=VerifyLotSize(LotSize);
      Alert("DynamicLotSize=",DynamicLotSize,", LotSize=",LotSize);

      //Open buy order
      BuyTicket=OpenBuyOrder(Symbol(),LotSize,UseSlippage,MagicNumber);
      AddStopProfit(BuyTicket,BuyStopLoss,BuyTakeProfit);
      Alert("BuyTicket=",BuyTicket,", TP=",BuyTakeProfit,", SL=",BuyStopLoss);

      if(BuyTicket==-1)
        {
         //Problem in open market buy order, BuyTicket set back to 0 to denote no buy order opened.
         Alert("Start(): Problem to open buy order, BuyTicket=",BuyTicket);
         BuyTicket=0;
         Alert("Start(): Problem to open buy order, now BuyTicket reset to ",BuyTicket);
        }
     }
//Sell order
   if(FastMA<SlowMA && SellTicket==0)
     {
      Alert("Start(): Sell action: FastMA=",FastMA,",SlowMA=",SlowMA,", BuyTicket=",BuyTicket,",SellTicket=",SellTicket);

      //Close existing buy position, if any
      if(BuyMarketCount(Symbol(),MagicNumber)>=0)
        {
         CloseAllBuyOrders(Symbol(),MagicNumber,UseSlippage);
         Alert("Start(): BuyMarketCount() now returns ",BuyMarketCount(Symbol(),MagicNumber));
         if(BuyMarketCount(Symbol(),MagicNumber)==0)
           {
            BuyTicket=0;
            Alert("reset BuyTicket to ",BuyTicket);
           }
        }
      //Delete outstanding buy order, if any
      CloseAllBuyLimitOrders(Symbol(),MagicNumber);
      CloseAllBuyStopOrders(Symbol(),MagicNumber);

      OpenPrice=Bid;
      //Calculate stop loss and take profit
      if(StopLoss>0)
        {
         SellStopLoss=CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);
         SellStopLoss=AdjustAboveStopLevel(Symbol(),SellStopLoss);
        }
      if(TakeProfit>0)
        {
         SellTakeProfit=CalcSellTakeProfit(Symbol(),TakeProfit,OpenPrice);
         SellTakeProfit=AdjustBelowStopLevel(Symbol(),SellTakeProfit);
        }

      //Calculate lot size
      LotSize=CalcLotSize(DynamicLotSize,EquityRiskPercentage,StopLoss,LotSize);
      LotSize=VerifyLotSize(LotSize);
      Alert("DynamicLotSize=",DynamicLotSize,", LotSize=",LotSize);

      //Open sell order
      SellTicket=OpenSellOrder(Symbol(),LotSize,UseSlippage,MagicNumber);
      AddStopProfit(SellTicket,SellStopLoss,SellTakeProfit);
      Alert("Start(): SellTicket=",SellTicket,", TP=",SellTakeProfit,", SL=",SellStopLoss);

      if(SellTicket==-1)
        {
         //Problem in open market sell order, SellTicket set back to 0 to denote no sell order opened.
         Alert("Start(): Problem to open sell order, SellTicket=",SellTicket);
         SellTicket=0;
         Alert("Start(): Problem to open sell order, now SellTicket reset to ",SellTicket);
        }
     }
   BuyTrailingStop(Symbol(),TrailingStopLoss,TrailingMinProfit,MagicNumber); // Once opened, immediately trigger trailing SL no matter what TP
   SellTrailingStop(Symbol(),TrailingStopLoss,TrailingMinProfit,MagicNumber); // Once opened, immediately trigger trailing SL no matter what TP
   CalcMartingaleLotSize(MagicNumber,AntiMartingaleStopLoss,MarketInfo(Symbol(),MODE_MINLOT));

   return;
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
   Alert("OnTester(): triggered");
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
