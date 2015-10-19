//+------------------------------------------------------------------+
//|                                                 AverageRange.mq4 |
//|                                           ��� ����� �. aka KimIV |
//|                                              http://www.kimiv.ru |
//|                                                                  |
//|   14.09.2005  ������ ��� �������:                                |
//| ������� ������������� ����������� High-Low                       |
//| �������� ������� ���� �����       ABS(Open-Close)                |
//| �������� ������� ���� �����                                      |
//+------------------------------------------------------------------+
#property copyright "��� ����� �. aka KimIV"
#property link      "http://www.kimiv.ru"
#property show_inputs

extern datetime BeginDateCalc = D'1996.01.01';
extern datetime EndDateCalc   = D'2016.01.01';

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
void start() {
  int    i, b=0, bb=0, eb, h=0, l=0, s=0, t=0;
  string comm="";

  for (i=Bars; i>0; i--) {
    if (Time[i]>=BeginDateCalc && Time[i]<=EndDateCalc) {
      if (bb==0) bb=i;
      s+=(High[i]-Low[i])/Point;
      t+=MathAbs(Open[i]-Close[i])/Point;
      if (Open[i]>Close[i]) {
        h+=(High[i]-Open[i])/Point;
        l+=(Close[i]-Low[i])/Point;
      } else {
        h+=(High[i]-Close[i])/Point;
        l+=(Open[i]-Low[i])/Point;
      }
      b++;
    }
  }

  comm = "From: " + TimeToStr(Time[bb], TIME_DATE|TIME_MINUTES) + "\n";
  comm = comm + "To: " + TimeToStr(Time[bb-b+1], TIME_DATE|TIME_MINUTES) + "\n";
  comm = comm + "Avg. High-Low: " + s/b + " point.\n";
  comm = comm + "Avg. Open-Close: " + t/b + " point.\n";
  comm = comm + "Avg. gain for upward candle: " + h/b + " point.\n";
  comm = comm + "Avg. loss for downward candle: " + l/b + " point.";

  Comment(comm);
}
//+------------------------------------------------------------------+

