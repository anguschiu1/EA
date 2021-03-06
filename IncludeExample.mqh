//+------------------------------------------------------------------+
//|                                               IncludeExample.mqh |
//|                                                     Andrew Young |
//|                                   http://www.easyexpertforex.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.easyexpertforex.com"

#include <stdlib.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcMartingaleLotSize(int argMagicNumber,double argDDTolerence,double argLotSizeIncrement)
  {
   double unrealizedProfitTotal=0,lotSizeTotal=0,result=0;
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";

   RefreshRates();
//int x = TotalOrderCount(Symbol(),argMagicNumber);
//Alert("CalcMartingaleLotSize: Total order count for symbol ",Symbol()," is ",x);
   for(int count=0;count<=OrdersTotal()-1;count++)
     {
      Alert("CalcMartingaleLotSize: count=",count,", OrdersTotal=",OrdersTotal());
      bool selected=OrderSelect(count,SELECT_BY_POS);

      if(selected==false)
        {
         ErrorCode=GetLastError();
         ErrDesc=ErrorDescription(ErrorCode);

         ErrAlert=StringConcatenate(Symbol()," Select order to count order - Error: ",ErrorCode,": ",ErrDesc);
         Alert("CalcMartingaleLotSize: ",ErrAlert);

         //string ErrLog = StringConcatenate("Ticket: ",argTicket);
         //Print(ErrLog);
        }
      else
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==argMagicNumber)
           {
            unrealizedProfitTotal+=OrderProfit();
            lotSizeTotal+=OrderLots();
            Alert("CalcMartingaleLotSize: Magic number matched, count=",count,", OrdersTotal=",OrdersTotal(),", unealizedProfitTotal=",unrealizedProfitTotal,", lotSizeTotal=",lotSizeTotal);
           }
        }
      Alert("CalcMartingaleLotSize: OrderSymbol()=",OrderSymbol(),", Symbol()=",Symbol());
      Alert("CalcMartingaleLotSize: Adding all orders together, unealizedProfitTotal=",unrealizedProfitTotal,", lotSizeTotal=",lotSizeTotal);
     }
   double TickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   if(Point==0.001 || Point==0.00001) TickValue*=10;

   double lot_should_add=(unrealizedProfitTotal/TickValue)/argDDTolerence-lotSizeTotal;
   Alert("CalcMartingaleLotSize: unrealizedProfitTotal=", unrealizedProfitTotal,", lotSizeTotal=",lotSizeTotal,", argDDTolerence=",argDDTolerence,", tick value=",TickValue,", hence additional number of lot should add is ",lot_should_add);

   if(lot_should_add>0)
     {
      result=VerifyLotSize(lot_should_add);
      Alert("CalcMartingaleLotSize: would suggest to place an add-up order with lot size of ",result);
     }
   else
     {
      Alert("CalcMartingaleLotSize: lot_should_add equal or smaller than 0 (may be losing?), should not place new add-up order.");
     }
   if(result>=VerifyLotSize(argLotSizeIncrement))
     {
      Alert("CalcMartingaleLotSize: suggested lot size of ",result," is LARGER than minimum increment requirement, SHOULD proceed to add order");
      return(result);
     }
   else
     {
      Alert("CalcMartingaleLotSize: suggested lot size of ",result," is SMALLER than minimum increment requirement,should NOT proceed to add order");
      return(0);
     }
  }
//Function to calculate lot size for the order based on :
// Dynamic: the specified equity percentage to account equity AND the SL pips
// Fixed: the specified fixed lot size
double CalcLotSize(bool argDynamicLotSize,double argEquityPercent,double argStopLoss,double argFixedLotSize)
  {
   double LotSize;
   if(argDynamicLotSize==true && argStopLoss>0)
     {
      double RiskAmount= AccountEquity() *(argEquityPercent/100);
      double TickValue = MarketInfo(Symbol(),MODE_TICKVALUE);
      if(Point== 0.001|| Point == 0.00001) TickValue *= 10;
      LotSize =(RiskAmount/argStopLoss)/TickValue;
     }
   else LotSize=argFixedLotSize;

   return(LotSize);
  }
