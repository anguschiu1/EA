//+------------------------------------------------------------------+
//|                                                      Simple MA.mq4 |
//|                             Copyright 2015, Angus Software Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+

//Preprocessor section
#include <stdlib.mqh>

#property copyright "Copyright 2015, Angus Software Corp."
#property link      "https://www.google.com"
#property version   "1.00"
#property strict

//External, variables
extern double LotSize = 0.1;
extern double StopLoss = 50;
extern double TakeProfit = 100;
//extern int PendingPips = 10;

extern int Slippage = 5;
extern int MagicNumber = 123;

extern int FastMAPeriod = 10;
extern int SlowMAPeriod = 20;

//Global variables
int BuyTicket;
int SellTicket;
double UsePoint;
int UseSlippage;
int ErrorCode;
int Ticket;

//init function
int init()
{
   UsePoint = PipPoint(Symbol());
   Alert("UsePoint: ", UsePoint);
   UseSlippage = GetSlippage(Symbol(),Slippage);
   Alert("UseSlippage: ", UseSlippage);
   return(0);
}

//Start function
int start()
{
double BuyStopLoss = 0;
double BuyTakeProfit = 0;
double CloseLots = 0;
double ClosePrice = 0;
bool Closed;
bool Deleted;
double OpenPrice;
double SellStopLoss;
double SellTakeProfit;

   //Moving averages
   if(FastMAPeriod>=SlowMAPeriod)
     {
      Alert("FastMAPeriod is longer than SlowMAPeriod, EA should no proceed.");
      return(0);
     }
   
   double FastMA = iMA(NULL,0, FastMAPeriod,0,MODE_SMA,PRICE_CLOSE,0);
   double SlowMA = iMA(NULL,0, SlowMAPeriod,0,MODE_SMA,PRICE_CLOSE,0);
   
     
   //Buy order
   if(FastMA > SlowMA && BuyTicket == 0)
   {
      Ticket = OrderSelect(SellTicket,SELECT_BY_TICKET);
      if (Ticket == -1)
      {
         string ErrDesc;
         string ErrAlert;
         //string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         //ErrLog = StringConcatenate("Bid:",Bid," Ask",Ask," Price: ",PendingPrice," Lots:",LotSize);
         //Print(ErrLog);
      }
      //Close existing sell position, if any
      if(OrderCloseTime()==0 && SellTicket>0 && OrderType()==OP_SELL)
      {
         CloseLots = OrderLots();
         ClosePrice = Ask;
         
          Closed = OrderClose(SellTicket,CloseLots,ClosePrice,UseSlippage,Red);
         if (Closed == false)
      {
         string ErrDesc;
         string ErrAlert;
         string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         ErrLog = StringConcatenate("Bid:",Bid," Ask",Ask," Price: ",ClosePrice," Lots:",CloseLots);
         Print(ErrLog);
      }
      }
      
      //Delete outstanding sell order, if any
      else if(OrderCloseTime() ==0 && SellTicket>0 && OrderType() == OP_SELLSTOP)
      {
          Deleted = OrderDelete(SellTicket,Red);
          if (Deleted == false)
      {
         string ErrDesc;
         string ErrAlert;
         //string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         //ErrLog = StringConcatenate("Bid:",Bid," Ask",Ask," Price: ",ClosePrice," Lots:",CloseLots);
         //Print(ErrLog);
      }
      }
      
       OpenPrice = Ask;
      //Calculate stop loss and take profit
      if(StopLoss > 0) BuyStopLoss = OpenPrice - (StopLoss * UsePoint);
      if(TakeProfit> 0) BuyTakeProfit = OpenPrice + (TakeProfit * UsePoint);
      
      //Open buy order
      BuyTicket = OrderSend(Symbol(),OP_BUY,LotSize,OpenPrice,UseSlippage,BuyStopLoss,BuyTakeProfit,"Buy Order",MagicNumber, 0,Green);
        if (BuyTicket == -1)
      {
         string ErrDesc;
         string ErrAlert;
         string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         ErrLog = StringConcatenate("Symbol: ",Symbol()," OP_BUY: ",OP_BUY," LotSize: ",LotSize," OpenPrice: ",OpenPrice," UseSlippage: ",UseSlippage," BuyStopLoss: ",BuyStopLoss," BuyTakeProfit: ",BuyTakeProfit," Market Buy Order "," MagicNumber: ",MagicNumber);
         Print(ErrLog);
      }
      SellTicket=0;
   }
   
   //Sell order
   if(FastMA<SlowMA && SellTicket==0)
   {
      Ticket = OrderSelect(BuyTicket,SELECT_BY_TICKET);
      if (Ticket == -1)
      {
         string ErrDesc;
         string ErrAlert;
         //string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         //ErrLog = StringConcatenate("Bid:",Bid," Ask",Ask," Price: ",PendingPrice," Lots:",LotSize);
         //Print(ErrLog);
      }
      //Close existing buy position, if any
     if(OrderCloseTime()==0 && BuyTicket>0 && OrderType()==OP_BUY)
      {
         CloseLots = OrderLots();
         ClosePrice = Bid;
         
         Closed = OrderClose(BuyTicket,CloseLots,ClosePrice,UseSlippage,Red);
         if (Closed == false)
      {
         string ErrDesc;
         string ErrAlert;
         string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         ErrLog = StringConcatenate("Bid:",Bid," Ask",Ask," Price: ",ClosePrice," Lots:",CloseLots);
         Print(ErrLog);
      }
      }
      
      //Delete outstanding buy order, if any
      else if(OrderCloseTime() ==0 && BuyTicket>0 && OrderType() == OP_BUYSTOP)
      {
         Deleted = OrderDelete(BuyTicket,Red);
          if (Deleted == false)
      {
         string ErrDesc;
         string ErrAlert;
         //string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         //ErrLog = StringConcatenate("Bid:",Bid," Ask",Ask," Price: ",ClosePrice," Lots:",CloseLots);
         //Print(ErrLog);
      }
      }
      
      OpenPrice = Bid;
      //Calculate stop loss and take profit
      if(StopLoss > 0)  SellStopLoss = OpenPrice + (StopLoss * UsePoint);
      if(TakeProfit> 0)  SellTakeProfit = OpenPrice - (TakeProfit * UsePoint);
      
      //Open sell order
      SellTicket = OrderSend(Symbol(),OP_SELL,LotSize,OpenPrice,UseSlippage,SellStopLoss,SellTakeProfit,"Sell Order",MagicNumber,0, Red);
       if (SellTicket == -1)
      {
         string ErrDesc;
         string ErrAlert;
         string ErrLog;
         ErrorCode = GetLastError();
         ErrDesc = ErrorDescription(ErrorCode);
         ErrAlert = StringConcatenate("OrderSelect error - Error ",ErrorCode,":",ErrDesc);
         Alert(ErrAlert);
         ErrLog = StringConcatenate("Symbol: ",Symbol()," OP_SELL: ",OP_SELL," LotSize: ",LotSize," OpenPrice: ",OpenPrice," UseSlippage: ",UseSlippage," SellStopLoss: ",SellTakeProfit," SellTakeProfit: ",BuyTakeProfit," Market Sell Order "," MagicNumber: ",MagicNumber);
         Print(ErrLog);
      }
      BuyTicket=0;
   }
   return(0);
}


