//+------------------------------------------------------------------+
//|                                            MA Cross Advanced.mq4 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, Ryan Klefas"
#property link      "rklefas@inbox.com"


extern string    basicheader="== Basic Settings ==";
extern double    TakeProfit=0;
extern double    Stoploss=0;
double           Lots=0.1;

extern string    eaheader="== EA Options ==";
extern bool      allowClosing=true;
extern int       profitTarget1=21;
extern int       profitTarget2=34;
extern int       profitTarget3=55;
extern int       profitTarget4=89;
extern double    lotSize1=0.1;
extern double    lotSize2=0.1;
extern double    lotSize3=0.1;
extern double    lotSize4=0.1;
extern double    lotSize5=0.1;

extern string    stopheader="== Advanced Stops ==";
extern double    TrailingStop=100;
extern bool      TrailingStopOnlyProfit=false;
extern bool      TrailingStopRegular=true;
extern int       breakEvenAtProfit=0;
extern int       breakEvenShift=0;

extern string    indheader = "== Indicators ==";
extern int       maOPENperiods=5;
extern int       maCLOSEperiods=5;
extern int       MAmode=1;                /*MODE_SMA 0 Simple moving average, 
                                            MODE_EMA 1 Exponential moving average, 
                                            MODE_SMMA 2 Smoothed moving average, 
                                            MODE_LWMA 3 Linear weighted moving average. */
extern int       current=0;
extern int       prev=1;
extern int       anchorA=2;
extern int       anchorB=4;
extern int       anchorC=6;










string commentString="MA Cross";
int magicNum=6873516;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {

   if (MAmode<0 || MAmode>3)
      MAmode=1;
      
   
   
   Lots=lotSize1+lotSize2+lotSize3+lotSize4+lotSize5;

   int OrdersOpen=0, buyOrders=0, sellOrders=0, pendingOrders=0;

   checkOrderStatus(OrdersOpen,buyOrders,sellOrders,pendingOrders);
   advancedStopManager(OrdersOpen);

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


   double maOPEN          =iMA(NULL,0,maOPENperiods,0,MAmode,PRICE_OPEN,current);
   double maCLOSE         =iMA(NULL,0,maCLOSEperiods,0,MAmode,PRICE_CLOSE,current);
   double maOPENpast      =iMA(NULL,0,maOPENperiods,0,MAmode,PRICE_OPEN,prev);
   double maCLOSEpast     =iMA(NULL,0,maCLOSEperiods,0,MAmode,PRICE_CLOSE,prev);
   
   double maOPENAnchorA   =iMA(NULL,0,maOPENperiods,0,MAmode,PRICE_OPEN,anchorA);
   double maCLOSEAnchorA  =iMA(NULL,0,maCLOSEperiods,0,MAmode,PRICE_CLOSE,anchorA);
   double maOPENAnchorB   =iMA(NULL,0,maOPENperiods,0,MAmode,PRICE_OPEN,anchorB);
   double maCLOSEAnchorB  =iMA(NULL,0,maCLOSEperiods,0,MAmode,PRICE_CLOSE,anchorB);
   double maOPENAnchorC   =iMA(NULL,0,maOPENperiods,0,MAmode,PRICE_OPEN,anchorC);
   double maCLOSEAnchorC  =iMA(NULL,0,maCLOSEperiods,0,MAmode,PRICE_CLOSE,anchorC);
   


bool anchorsConfirmBuy;
bool anchorsConfirmSell;
bool confirmBuy;
bool confirmSell;



if (maOPENAnchorA<maCLOSEAnchorA && maOPENAnchorB<maCLOSEAnchorB
                                 && maOPENAnchorC<maCLOSEAnchorC)
    anchorsConfirmBuy=true;
else
    anchorsConfirmBuy=false;
    
    
if (maOPENAnchorA>maCLOSEAnchorA && maOPENAnchorB>maCLOSEAnchorB 
                                 && maOPENAnchorC>maCLOSEAnchorC)
    anchorsConfirmSell=true;
else
    anchorsConfirmSell=false;    
    

if (maOPEN>maCLOSE && maOPENpast>maCLOSEpast)
   confirmBuy=true;
else
   confirmBuy=false;
   
if (maOPEN<maCLOSE && maOPENpast<maCLOSEpast)
   confirmSell=true;
else
   confirmSell=false;

if (OrdersOpen == 0)
{
   if (anchorsConfirmBuy && confirmBuy)
      sendBuyOrder();
   if (anchorsConfirmSell && confirmSell)
      sendSellOrder();
}

if (allowClosing)
{
   if (buyOrders == 1)
   {
      if (maOPENpast<=maCLOSEpast)
       closeBuyOrder();
   }

   if (sellOrders == 1)
   {
     if (maOPENpast>=maCLOSEpast)
       closeSellOrder();
   }      
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

   return(0);
  }
  
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void sendSellOrder() 
   {
      double Stopvalue=0, TPvalue=0;
      if (Stoploss>0)
         {Stopvalue = Ask+Stoploss*Point;}
      if (TakeProfit>0)
         {TPvalue = Bid-TakeProfit*Point;}
         
      int ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Stopvalue,TPvalue,commentString + " " + Period(),magicNum,0,Red);
      if(ticket>0)
         {if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print(commentString + " SELL order at ",OrderOpenPrice()); }
      else 
         {Print("Error opening SELL order : ",GetLastError());}
   }

//+------------------------------------------------------------------+