// Function to avoid invalid lot size (too big or too small) entered to the order
double VerifyLotSize(double argLotSize)
  {
   if(argLotSize<MarketInfo(Symbol(),MODE_MINLOT))
     {
      Alert("Order lot size is too small, round up from ",argLotSize," lot to ",MarketInfo(Symbol(),MODE_MINLOT)," lot.");
      argLotSize=MarketInfo(Symbol(),MODE_MINLOT);
     }
   else if(argLotSize>MarketInfo(Symbol(),MODE_MAXLOT))
     {
      Alert("Order lot size is too big, round down from ",argLotSize," lot to ",MarketInfo(Symbol(),MODE_MAXLOT)," lot.");
      argLotSize=MarketInfo(Symbol(),MODE_MAXLOT);
     }

   if(MarketInfo(Symbol(),MODE_LOTSTEP)==0.1)
     {
      argLotSize=NormalizeDouble(argLotSize,1);
      Alert("Lot rounded to ",argLotSize);
     }
   else
     {
      argLotSize=NormalizeDouble(argLotSize,2);
      Alert("Lot rounded to ",argLotSize);
     }
   return(argLotSize);
  }
// Function to open MARKET BUY order, and return ticket number for success open order, or -1 for failed open order
int OpenBuyOrder(string argSymbol,double argLotSize,int argSlippage,int argMagicNumber,string argComment="Buy Order")
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   while(IsTradeContextBusy()) Sleep(10); //To wait until process thread released

                                          // Place Market Buy Order
   int Ticket=OrderSend(argSymbol,OP_BUY,argLotSize,MarketInfo(argSymbol,MODE_ASK),argSlippage,0,0,argComment,argMagicNumber,0,Green);
Alert("OpenBuyOrder(): lot size=",argLotSize,", Ask=",MarketInfo(argSymbol,MODE_ASK),", slippage=",argSlippage,", comment=",argComment,", magicNumber=",argMagicNumber);
// Error Handling
   if(Ticket==-1)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Open Buy Order - Error	",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Bid: ",MarketInfo(argSymbol,MODE_BID)," Ask: ",MarketInfo(argSymbol,MODE_ASK)," Lots: ",argLotSize);
      Print(ErrLog);
     }

   return(Ticket);
  }
// Function to open MARKET SELL order, and return ticket number for success open order, or -1 for failed open order
int OpenSellOrder(string argSymbol,double argLotSize,int argSlippage,int argMagicNumber,string argComment="Sell Order")
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   while(IsTradeContextBusy()) Sleep(10);

// Place Sell Order
   int Ticket=OrderSend(argSymbol,OP_SELL,argLotSize,MarketInfo(argSymbol,MODE_BID),argSlippage,0,0,argComment,argMagicNumber,0,Red);
Alert("OpenSellOrder(): lot size=",argLotSize,", Ask=",MarketInfo(argSymbol,MODE_BID),", slippage=",argSlippage,", comment=",argComment,", magicNumber=",argMagicNumber);

// Error Handling
   if(Ticket==-1)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Open Sell Order - Error ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Bid: ",MarketInfo(argSymbol,MODE_BID)," Ask: ",MarketInfo(argSymbol,MODE_ASK)," Lots: ",argLotSize);
      Print(ErrLog);
     }

   return(Ticket);
  }
// Function to open BUY STOP order, and return ticket number for success open order, or -1 for failed open order
int OpenBuyStopOrder(string argSymbol,double argLotSize,double argPendingPrice,double argStopLoss,double argTakeProfit,int argSlippage,
                     int argMagicNumber,datetime argExpiration=0,string argComment="Buy Stop Order")
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   while(IsTradeContextBusy()) Sleep(10);

// Place Buy Stop Order
   int Ticket=OrderSend(argSymbol,OP_BUYSTOP,argLotSize,argPendingPrice,argSlippage,argStopLoss,argTakeProfit,argComment,argMagicNumber,argExpiration,Green);

// Error Handling
   if(Ticket==-1)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Open Buy Stop Order - Error ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Ask: ",MarketInfo(argSymbol,MODE_ASK)," Lots: ",argLotSize,
                               " Price: ",argPendingPrice," Stop: ",argStopLoss," Profit: ",argTakeProfit," Expiration: ",TimeToStr(argExpiration));
      Print(ErrLog);
     }

   return(Ticket);
  }
// Function to open SELL STOP order, and return ticket number for success open order, or -1 for failed open order
int OpenSellStopOrder(string argSymbol,double argLotSize,double argPendingPrice,double argStopLoss,double argTakeProfit,int argSlippage,
                      int argMagicNumber,datetime argExpiration=0,string argComment="Sell Stop Order")
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   while(IsTradeContextBusy()) Sleep(10);

// Place Sell Stop Order
   int Ticket=OrderSend(argSymbol,OP_SELLSTOP,argLotSize,argPendingPrice,argSlippage,argStopLoss,argTakeProfit,argComment,argMagicNumber,argExpiration,Red);

// Error Handling
   if(Ticket==-1)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Open Sell Stop Order - Error ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Bid: ",MarketInfo(argSymbol,MODE_BID)," Lots: ",argLotSize,
                               " Price: ",argPendingPrice," Stop: ",argStopLoss," Profit: ",argTakeProfit," Expiration: ",TimeToStr(argExpiration));
      Print(ErrLog);
     }

   return(Ticket);
  }
