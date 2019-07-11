class MovingAverage < ActiveRecord::Base
  PAIR_LIST = %w[AUDJPY CADJPY CHFJPY EURJPY EURUSD GBPJPY NZDJPY USDJPY]
  TIME_FRAME_LIST = %w[M1 M5 M15 M30 H1 H4 D1 W1 MN1]
  PERIOD_LIST = [25, 50, 75, 100, 150, 200]

  validates :time, :pair, :time_frame, :period, :value,
            presence: {message: 'absent'}
  validates :pair,
            inclusion: {in: PAIR_LIST, message: 'invalid'}
  validates :time_frame,
            inclusion: {in: TIME_FRAME_LIST, message: 'invalid'}
  validates :period,
            inclusion: {in:  PERIOD_LIST, message: 'invalid'}
  validates :value,
            numericality: {greater_than: 0, message: 'invalid'}
end
