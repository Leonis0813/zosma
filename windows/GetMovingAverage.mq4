//+------------------------------------------------------------------+
//|                                             GetMovingAverage.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#define TIME_FRAME_SIZE 9
#define PERIOD_SIZE 6
#define INTERVAL 1

const int time_frames[TIME_FRAME_SIZE] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
const string time_frames_str[TIME_FRAME_SIZE] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN1"};
const int periods[PERIOD_SIZE] = {25, 50, 75, 100, 150, 200};

void writeMovingAverage(int index, int handle, datetime now) {
  for(int i=0;i<PERIOD_SIZE;i++) {
    double ma = iMA(NULL, time_frames[index], periods[i], 0, MODE_SMA, PRICE_CLOSE, 1);
    ma = NormalizeDouble(ma, Digits());

    string time = TimeToStr(now - time_frames[index] * 60, TIME_DATE | TIME_MINUTES);
    StringReplace(time, ".", "-");

    FileSeek(handle, 0, SEEK_END);
    FileWrite(handle, time + ":00", Symbol(), time_frames_str[index], periods[i], ma);
  }
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
  EventSetTimer(INTERVAL);
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
                const int &spread[]) {
  return(rates_total);
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
  datetime now = TimeGMT();

  if(TimeSeconds(now) == 1) {
    string date_str = TimeToStr(now, TIME_DATE);
    StringReplace(date_str, ".", "-");

    int handle = FileOpen("moving_averages/" + Symbol() + "_" + date_str + ".csv", FILE_CSV | FILE_READ | FILE_WRITE, ',');

    writeMovingAverage(0, handle, now);

    if(TimeMinute(now) % 5 == 0) {
      writeMovingAverage(1, handle, now);
    }

    if(TimeMinute(now) % 15 == 0) {
      writeMovingAverage(2, handle, now);
    }

    if(TimeMinute(now) % 30 == 0) {
      writeMovingAverage(3, handle, now);
    }

    if(TimeMinute(now) == 0) {
      writeMovingAverage(4, handle, now);

      if(TimeHour(now) % 4 == 0) {
        writeMovingAverage(5, handle, now);
      }

      if(TimeHour(now) == 0) {
        writeMovingAverage(6, handle, now);

        if(TimeDayOfWeek(now) == 0) {
          writeMovingAverage(7, handle, now);
        }

        if(TimeDay(now) == 1) {
          writeMovingAverage(8, handle, now);
        }
      }
    }

    FileClose(handle);
  }
}
//+------------------------------------------------------------------+