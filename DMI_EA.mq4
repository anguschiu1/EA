//+------------------------------------------------------------------+
//|                                          DMI Anti-Martingale.mq4 |
//|                                                  Angus Chiu 2015 |
//|                                https://anguschiu_trade_world.com |
//+------------------------------------------------------------------+

//Preprocessor
#include <IncludeExample.mqh>
#include <stdlib.mqh>

#property copyright "Angus Chiu 2015"
#property link      "https://anguschiu_trade_world.com"
#property version   "1.00"
#property strict

//External, variables
extern double InitalLotSize=0.5;
extern double StopLoss=50;
extern double TrailingStopLoss=50;
extern double TrailingMinProfit=-100;
extern double AntiMartingaleStopLoss=50;
extern double AntiMartingaleMinLotInc=0.1;
extern double TakeProfit=100;
extern double EquityRiskPercentage=4;
//extern int PendingPips = 10;

extern int Slippage=5;
extern int MagicNumber=123;

//extern int FastMAPeriod = 10;
//extern int SlowMAPeriod = 20;
extern int ADXPeriod=14;
extern int ADXUpperRange=40;
extern int ADXLowerRange=20;

extern bool ADXPositiveSlopeRequirement=true;
extern bool useAntiMartingale=true;
extern bool CheckOncePerBar=true;
extern bool useTimer=false;
extern bool useLocalTimeInTimer=false;
extern string AllowedTradeStartTime="1970.1.1.0.0";
extern string AllowedTradeEndTime="2099.12.31.23.59";

//Global variables
int BuyTicket;
int SellTicket;
double UsePoint;
int UseSlippage;
datetime currentTimeStamp;
//int ErrorCode;
//int Ticket;
//--- input parameters
input bool     DynamicLotSize=true;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   currentTimeStamp=Time[0];
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
   bool newBar=false;
   int barShift=0;
   bool isTradeAllowed=false;
   datetime currentTime=TimeLocal();
   enum operation
     {
      ADX_BUY,
      ADX_SELL,
      ADX_HOLD,
      ADX_CLOSE
     };

// Condition to trigger trade algorithm
   datetime tradeStartTime=StrToTime(AllowedTradeStartTime);
   datetime tradeEndTime=StrToTime(AllowedTradeEndTime);

//Check whether entered allow trade time is defined by server time instead of local time.
   if(useLocalTimeInTimer)
      currentTime=TimeLocal();
   else
      currentTime=TimeCurrent();

