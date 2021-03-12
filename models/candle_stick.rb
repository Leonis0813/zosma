class CandleStick < ApplicationRecord
  PAIR_LIST = %w[AUDJPY CADJPY CHFJPY EURJPY EURUSD GBPJPY NZDJPY USDJPY].freeze
  TIME_FRAME_LIST = %w[M1 M5 M15 M30 H1 H4 D1 W1 MN1].freeze

  validates :from, :to, :pair, :time_frame, :open, :close, :high, :low,
            presence: {message: 'absent'}
  validates :pair,
            inclusion: {in: PAIR_LIST, message: 'invalid'}
  validates :time_frame,
            inclusion: {in: TIME_FRAME_LIST, message: 'invalid'}
  validates :open, :close, :high, :low,
            numericality: {greater_than: 0, message: 'invalid'}

  scope :on, lambda {|date|
    from = date.strftime('%F 00:00:00')
    to = date.strftime('%F 23:59:59')
    where('`to` BETWEEN ? AND ?', from, to)
  }

  def create_infile(src_file, dst_file)
    FileUtils.cp(src_file, dst_file)
  end

  def to_csv
    [
      from.strftime('%F %T'),
      to.strftime('%F %T'),
      pair,
      time_frame,
      open,
      close,
      high,
      low,
    ]
  end
end