void sendBuyOrder() 
   {
     double Stopvalue=0, TPvalue=0;
     if (Stoploss>0)
        {Stopvalue = Bid-Stoploss*Point;}
     if (TakeProfit>0)
        {TPvalue = Ask+TakeProfit*Point;}

     int ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Stopvalue,TPvalue,commentString + " " + Period(),magicNum,0,Green);
     if(ticket>0)
       {if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print(commentString + " BUY order at ",OrderOpenPrice()); }
     else 
        {Print("Error opening BUY order : ",GetLastError());}
   }
   
//+------------------------------------------------------------------+

void regularTrailingStop() 
{
   int cnt, total = OrdersTotal();
   
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==magicNum )
        {if(TrailingStop>0)  
           {if(OrderType()==OP_BUY)
              {if(OrderStopLoss()<Bid-Point*TrailingStop)
                 { OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green); 
                 }}}
            else
              {if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                 { OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red); 
                 }}}}
}

//+------------------------------------------------------------------+

void onlyProfitTrailingStop() 
   {
   
   int cnt, total = OrdersTotal();

   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==magicNum )
        {if(TrailingStop>0)  
           {if(OrderType()==OP_BUY)
              {if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {if(OrderStopLoss()<Bid-Point*TrailingStop)
                    { OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green); 
                        }}}}
            else
              {if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    { OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red); 
                        }}}}}}
   
//+------------------------------------------------------------------+

void closeSellOrder() 
   {
   int cnt, total = OrdersTotal();

   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==magicNum )
        {if(OrderType()==OP_SELL)
           {OrderClose(OrderTicket(),OrderLots(),Ask,3,CLR_NONE); 
             }}}}

//+------------------------------------------------------------------+

void closeBuyOrder() 
   {
   int cnt, total = OrdersTotal();

   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==magicNum )
        {if(OrderType()==OP_BUY)
           {OrderClose(OrderTicket(),OrderLots(),Bid,3,CLR_NONE); 
             }}}}

//+------------------------------------------------------------------+

void breakEvenManager() 

   {
   
   for(int cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==magicNum )
        {if(breakEvenAtProfit>0)  
           {if(OrderType()==OP_BUY)
              {if(Bid-OrderOpenPrice()>=Point*breakEvenAtProfit)
                 {if(OrderStopLoss()!=OrderOpenPrice() + breakEvenShift*Point)
                    { OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+ breakEvenShift*Point,OrderTakeProfit(),0,Green); 
                        }}}}
             else
              {if((OrderOpenPrice()-Ask)>(Point*breakEvenAtProfit))
                 {if(OrderStopLoss()!=OrderOpenPrice() - breakEvenShift*Point)
                    { OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()- breakEvenShift*Point,OrderTakeProfit(),0,Red); 
                        }}}}}}
   
//+------------------------------------------------------------------+

 
void checkOrderStatus(int& OrdersOpen,int& buyOrders,int& sellOrders,int& pendingOrders)
{
   for(int cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==magicNum /**/ )
        {  
         if (OrderType()==OP_BUY)
            {buyOrders++; OrdersOpen++;}
         else if (OrderType()==OP_SELL)
            {sellOrders++; OrdersOpen++;}
         else
            {pendingOrders++; OrdersOpen++;}
        }
     }
}

//+------------------------------------------------------------------+

void advancedStopManager(int OrdersOpen) 
{
   if (TrailingStopOnlyProfit && TrailingStopRegular)
      {Print("Both Trailing Stops are enabled.  Defaulted to Regular TS.");}
    
   if (OrdersOpen >= 1)
   {
      profitTargets();

      if (breakEvenAtProfit>0)
         breakEvenManager();
      if (TrailingStopRegular)
          regularTrailingStop();
      else if (TrailingStopOnlyProfit)
          onlyProfitTrailingStop();
      
    }
}

//+------------------------------------------------------------------+

void profitTargets()
// Closes lots on open orders when profit targets are hit
{
   int cnt, total = OrdersTotal();

   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==magicNum )
        {if(OrderType()==OP_BUY)
           {if(  (Bid >= OrderOpenPrice()+profitTarget1*Point && OrderLots() == Lots) || 
                 (Bid >= OrderOpenPrice()+profitTarget2*Point && OrderLots() == (lotSize2+lotSize3+lotSize4+lotSize5) )|| 
                 (Bid >= OrderOpenPrice()+profitTarget3*Point && OrderLots() == (lotSize3+lotSize4+lotSize5) )|| 
                 (Bid >= OrderOpenPrice()+profitTarget4*Point && OrderLots() == (lotSize4+lotSize5) ) )
             { OrderClose(OrderTicket(),(Lots/5),Bid,3,CLR_NONE); }  }  }
        {if(OrderType()==OP_SELL)
           {if(  (Ask <= OrderOpenPrice()-profitTarget1*Point && OrderLots() == Lots) || 
                 (Ask <= OrderOpenPrice()-profitTarget2*Point && OrderLots() == (lotSize2+lotSize3+lotSize4+lotSize5) )|| 
                 (Ask <= OrderOpenPrice()-profitTarget3*Point && OrderLots() == (lotSize3+lotSize4+lotSize5) )|| 
                 (Ask <= OrderOpenPrice()-profitTarget4*Point && OrderLots() == (lotSize4+lotSize5) ) )
             { OrderClose(OrderTicket(),(Lots/5),Ask,3,CLR_NONE); }  }  }
     }
}

//+------------------------------------------------------------------+   

//+------------------------------------------------------------------+