// Check current time is allowed to trade 
//Alert("useTime=",useTimer," isTradeAllowed=",isTradeAllowed," currentTime=",currentTime," tradeStartTime=",tradeStartTime);
   if(useTimer)
     {
      if(currentTime<=tradeEndTime && currentTime>=tradeStartTime)
        {
         isTradeAllowed=true;
        }
      else
        {
         isTradeAllowed=false;
        }
     }
   else
      isTradeAllowed=true;

   if(CheckOncePerBar)
     {
      barShift=1;
      if(currentTimeStamp==Time[0])
        {
         //Bar has not updated yet.
         //Alert("OnTick(): New time bar is not drawn yet, no need to trigger trading algorithm.");
         newBar=false;
        }
      else
        {
         //Bar has been updated, new time bar is drawn.
         Alert("OnTick(): New time bar is drawn, should trigger trading algorithm.");
         currentTimeStamp=Time[0]; //Adjust currentTimeStamp to open time of latest K bar.
         newBar=true;
        }
     }

   if(newBar && isTradeAllowed) // Check trade condition is allowed to run
     {
      //--- Begin trade block
      Alert("OnTick(): Trade condition true, trade decision started at ",currentTimeStamp);

      //Moving averages
      if(ADXLowerRange<0 || ADXLowerRange>100 || ADXUpperRange<0 || ADXUpperRange>100 || ADXPeriod<1)
        {
         //string ErrDesc;
         //string ErrAlert;
         string ErrLog;

         Alert("OnTick(): Invalid DMI input, EA should not proceed.");
         ErrLog=StringConcatenate("OnTick(): Invalid DMI input, EA should not proceed.");
         Print(ErrLog);
         return;
        }

      //double FastMA = iMA(NULL,0, FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,barShift);
      //double SlowMA = iMA(NULL,0, SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,barShift);
      double ADX=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,barShift);
      double plusDI=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,barShift);
      double minusDI=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,barShift);

      double lastADX=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,barShift+1);
      double lastPlusDI=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,barShift+1);
      double lastMinusDI=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,barShift+1);

      double llastADX=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MAIN,barShift+2);
      double llastPlusDI=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,barShift+2);
      double llastMinusDI=iADX(NULL,0,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,barShift+2);

      //Alert("OnTick(): FastMA=",FastMA,",SlowMA=",SlowMA,", BuyTicket=",BuyTicket,",SellTicket=",SellTicket);
      Alert("OnTick(): ADX=",ADX,",lastADX=",lastADX,",+DI=",plusDI,", previous +DI=",lastPlusDI,", -DI=",minusDI,",previous -DI=",lastMinusDI,",BuyTicket=",BuyTicket,",SellTicket=",SellTicket);

      //ADX trade decision calculation
      operation ADXTradeSignal=ADX_CLOSE;
      //if(ADX>ADXLowerRange && plusDI>minusDI && lastPlusDI<lastMinusDI)
      if(!ADXPositiveSlopeRequirement)
        {
         //        Ignore ADX slope check
         lastADX=ADX-1;
         llastADX=ADX-2;
        }
        //Alert("ADXTradeSignal test:",ADX,",",lastADX,",",llastADX);
      if(ADX>ADXLowerRange && plusDI>minusDI && lastPlusDI<lastMinusDI && ADX>lastADX)
        {
         ADXTradeSignal=ADX_BUY;
        }
      else if(ADX>ADXLowerRange && plusDI>minusDI && ADX>lastADX)
        {
         ADXTradeSignal=ADX_BUY;
        }
      else if(ADX>ADXLowerRange && plusDI>minusDI && ADX<=lastADX && lastADX>=llastADX)
        {
         ADXTradeSignal=ADX_BUY;
        }
      //else if(ADX>ADXLowerRange && minusDI>plusDI && lastMinusDI<lastPlusDI)
      else if(ADX>ADXLowerRange && minusDI>plusDI && lastMinusDI<lastPlusDI && ADX>lastADX)
        {
         ADXTradeSignal=ADX_SELL;
        }
      else if(ADX>ADXLowerRange && minusDI>plusDI && ADX>lastADX)
        {
         ADXTradeSignal=ADX_SELL;
        }
      else if(ADX>ADXLowerRange && minusDI>plusDI && ADX<=lastADX && lastADX>=llastADX)
        {
         ADXTradeSignal=ADX_SELL;
        }
      else
        {
         ADXTradeSignal=ADX_CLOSE;
        }
      //if(ADX>ADXUpperRange || ADX<ADXLowerRange)
      //  {
      //   Alert("OnTick(): ADX out of range, should not place new orders. ADX=",ADX,",lastADX=",lastADX,",+DI=",plusDI,", previous +DI=",lastPlusDI,", -DI=",minusDI,",previous -DI=",lastMinusDI,",BuyTicket=",BuyTicket,",SellTicket=",SellTicket);
      //   if(ADX>lastADX)
      //     {
      //      Alert("OnTick(): ADX descreasing, should square all position");
      //      ADXTradeSignal=CLOSE;
      //     }
      //  }
      //else if(ADXPositiveSlopeRequirement && (ADX<=lastADX))
      //  {
      //   Alert("OnTick(): ADX does not meet slope requirement, trade not triggered. ADX=",ADX,",lastADX=",lastADX,",+DI=",plusDI,", previous +DI=",lastPlusDI,", -DI=",minusDI,",previous -DI=",lastMinusDI,",BuyTicket=",BuyTicket,",SellTicket=",SellTicket);
      //  }
      //else
      //  {
      //   Alert("OnTick(): ADX +ve slope and within range. ADX=",ADX,",lastADX=",lastADX,",+DI=",plusDI,", previous +DI=",lastPlusDI,", -DI=",minusDI,",previous -DI=",lastMinusDI,",BuyTicket=",BuyTicket,",SellTicket=",SellTicket);
      //   if((plusDI>minusDI) && (plusDI>lastPlusDI && minusDI<lastMinusDI))
      //     {
      //      Alert("OnTick(): ADXTradeSignal=OP_BUY.");
      //      ADXTradeSignal=BUY;
      //     }
      //   else if((minusDI>plusDI) && (minusDI>lastMinusDI && plusDI<lastPlusDI))
      //     {
      //      Alert("OnTick(): ADXTradeSignal=OP_SELL.");
      //      ADXTradeSignal=SELL;
      //     }
      //  }

            Alert("OnTick(): ADXTradeSignal=",ADXTradeSignal);


      //Buy order
      if(ADXTradeSignal==ADX_BUY)
        {
         Alert("OnTick(): Buy action. ADX=",ADX,",lastADX=",lastADX,",+DI=",plusDI,", previous +DI=",lastPlusDI,", -DI=",minusDI,",previous -DI=",lastMinusDI,",BuyTicket=",BuyTicket,",SellTicket=",SellTicket);

         //Close existing sell position, if any
         //if(SellMarketCount(Symbol(),MagicNumber)>=0)
         //{
         CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage);
         Alert("OnTick(): SellMarketCount() now returns ",SellMarketCount(Symbol(),MagicNumber));
         if(SellMarketCount(Symbol(),MagicNumber)==0)
           {
            SellTicket=0;
            Alert("OnTick(): reset SellTicket to ",SellTicket);
           }
         //}

         //Delete outstanding sell order, if any
         CloseAllSellStopOrders(Symbol(),MagicNumber);
         Alert("OnTick(): SellStopCount() now returns ",SellStopCount(Symbol(),MagicNumber));
         CloseAllSellLimitOrders(Symbol(),MagicNumber);
         Alert("OnTick(): SellLimitCount() now returns ",SellLimitCount(Symbol(),MagicNumber));

         //Open buy order
         OpenPrice=Ask;
         int marketOrderCnt=BuyMarketCount(Symbol(),MagicNumber);
         if(marketOrderCnt==0)
           {
            // First order for this MA cross, enter initial ordering logic
            //Calculate lot size
            InitalLotSize=CalcLotSize(DynamicLotSize,EquityRiskPercentage,StopLoss,InitalLotSize);
            InitalLotSize=VerifyLotSize(InitalLotSize);
            Alert("OnTick(): DynamicLotSize=",DynamicLotSize,", InitalLotSize=",InitalLotSize);

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
            BuyTicket=OpenBuyOrder(Symbol(),InitalLotSize,UseSlippage,MagicNumber);
            AddStopProfit(BuyTicket,BuyStopLoss,BuyTakeProfit);
            Alert("OnTick(): BuyTicket=",BuyTicket,", TP=",BuyTakeProfit,", SL=",BuyStopLoss);

            if(BuyTicket==-1)
              {
               //Problem in open market buy order, BuyTicket set back to 0 to denote no buy order opened.
               Alert("OnTick(): Problem to open buy order, BuyTicket=",BuyTicket);
               BuyTicket=0;
               Alert("OnTick(): Problem to open buy order, now BuyTicket reset to ",BuyTicket);
              }
           }
         else if(marketOrderCnt>0 && useAntiMartingale)
           {
            // Buy order is already in place, calculate whether follow up order is needed.
            double newLotShouldAdd=CalcMartingaleLotSize(MagicNumber,AntiMartingaleStopLoss,AntiMartingaleMinLotInc);
            bool selected=OrderSelect(BuyTicket,SELECT_BY_TICKET);
            if(selected==false)
              {
               int ErrorCode=GetLastError();
               string ErrDesc=ErrorDescription(ErrorCode);

               string ErrAlert=StringConcatenate(Symbol(),"OnTick(): Select First Buy Order - Error: ",ErrorCode,": ",ErrDesc);
               Alert(ErrAlert);

               string ErrLog=StringConcatenate("Ticket: ",BuyTicket);
               Print(ErrLog);
              }
            else
              {
               if(newLotShouldAdd>0)
                 {
                  // Create add-on order
                  int addonBuyTicket=OpenBuyOrder(Symbol(),newLotShouldAdd,UseSlippage,MagicNumber);
                  AddStopProfit(addonBuyTicket,OrderStopLoss(),OrderTakeProfit());
                  Alert("OnTick(): addonBuyTicket=",addonBuyTicket,", TP=",BuyTakeProfit,", SL=",BuyStopLoss,", lot size=",newLotShouldAdd);
                  if(addonBuyTicket==-1)
                    {
                     //Problem in open add-on market buy order
                     Alert("OnTick(): Problem to open add-on buy order, BuyTicket=",addonBuyTicket);
                    }
                 }
              }

           }
         else
           {
            int ErrorCode=GetLastError();
            string ErrDesc=ErrorDescription(ErrorCode);

            string ErrAlert=StringConcatenate(Symbol(),"OnTick(): Market order count smaller than 0 - Error: ",ErrorCode,": ",ErrDesc);
            Alert(ErrAlert);

            string ErrLog=StringConcatenate("Ticket: ",BuyTicket);
            Print(ErrLog);
           }
        }
      //Sell order
      if(ADXTradeSignal==ADX_SELL)
        {
         Alert("OnTick(): Sell action. ADX=",ADX,",lastADX=",lastADX,",+DI=",plusDI,", previous +DI=",lastPlusDI,", -DI=",minusDI,",previous -DI=",lastMinusDI,",BuyTicket=",BuyTicket,",SellTicket=",SellTicket);

         CloseAllBuyOrders(Symbol(),MagicNumber,UseSlippage);
         Alert("OnTick(): CloseAllBuyOrders()");
         Alert("OnTick(): BuyMarketCount() now returns ",BuyMarketCount(Symbol(),MagicNumber));
         if(BuyMarketCount(Symbol(),MagicNumber)==0)
           {
            BuyTicket=0;
            Alert("OnTick(): reset BuyTicket to ",BuyTicket);
           }
         //}

         //Delete outstanding buy order, if any
         CloseAllBuyStopOrders(Symbol(),MagicNumber);
         Alert("OnTick(): BuyStopCount() now returns ",BuyStopCount(Symbol(),MagicNumber));
         CloseAllBuyLimitOrders(Symbol(),MagicNumber);
         Alert("OnTick(): BuyLimitCount() now returns ",BuyLimitCount(Symbol(),MagicNumber));

         //Open sell order
         OpenPrice=Bid;
         int marketOrderCnt=SellMarketCount(Symbol(),MagicNumber);
         if(marketOrderCnt==0)
           {
            // First order for this MA cross, enter initial ordering logic
            //Calculate lot size
            InitalLotSize=CalcLotSize(DynamicLotSize,EquityRiskPercentage,StopLoss,InitalLotSize);
            InitalLotSize=VerifyLotSize(InitalLotSize);
            Alert("OnTick(): DynamicLotSize=",DynamicLotSize,", InitalLotSize=",InitalLotSize);

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
            SellTicket=OpenSellOrder(Symbol(),InitalLotSize,UseSlippage,MagicNumber);
            AddStopProfit(SellTicket,SellStopLoss,SellTakeProfit);
            Alert("OnTick(): SellTicket=",SellTicket,", TP=",SellTakeProfit,", SL=",SellStopLoss);

            if(SellTicket==-1)
              {
               //Problem in open market sell order, SellTicket set back to 0 to denote no buy order opened.
               Alert("OnTick(): Problem to open sell order, SellTicket=",SellTicket);
               SellTicket=0;
               Alert("OnTick(): Problem to open sell order, now SellTicket reset to ",SellTicket);
              }
           }
         else if(marketOrderCnt>0 && useAntiMartingale)
           {
            // Sell order is already in place, calculate whether follow up order is needed.
            double newLotShouldAdd=CalcMartingaleLotSize(MagicNumber,AntiMartingaleStopLoss,AntiMartingaleMinLotInc);
            bool selected=OrderSelect(SellTicket,SELECT_BY_TICKET);
            if(selected==false)
              {
               int ErrorCode=GetLastError();
               string ErrDesc=ErrorDescription(ErrorCode);

               string ErrAlert=StringConcatenate(Symbol(),"OnTick(): Select First Sell Order - Error: ",ErrorCode,": ",ErrDesc);
               Alert(ErrAlert);

               string ErrLog=StringConcatenate("Ticket: ",SellTicket);
               Print(ErrLog);
              }
            else
              {
               if(newLotShouldAdd>0)
                 {
                  // Create add-on order
                  int addonSellTicket=OpenSellOrder(Symbol(),newLotShouldAdd,UseSlippage,MagicNumber);
                  AddStopProfit(addonSellTicket,OrderStopLoss(),OrderTakeProfit());
                  Alert("OnTick(): addonSellTicket=",addonSellTicket,", TP=",SellTakeProfit,", SL=",SellStopLoss,", lot size=",newLotShouldAdd);
                  if(addonSellTicket==-1)
                    {
                     //Problem in open add-on market sell order
                     Alert("OnTick(): Problem to open add-on sell order, SellTicket=",addonSellTicket);
                    }
                 }
              }

           }
         else
           {
            int ErrorCode=GetLastError();
            string ErrDesc=ErrorDescription(ErrorCode);

            string ErrAlert=StringConcatenate(Symbol(),"OnTick(): Market order count smaller than 0 - Error: ",ErrorCode,": ",ErrDesc);
            Alert(ErrAlert);

            string ErrLog=StringConcatenate("Ticket: ",SellTicket);
            Print(ErrLog);
           }
         //OpenPrice=Bid;
         //Calculate stop loss and take profit
         //         if(StopLoss>0)
         //           {
         //            SellStopLoss=CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);
         //            SellStopLoss=AdjustAboveStopLevel(Symbol(),SellStopLoss);
         //           }
         //         if(TakeProfit>0)
         //           {
         //            SellTakeProfit=CalcSellTakeProfit(Symbol(),TakeProfit,OpenPrice);
         //            SellTakeProfit=AdjustBelowStopLevel(Symbol(),SellTakeProfit);
         //           }
         //
         //         //Calculate lot size
         //         InitalLotSize=CalcLotSize(DynamicLotSize,EquityRiskPercentage,StopLoss,InitalLotSize);
         //         InitalLotSize=VerifyLotSize(InitalLotSize);
         //         Alert("OnTick(): DynamicLotSize=",DynamicLotSize,", InitalLotSize=",InitalLotSize);
         //
         //         //Open sell order
         //         SellTicket=OpenSellOrder(Symbol(),InitalLotSize,UseSlippage,MagicNumber);
         //         AddStopProfit(SellTicket,SellStopLoss,SellTakeProfit);
         //         Alert("OnTick(): SellTicket=",SellTicket,", TP=",SellTakeProfit,", SL=",SellStopLoss);
         //
         //         if(SellTicket==-1)
         //           {
         //            //Problem in open market sell order, SellTicket set back to 0 to denote no sell order opened.
         //            Alert("OnTick(): Problem to open sell order, SellTicket=",SellTicket);
         //            SellTicket=0;
         //            Alert("OnTick(): Problem to open sell order, now SellTicket reset to ",SellTicket);
         //           }
        }
      if(ADXTradeSignal==ADX_CLOSE)
        {
         //Close existing sell position, if any
         CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage);
         Alert("OnTick(): SellMarketCount() now returns ",SellMarketCount(Symbol(),MagicNumber));
         if(SellMarketCount(Symbol(),MagicNumber)==0)
           {
            SellTicket=0;
            Alert("OnTick(): reset SellTicket to ",SellTicket);
           }

         //Delete outstanding sell order, if any
         CloseAllSellStopOrders(Symbol(),MagicNumber);
         Alert("OnTick(): SellStopCount() now returns ",SellStopCount(Symbol(),MagicNumber));
         CloseAllSellLimitOrders(Symbol(),MagicNumber);
         Alert("OnTick(): SellLimitCount() now returns ",SellLimitCount(Symbol(),MagicNumber));

         //Close existing buy position, if any
         CloseAllBuyOrders(Symbol(),MagicNumber,UseSlippage);
         Alert("OnTick(): CloseAllBuyOrders()");
         Alert("OnTick(): BuyMarketCount() now returns ",BuyMarketCount(Symbol(),MagicNumber));
         if(BuyMarketCount(Symbol(),MagicNumber)==0)
           {
            BuyTicket=0;
            Alert("OnTick(): reset BuyTicket to ",BuyTicket);
           }

         //Delete outstanding buy order, if any
         CloseAllBuyStopOrders(Symbol(),MagicNumber);
         Alert("OnTick(): BuyStopCount() now returns ",BuyStopCount(Symbol(),MagicNumber));
         CloseAllBuyLimitOrders(Symbol(),MagicNumber);
         Alert("OnTick(): BuyLimitCount() now returns ",BuyLimitCount(Symbol(),MagicNumber));
        }
      //-- End of trade block
     }

//-- Begin trailing stop adjustment
//TrailingStop and CalMartingaleLotSize is analyzed and adjusted every tick.
   BuyTrailingStop(Symbol(),TrailingStopLoss,TrailingMinProfit,MagicNumber); // Once opened, immediately trigger trailing SL no matter what TP
   SellTrailingStop(Symbol(),TrailingStopLoss,TrailingMinProfit,MagicNumber); // Once opened, immediately trigger trailing SL no matter what TP
                                                                              //-- End of trailing stop adjustment
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