// Pip Point Function
double PipPoint(string Currency)
{
   double CalcPoint;
   int CalcDigits = MarketInfo(Currency,MODE_DIGITS);
   Alert("MarketInfo(Currency,MODE_DIGITS): ", CalcDigits);
   if (CalcDigits == 1) 
      CalcPoint = 1;
   if (CalcDigits == 2 ||CalcDigits == 3) 
      CalcPoint = 0.01;
   else if(CalcDigits == 4 || CalcDigits ==5) 
       CalcPoint = 0.0001;
   return (CalcPoint);
}

// GetSlippage Function
int GetSlippage(string Currency,int SlippagePips)
{
   double CalcSlippage;
   int CalcDigits = MarketInfo(Currency,MODE_DIGITS);
   if (CalcDigits == 1)
      CalcSlippage = SlippagePips *10;
   if (CalcDigits == 2 ||CalcDigits == 4) 
      CalcSlippage = SlippagePips;
   else if(CalcDigits == 3 || CalcDigits ==5) 
      CalcSlippage = SlippagePips *10;
   return (CalcSlippage);
}


////+------------------------------------------------------------------+
////| Expert initialization function                                   |
////+------------------------------------------------------------------+
//int OnInit()
//  {
////---
//   
////---
//   return(INIT_SUCCEEDED);
//  }
////+------------------------------------------------------------------+
////| Expert deinitialization function                                 |
////+------------------------------------------------------------------+
//void OnDeinit(const int reason)
//  {
////---
//   
//  }
////+------------------------------------------------------------------+
////| Expert tick function                                             |
////+------------------------------------------------------------------+
//void OnTick()
//  {
////---
//   
//  }
////+------------------------------------------------------------------+
////| Tester function                                                  |
////+------------------------------------------------------------------+
//double OnTester()
//  {
////---
//   double ret=0.0;
////---
//
////---
//   return(ret);
//  }
////+------------------------------------------------------------------+
////| ChartEvent function                                              |
////+------------------------------------------------------------------+
//void OnChartEvent(const int id,
//                  const long &lparam,
//                  const double &dparam,
//                  const string &sparam)
//  {
////---
//   
//  }