// Function to open BUY LIMIT order, and return ticket number for success open order, or -1 for failed open order
int OpenBuyLimitOrder(string argSymbol,double argLotSize,double argPendingPrice,double argStopLoss,double argTakeProfit,int argSlippage,
                      int argMagicNumber,datetime argExpiration,string argComment="Buy Limit Order")
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   while(IsTradeContextBusy()) Sleep(10);

// Place Buy Limit Order
   int Ticket=OrderSend(argSymbol,OP_BUYLIMIT,argLotSize,argPendingPrice,argSlippage,argStopLoss,argTakeProfit,argComment,argMagicNumber,argExpiration,Green);

// Error Handling
   if(Ticket==-1)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Open Buy Limit Order - Error ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Bid: ",MarketInfo(argSymbol,MODE_BID)," Lots: ",argLotSize,
                               " Price: ",argPendingPrice," Stop: ",argStopLoss," Profit: ",argTakeProfit," Expiration: ",TimeToStr(argExpiration));
      Print(ErrLog);
     }

   return(Ticket);
  }
// Function to open SELL LIMIT order, and return ticket number for success open order, or -1 for failed open order.
int OpenSellLimitOrder(string argSymbol,double argLotSize,double argPendingPrice,double argStopLoss,double argTakeProfit,int argSlippage,
                       int argMagicNumber,datetime argExpiration,string argComment="Sell Limit Order")
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   while(IsTradeContextBusy()) Sleep(10);

// Place Sell Limit Order
   int Ticket=OrderSend(argSymbol,OP_SELLLIMIT,argLotSize,argPendingPrice,argSlippage,argStopLoss,argTakeProfit,argComment,argMagicNumber,argExpiration,Red);

// Error Handling
   if(Ticket==-1)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Open Sell Stop Order - Error ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Ask: ",MarketInfo(argSymbol,MODE_ASK)," Lots: ",argLotSize,
                               " Price: ",argPendingPrice," Stop: ",argStopLoss," Profit: ",argTakeProfit," Expiration: ",TimeToStr(argExpiration));
      Print(ErrLog);
     }

   return(Ticket);
  }
//Function to return number of digit calculated for this currency pair. Not more useful then MarketInfo()
int DecimalPoint(string Currency)
  {
   int CalcDigits=(int)MarketInfo(Currency,MODE_DIGITS);
   return(CalcDigits);
  }
//Function to return correct pips value of this currency pair
double PipPoint(string Currency)
  {
   double CalcPoint;
   int CalcDigits= (int)MarketInfo(Currency,MODE_DIGITS);
   if(CalcDigits == 2|| CalcDigits == 3) CalcPoint = 0.01;
   else if(CalcDigits==4 || CalcDigits==5) CalcPoint=0.0001;
   return(CalcPoint);
  }
//Function to return slippage, in PIPS, for this currency pair
int GetSlippage(string Currency,int SlippagePips)
  {
   int CalcSlippage;
   int CalcDigits= (int) MarketInfo(Currency,MODE_DIGITS);
   if(CalcDigits == 2|| CalcDigits == 4)  CalcSlippage = SlippagePips;
   else if(CalcDigits==3 || CalcDigits==5) CalcSlippage=SlippagePips*10;
   return(CalcSlippage);
  }
// Function to square a long position
bool CloseBuyOrder(string argSymbol,int argCloseTicket,int argSlippage)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   bool Closed=false;

   bool selected=OrderSelect(argCloseTicket,SELECT_BY_TICKET);
   if(selected==false)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Select Buy Order - Error: ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Ticket: ",argCloseTicket);
      Print(ErrLog);
     }
   if(selected && (OrderCloseTime()==0)) //No close time -> not a closed order
     {
      double CloseLots=OrderLots();

      while(IsTradeContextBusy()) Sleep(10);

      double ClosePrice=MarketInfo(argSymbol,MODE_BID); //Obtain latest market bid pricing. Long Ask Short Bid, close buy is a short action, hense use bid price

      Closed=OrderClose(argCloseTicket,CloseLots,ClosePrice,argSlippage,Green);

      if(Closed==false)
        {
         ErrorCode=GetLastError();
         ErrDesc=ErrorDescription(ErrorCode);

         ErrAlert=StringConcatenate(Symbol()," Close Buy Order - Error: ",ErrorCode,": ",ErrDesc);
         Alert(ErrAlert);

         ErrLog=StringConcatenate("Ticket: ",argCloseTicket," Bid: ",MarketInfo(argSymbol,MODE_BID));
         Print(ErrLog);
        }
     }
   return(Closed);
  }
