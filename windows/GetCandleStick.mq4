//+------------------------------------------------------------------+
//|                                               GetCandleStick.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#define PERIOD_SIZE 9
#define INTERVAL 60

const int periods[PERIOD_SIZE] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
const string periods_str[PERIOD_SIZE] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN1"};
double prev_open[PERIOD_SIZE], prev_close[PERIOD_SIZE], prev_high[PERIOD_SIZE], prev_low[PERIOD_SIZE];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
  for(int i=0;i<PERIOD_SIZE;i++) {
    prev_open[i] = iOpen(NULL, periods[i], 1);
    prev_close[i] = iClose(NULL, periods[i], 1);
    prev_high[i] = iHigh(NULL, periods[i], 1);
    prev_low[i] = iLow(NULL, periods[i], 1);
  }
  EventSetTimer(INTERVAL);
//---
 return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
    return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
  datetime now = TimeGMT();
  string date_str = TimeToStr(now, TIME_DATE);
  StringReplace(date_str, ".", "-");

  int handle = FileOpen("candle_sticks/" + Symbol() + "_" + date_str + ".csv", FILE_CSV | FILE_READ | FILE_WRITE, ',');

  for(int i=0;i<PERIOD_SIZE;i++) {
    double open = iOpen(NULL, periods[i], 1);
    double close = iClose(NULL, periods[i], 1);
    double high = iHigh(NULL, periods[i], 1);
    double low = iLow(NULL, periods[i], 1);

    if(open != prev_open[i] && close != prev_close[i] && high != prev_high[i] && low != prev_low[i]) {
      string from = TimeToStr(now - periods[i] * 60, TIME_DATE | TIME_MINUTES);
      string to = TimeToStr(now - 60, TIME_DATE | TIME_MINUTES);
      StringReplace(from, ".", "-");
      StringReplace(to, ".", "-");

      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, from + ":00", to + ":59", Symbol(), periods_str[i], open, close, high, low);

      prev_open[i] = open;
      prev_close[i] = close;
      prev_high[i] = high;
      prev_low[i] = low;
    }
  }

  FileClose(handle);
}
