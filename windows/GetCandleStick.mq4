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

#define TIME_FRAME_SIZE 9
#define INTERVAL 1

const int time_frames[TIME_FRAME_SIZE] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
const string time_frames_str[TIME_FRAME_SIZE] = {"M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN1"};
bool is_written[TIME_FRAME_SIZE];

void writeCandleStick(int index, int handle, datetime now) {
  if(!is_written[index]) {
    double open = iOpen(NULL, time_frames[index], 1);
    double close = iClose(NULL, time_frames[index], 1);
    double high = iHigh(NULL, time_frames[index], 1);
    double low = iLow(NULL, time_frames[index], 1);

    string from = TimeToStr(now - time_frames[index] * 60, TIME_DATE | TIME_MINUTES);
    string to = TimeToStr(now - 60, TIME_DATE | TIME_MINUTES);
    StringReplace(from, ".", "-");
    StringReplace(to, ".", "-");

    FileSeek(handle, 0, SEEK_END);
    FileWrite(handle, from + ":00", to + ":59", Symbol(), time_frames_str[index], open, close, high, low);
    is_written[index] = true
  }
}

void resetFlag() {
  for(int i=0;i<TIME_FRAME_SIZE;i++) {
    is_written[i] = false;
  }
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
  EventSetTimer(INTERVAL);
  resetFlag();
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

  if(1 <= TimeDayOfWeek(now) && TimeDayOfWeek(now) <= 5) {
    if(1 <= TimeSeconds(now) && TimeSeconds(now) <= 10) {
      string date_str = TimeToStr(now, TIME_DATE);
      StringReplace(date_str, ".", "-");

      int handle = FileOpen("candle_sticks/" + Symbol() + "_" + date_str + ".csv", FILE_CSV | FILE_READ | FILE_WRITE, ',');

      writeCandleStick(0, handle, now);

      if(TimeMinute(now) % 5 == 0) {
        writeCandleStick(1, handle, now);
      }

      if(TimeMinute(now) % 15 == 0) {
        writeCandleStick(2, handle, now);
      }

      if(TimeMinute(now) % 30 == 0) {
        writeCandleStick(3, handle, now);
      }

      if(TimeMinute(now) == 0) {
        writeCandleStick(4, handle, now);

        if(TimeHour(now) % 4 == 0) {
          writeCandleStick(5, handle, now);
        }

        if(TimeHour(now) == 0) {
          writeCandleStick(6, handle, now);

          if(TimeDayOfWeek(now) == 0) {
            writeCandleStick(7, handle, now);
          }

          if(TimeDay(now) == 1) {
            writeCandleStick(8, handle, now);
          }
        }
      }
      FileClose(handle);
    } else {
      if(TimeSeconds(now) > 10) {
        resetFlag();
      }
    }
  }
}