//Function to square a short position
bool CloseSellOrder(string argSymbol,int argCloseTicket,int argSlippage)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   bool Closed=false;

   bool selected=OrderSelect(argCloseTicket,SELECT_BY_TICKET);
   if(selected==false)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Select Sell Order - Error: ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Ticket: ",argCloseTicket);
      Print(ErrLog);
     }
   if(selected && (OrderCloseTime()==0))
     {
      double CloseLots=OrderLots();

      while(IsTradeContextBusy()) Sleep(10);

      double ClosePrice=MarketInfo(argSymbol,MODE_ASK);

      Closed=OrderClose(argCloseTicket,CloseLots,ClosePrice,argSlippage,Red);

      if(Closed==false)
        {
         ErrorCode=GetLastError();
         ErrDesc=ErrorDescription(ErrorCode);

         ErrAlert=StringConcatenate(Symbol()," Close Sell Order - Error: ",ErrorCode,": ",ErrDesc);
         Alert(ErrAlert);

         ErrLog=StringConcatenate("Ticket: ",argCloseTicket," Ask: ",MarketInfo(argSymbol,MODE_ASK));
         Print(ErrLog);
        }
     }
   return(Closed);
  }
//Function to close a pending order (i.e. to delete an unexecuted order)
bool ClosePendingOrder(string argSymbol,int argCloseTicket)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   bool Deleted=false;

   bool selected=OrderSelect(argCloseTicket,SELECT_BY_TICKET);
   if(selected==false)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Select pending Order - Error: ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Ticket: ",argCloseTicket);
      Print(ErrLog);
     }
   if(selected && (OrderCloseTime()==0))
     {
      while(IsTradeContextBusy()) Sleep(10);

      Deleted=OrderDelete(argCloseTicket,Red);

      if(Deleted==false)
        {
         ErrorCode=GetLastError();
         ErrDesc=ErrorDescription(ErrorCode);

         ErrAlert=StringConcatenate(Symbol()," Close Pending Order - Error: ",ErrorCode,": ",ErrDesc);
         Alert(ErrAlert);

         ErrLog=StringConcatenate("Ticket: ",argCloseTicket," Bid: ",MarketInfo(argSymbol,MODE_BID)," Ask: ",MarketInfo(argSymbol,MODE_ASK));
         Print(ErrLog);
        }
     }
   return(Deleted);
  }
// Function to return a buy SL price from provided open price
double CalcBuyStopLoss(string argSymbol,double argStopLoss,double argOpenPrice)
  {
   if(argStopLoss == 0) return(0);

   double BuyStopLoss=argOpenPrice -(argStopLoss*PipPoint(argSymbol));
   return(BuyStopLoss);
  }
// Function to return a sell SL price from provided open price	
double CalcSellStopLoss(string argSymbol,double argStopLoss,double argOpenPrice)
  {
   if(argStopLoss == 0) return(0);

   double SellStopLoss=argOpenPrice+(argStopLoss*PipPoint(argSymbol));
   return(SellStopLoss);
  }
// Function to return a buy TP price from provided open price
double CalcBuyTakeProfit(string argSymbol,double argTakeProfit,double argOpenPrice)
  {
   if(argTakeProfit == 0) return(0);

   double BuyTakeProfit=argOpenPrice+(argTakeProfit*PipPoint(argSymbol));
   return(BuyTakeProfit);
  }
// Function to return a sell TP price from provided open price
double CalcSellTakeProfit(string argSymbol,double argTakeProfit,double argOpenPrice)
  {
   if(argTakeProfit == 0) return(0);

   double SellTakeProfit=argOpenPrice -(argTakeProfit*PipPoint(argSymbol));
   return(SellTakeProfit);
  }
//Function to verify provided upper stop level using latest market ask price
bool VerifyUpperStopLevel(string argSymbol,double argVerifyPrice,double argOpenPrice=0)
  {
   double StopLevel=MarketInfo(argSymbol,MODE_STOPLEVEL)*Point;
   double OpenPrice= 0;

   if(argOpenPrice== 0) OpenPrice = MarketInfo(argSymbol,MODE_ASK);
   else OpenPrice = argOpenPrice;

   double UpperStopLevel=OpenPrice+StopLevel;
   bool StopVerify=false;

   if(argVerifyPrice>UpperStopLevel) StopVerify=true;
   else StopVerify=false;

   return(StopVerify);
  }
