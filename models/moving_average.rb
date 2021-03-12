class MovingAverage < ApplicationRecord
  PAIR_LIST = %w[AUDJPY CADJPY CHFJPY EURJPY EURUSD GBPJPY NZDJPY USDJPY].freeze
  TIME_FRAME_LIST = %w[M1 M5 M15 M30 H1 H4 D1 W1 MN1].freeze
  PERIOD_LIST = [25, 50, 75, 100, 150, 200].freeze

  validates :time, :pair, :time_frame, :period, :value,
            presence: {message: 'absent'}
  validates :pair,
            inclusion: {in: PAIR_LIST, message: 'invalid'}
  validates :time_frame,
            inclusion: {in: TIME_FRAME_LIST, message: 'invalid'}
  validates :period,
            inclusion: {in: PERIOD_LIST, message: 'invalid'}
  validates :value,
            numericality: {greater_than: 0, message: 'invalid'}

  scope :on, lambda {|date|
    from = date.strftime('%F 00:00:00')
    to = date.strftime('%F 23:59:59')
    where('`time` BETWEEN ? AND ?', from, to)
  }

  def create_infile(src_file, dst_file)
    FileUtils.cp(src_file, dst_file)
  end

  def to_csv
    [time.strftime('%F %T'), pair, time_frame, period, value]
  end
end
