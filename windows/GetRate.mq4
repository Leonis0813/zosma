//+------------------------------------------------------------------+
//|                                                      GetRate.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping

//---
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[]) {
//---
  datetime now = TimeGMT();
  string date_str = TimeToStr(now, TIME_DATE);
  string datetime_str = TimeToStr(now, TIME_DATE | TIME_SECONDS);
  StringReplace(date_str, ".", "-");
  StringReplace(datetime_str, ".", "-");

  MqlTick tick;
  SymbolInfoTick(Symbol(), tick);

  int handle = FileOpen(Symbol() + "_" + date_str + ".csv", FILE_CSV | FILE_READ | FILE_WRITE, ',');
  FileSeek(handle, 0, SEEK_END);
  FileWrite(handle, datetime_str, Symbol(), tick.bid, tick.ask);
  FileClose(handle);
//--- return value of prev_calculated for next call
  return(rates_total);
}
//+------------------------------------------------------------------+