//Function to verify provided lower stop level using latest market bid price
bool VerifyLowerStopLevel(string argSymbol,double argVerifyPrice,double argOpenPrice=0)
  {
   double StopLevel=MarketInfo(argSymbol,MODE_STOPLEVEL)*Point;
   double OpenPrice=0;
   double LowerStopLevel=0;
   bool StopVerify=false;

   if(argOpenPrice== 0) OpenPrice = MarketInfo(argSymbol,MODE_BID);
   else OpenPrice = argOpenPrice;

   LowerStopLevel=OpenPrice-StopLevel;

   if(argVerifyPrice<LowerStopLevel) StopVerify=true;
   else StopVerify=false;

   return(StopVerify);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double AdjustAboveStopLevel(string argSymbol,double argAdjustPrice,int argAddPips=0,double argOpenPrice=0)
  {
   double StopLevel=MarketInfo(argSymbol,MODE_STOPLEVEL)*Point;
   double OpenPrice=0;

   if(argOpenPrice== 0) OpenPrice = MarketInfo(argSymbol,MODE_ASK);
   else OpenPrice = argOpenPrice;

   double UpperStopLevel=OpenPrice+StopLevel;
   double AdjustedPrice =0;

   if(argAdjustPrice<=UpperStopLevel)
     {
      AdjustedPrice=UpperStopLevel+(argAddPips*PipPoint(argSymbol));
      Alert("AdjustPrice is ",argAdjustPrice," which is smaller than UpperStopLevel ",UpperStopLevel,", upper stop level adjusted to ",AdjustedPrice);
     }
   else AdjustedPrice=argAdjustPrice;

   return(AdjustedPrice);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double AdjustBelowStopLevel(string argSymbol,double argAdjustPrice,int argAddPips=0,double argOpenPrice=0)
  {
   double StopLevel=MarketInfo(argSymbol,MODE_STOPLEVEL)*Point;
   double OpenPrice= 0;

   if(argOpenPrice== 0) OpenPrice = MarketInfo(argSymbol,MODE_BID);
   else OpenPrice = argOpenPrice;

   double LowerStopLevel=OpenPrice-StopLevel;
   double AdjustedPrice = 0;
   if(argAdjustPrice>=LowerStopLevel)
     {
      AdjustedPrice=LowerStopLevel -(argAddPips*PipPoint(argSymbol));
      Alert("AdjustPrice is ",argAdjustPrice," which is higher than LowerStopLevel ",LowerStopLevel,", lower stop level adjusted to ",AdjustedPrice);
     }
   else AdjustedPrice=argAdjustPrice;

   return(AdjustedPrice);
  }
// Function that add TP/SL to an opened order
bool AddStopProfit(int argTicket,double argStopLoss,double argTakeProfit)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   bool selected=OrderSelect(argTicket,SELECT_BY_TICKET);
   if(selected==false)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate(Symbol()," Select order to add Stop/Profit - Error: ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Ticket: ",argTicket);
      Print(ErrLog);
     }
   double OpenPrice=OrderOpenPrice();

   while(IsTradeContextBusy()) Sleep(10);

// Modify Order
   bool TicketMod=OrderModify(argTicket,OrderOpenPrice(),argStopLoss,argTakeProfit,0);

// Error Handling
   if(TicketMod==false)
     {
      ErrorCode=GetLastError();
      ErrDesc=ErrorDescription(ErrorCode);

      ErrAlert=StringConcatenate("Add Stop/Profit - Error ",ErrorCode,": ",ErrDesc);
      Alert(ErrAlert);

      ErrLog=StringConcatenate("Bid: ",MarketInfo(OrderSymbol(),MODE_BID)," Ask: ",MarketInfo(OrderSymbol(),MODE_ASK)," Ticket: ",argTicket," Stop: ",argStopLoss," Profit: ",argTakeProfit);
      Print(ErrLog);
     }

   return(TicketMod);
  }
// Function that return order count for a specified symbol and magic number
int TotalOrderCount(string argSymbol,int argMagicNumber)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   int OrderCount=0;

   Alert("OrdersTotal()=",OrdersTotal());
   for(int Counter=0; Counter<=OrdersTotal()-1; Counter++)
     {
      bool selected=OrderSelect(Counter,SELECT_BY_POS);
      if(selected==false)
        {
         ErrorCode=GetLastError();
         ErrDesc=ErrorDescription(ErrorCode);

         ErrAlert=StringConcatenate(Symbol()," Select order to count order - Error: ",ErrorCode,": ",ErrDesc);
         Alert(ErrAlert);

         //string ErrLog = StringConcatenate("Ticket: ",argTicket);
         //Print(ErrLog);
        }
      else
        {
         if(OrderMagicNumber()==argMagicNumber && OrderSymbol()==argSymbol)
           {
            OrderCount++;
           }
        }
     }
   return(OrderCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int OrderCount(string argSymbol,int argMagicNumber,int argOrderType)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   int OrderCount=0;
   Alert("OrderCount(): OrdersTotal() is ",OrdersTotal());
   if(OrdersTotal()<=0)
     {
      Alert("OrderCount(): There is no opened orders.");
     }
   else
     {
      for(int Counter=0; Counter<=OrdersTotal()-1; Counter++)
        {
         bool selected=OrderSelect(Counter,SELECT_BY_POS);
         Alert("OrderCount(): OrderSelect() is ",selected);
         if(selected==false)
           {
            ErrorCode=GetLastError();
            ErrDesc=ErrorDescription(ErrorCode);

            ErrAlert=StringConcatenate(Symbol()," Select order to count - Error: ",ErrorCode,": ",ErrDesc);
            Alert(ErrAlert);

            OrderCount=-1;
            break;

            //string ErrLog = StringConcatenate("Ticket: ",argTicket);
            //Print(ErrLog);
           }
         else
           {
            if(OrderMagicNumber()==argMagicNumber && OrderSymbol()==argSymbol && OrderType()==argOrderType)
              {
               OrderCount++;
              }
           }
        }
     }
   Alert("OrderCount(): argOrderType=",argOrderType," order count=",OrderCount," argMagicNumber=",argMagicNumber);
   return(OrderCount);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int BuyMarketCount(string argSymbol,int argMagicNumber)
  {
   return(OrderCount(argSymbol,argMagicNumber,OP_BUY));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SellMarketCount(string argSymbol,int argMagicNumber)
  {
   return(OrderCount(argSymbol,argMagicNumber,OP_SELL));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int BuyStopCount(string argSymbol,int argMagicNumber)
  {
   return(OrderCount(argSymbol,argMagicNumber,OP_BUYSTOP));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SellStopCount(string argSymbol,int argMagicNumber)
  {
   return(OrderCount(argSymbol,argMagicNumber,OP_SELLSTOP));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int BuyLimitCount(string argSymbol,int argMagicNumber)
  {
   return(OrderCount(argSymbol,argMagicNumber,OP_BUYLIMIT));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SellLimitCount(string argSymbol,int argMagicNumber)
  {
   return(OrderCount(argSymbol,argMagicNumber,OP_SELLLIMIT));
  }
//+------------------------------------------------------------------+
//| Generic close all order function                                |
//+------------------------------------------------------------------+
void CloseAllOrders(string argSymbol,int argMagicNumber,int argSlippage,int argOrderType)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   if(OrdersTotal()<=0)
     {
      Alert("CloseAllOrders(): No orders exist here, OrdersTotal()=",OrdersTotal());
     }
   else
     {
      for(int Counter=0; Counter<=OrdersTotal()-1; Counter++)
        {
         bool selected=OrderSelect(Counter,SELECT_BY_POS);
         if(selected==false)
           {
            ErrorCode=GetLastError();
            ErrDesc=ErrorDescription(ErrorCode);

            ErrAlert=StringConcatenate(Symbol()," Order type =",argOrderType,", Select order to close all opened orders - Error: ",ErrorCode,": ",ErrDesc);
            Alert(ErrAlert);

            //string ErrLog = StringConcatenate("Ticket: ",argTicket);
            //Print(ErrLog);
           }

         if(selected && OrderMagicNumber()==argMagicNumber && OrderSymbol()==argSymbol && OrderType()==argOrderType)
           {
            // Close Order
            int CloseTicket=OrderTicket();
            double CloseLots=OrderLots();

            while(IsTradeContextBusy()) Sleep(10);
            double ClosePrice= MarketInfo(argSymbol,MODE_ASK);
            
            if(argOrderType==OP_BUY || argOrderType==OP_BUYLIMIT || argOrderType==OP_BUYSTOP)
              {
               ClosePrice=MarketInfo(argSymbol,MODE_BID);
              }
            else if(argOrderType==OP_SELL || argOrderType==OP_SELLLIMIT || argOrderType==OP_SELLSTOP)
              {
               ClosePrice=MarketInfo(argSymbol,MODE_ASK);
              }

            bool Closed=OrderClose(CloseTicket,CloseLots,ClosePrice,argSlippage,Red);

            // Error Handling
            if(Closed==false)
              {
               ErrorCode=GetLastError();
               ErrDesc=ErrorDescription(ErrorCode);

               ErrAlert=StringConcatenate("Close All Orders in order type =",argOrderType," - Error ",ErrorCode,": ",ErrDesc);
               Alert(ErrAlert);

               ErrLog=StringConcatenate("Bid: ",MarketInfo(argSymbol,MODE_BID)," ,Ask: ",MarketInfo(argSymbol,MODE_ASK)," Ticket: ",CloseTicket," Price: ",ClosePrice);
               Print(ErrLog);
              }
            else Counter--;
           }
        }
     }
  }
// Function to close all opened buy orders in specific symbol, magic number and slippage constraint
void CloseAllBuyOrders(string argSymbol,int argMagicNumber,int argSlippage)
  {
   CloseAllOrders(argSymbol,argMagicNumber,argSlippage,OP_BUY);
  }
// Function to close all opened sell orders in specific symbol, magic number and slippage constraint
void CloseAllSellOrders(string argSymbol,int argMagicNumber,int argSlippage)
  {
   CloseAllOrders(argSymbol,argMagicNumber,argSlippage,OP_SELL);
  }
//+------------------------------------------------------------------------------------------+
//| Generic function to close all pending orders in same order type, magicnumbers and symbol |
//+------------------------------------------------------------------------------------------+
void CloseAllPendingOrders(string argSymbol,int argMagicNumber,int argOrderType)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   if(OrdersTotal()==0)
     {
      Alert("CloseAllPendingOrders(): There are no any orders.");
     }
   else
     {
      for(int Counter=0; Counter<=OrdersTotal()-1; Counter++)
        {
         bool selected=OrderSelect(Counter,SELECT_BY_POS);
         if(selected==false)
           {
            ErrorCode=GetLastError();
            ErrDesc=ErrorDescription(ErrorCode);

            ErrAlert=StringConcatenate(Symbol()," Select order to delete all existing pending orders - Error: ",ErrorCode,": ",ErrDesc);
            Alert(ErrAlert);

            //string ErrLog = StringConcatenate("Ticket: ",argTicket);
            //Print(ErrLog);
           }
         if(selected && OrderMagicNumber()==argMagicNumber && OrderSymbol()==argSymbol && OrderType()==argOrderType)
           {
            // Delete Order
            int CloseTicket=OrderTicket();

            while(IsTradeContextBusy()) Sleep(10);

            bool Closed=OrderDelete(CloseTicket,Red);

            // Error Handling
            if(Closed==false)
              {
               ErrorCode=GetLastError();
               ErrDesc=ErrorDescription(ErrorCode);

               ErrAlert=StringConcatenate("Delete All pending orders, order type=",argOrderType," - Error ",ErrorCode,": ",ErrDesc);
               Alert(ErrAlert);

               ErrLog=StringConcatenate("Bid: ",MarketInfo(argSymbol,MODE_BID)," Ask: ",MarketInfo(argSymbol,MODE_ASK)," Ticket: ",CloseTicket);
               Print(ErrLog);
              }
            else Counter--;
           }
        }
     }
  }
// Function to delete all existing buy stop order specified by symbol and magic number
void CloseAllBuyStopOrders(string argSymbol,int argMagicNumber)
  {
   CloseAllPendingOrders(argSymbol,argMagicNumber,OP_BUYSTOP);
  }
// Function to delete all existing sell stop orders specified by symbol and magic number
void CloseAllSellStopOrders(string argSymbol,int argMagicNumber)
  {
   CloseAllPendingOrders(argSymbol,argMagicNumber,OP_SELLSTOP);
  }
// Function to delete all buy limit orders specified by symbol and magic number
void CloseAllBuyLimitOrders(string argSymbol,int argMagicNumber)
  {
   CloseAllPendingOrders(argSymbol,argMagicNumber,OP_BUYLIMIT);
  }
// Function to delete all existing sell limit orders specified by symbol and magic number
void CloseAllSellLimitOrders(string argSymbol,int argMagicNumber)
  {
   CloseAllPendingOrders(argSymbol,argMagicNumber,OP_SELLLIMIT);
  }
// Function to enable trailing stop for all buy order(s) specified by symbol and magic number	
// argTrailingStop: pips of trailing stop
// argMinProfit: minimum pips of profits to trigger trailing stop behavior
void BuyTrailingStop(string argSymbol,double argTrailingStop,double argMinProfit,int argMagicNumber)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   for(int Counter=0; Counter<=OrdersTotal()-1; Counter++)
     {
      bool selected=OrderSelect(Counter,SELECT_BY_POS);
      if(selected==false)
        {
         ErrorCode=GetLastError();
         ErrDesc=ErrorDescription(ErrorCode);

         ErrAlert=StringConcatenate(Symbol()," Select order to set buy order trailing stop - Error: ",ErrorCode,": ",ErrDesc);
         Alert(ErrAlert);

         //string ErrLog = StringConcatenate("Ticket: ",argTicket);
         //Print(ErrLog);
        }
      else
        {

         // Calculate Max Stop and Min Profit
         double MaxStopLoss=MarketInfo(argSymbol,MODE_BID) -(argTrailingStop*PipPoint(argSymbol));
         MaxStopLoss=NormalizeDouble(MaxStopLoss,(int)MarketInfo(OrderSymbol(),MODE_DIGITS));

         double CurrentStop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(OrderSymbol(),MODE_DIGITS));

         double PipsProfit= MarketInfo(argSymbol,MODE_BID)-OrderOpenPrice();
         double MinProfit = argMinProfit * PipPoint(argSymbol);

         // Modify Stop
         if(OrderMagicNumber()==argMagicNumber && OrderSymbol()==argSymbol && OrderType()==OP_BUY && CurrentStop<MaxStopLoss && PipsProfit>=MinProfit)
           {
            bool Trailed=OrderModify(OrderTicket(),OrderOpenPrice(),MaxStopLoss,OrderTakeProfit(),0);
            Alert("BuyTrailingStop modified the SL, Bid=",Bid,", SL=",MaxStopLoss,", TP=",OrderTakeProfit());

            // Error Handling
            if(Trailed==false)
              {
               ErrorCode=GetLastError();
               ErrDesc=ErrorDescription(ErrorCode);

               ErrAlert=StringConcatenate("Buy Trailing Stop - Error ",ErrorCode,": ",ErrDesc);
               Alert(ErrAlert);

               ErrLog=StringConcatenate("Bid: ",MarketInfo(argSymbol,MODE_BID)," Ticket: ",OrderTicket()," Stop: ",OrderStopLoss()," Trail: ",MaxStopLoss);
               Print(ErrLog);
              }
           }
        }
     }
  }
// Function to enable trailing stop for all sell order(s) specified by symbol and magic number		
// argTrailingStop: pips of trailing stop
// argMinProfit: minimum pips of profits to trigger trailing stop behavior
void SellTrailingStop(string argSymbol,double argTrailingStop,double argMinProfit,int argMagicNumber)
  {
   int ErrorCode=0;
   string ErrDesc= "";
   string ErrLog = "";
   string ErrAlert="";
   for(int Counter=0; Counter<=OrdersTotal()-1; Counter++)
     {
      bool selected=OrderSelect(Counter,SELECT_BY_POS);
      if(selected==false)
        {
         ErrorCode=GetLastError();
         ErrDesc=ErrorDescription(ErrorCode);

         ErrAlert=StringConcatenate(Symbol()," Select order to set sell order trailing stop - Error: ",ErrorCode,": ",ErrDesc);
         Alert(ErrAlert);

         //string ErrLog = StringConcatenate("Ticket: ",argTicket);
         //Print(ErrLog);
        }
      else
        {

         // Calculate Max Stop and Min Profit
         double MaxStopLoss=MarketInfo(argSymbol,MODE_ASK)+(argTrailingStop*PipPoint(argSymbol));
         MaxStopLoss=NormalizeDouble(MaxStopLoss,(int)MarketInfo(OrderSymbol(),MODE_DIGITS));

         double CurrentStop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(OrderSymbol(),MODE_DIGITS));

         double PipsProfit= OrderOpenPrice()-MarketInfo(argSymbol,MODE_ASK);
         double MinProfit = argMinProfit * PipPoint(argSymbol);

         // Modify Stop
         if(OrderMagicNumber()==argMagicNumber && OrderSymbol()==argSymbol && OrderType()==OP_SELL && (CurrentStop>MaxStopLoss || CurrentStop==0) && PipsProfit>=MinProfit)
           {
            bool Trailed=OrderModify(OrderTicket(),OrderOpenPrice(),MaxStopLoss,OrderTakeProfit(),0);
            Alert("SellTrailingStop modified the SL, Ask=",Ask,", SL=",MaxStopLoss,", TP=",OrderTakeProfit());
            // Error Handling
            if(Trailed==false)
              {
               ErrorCode=GetLastError();
               ErrDesc=ErrorDescription(ErrorCode);

               ErrAlert=StringConcatenate("Sell Trailing Stop - Error ",ErrorCode,": ",ErrDesc);
               Alert(ErrAlert);

               ErrLog=StringConcatenate("Ask: ",MarketInfo(argSymbol,MODE_ASK)," Ticket: ",OrderTicket()," Stop: ",OrderStopLoss()," Trail: ",MaxStopLoss);
               Print(ErrLog);
              }
           }
        }
     }
  }

//  
//// Function that set breakeven stop when profit meet to predefined level
//extern double BreakEvenProfit = 25; // Profit pips to achieve that trigger setting breakeven stop
//void 

//+------------------------------------------------------------------+
