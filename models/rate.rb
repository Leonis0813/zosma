class Rate < ApplicationRecord
  PAIR_LIST = %w[AUDJPY CADJPY CHFJPY EURJPY EURUSD GBPJPY NZDJPY USDJPY].freeze

  validates :time, :pair, :bid, :ask,
            presence: {message: 'absent'}
  validates :pair,
            inclusion: {in: PAIR_LIST, message: 'invalid'}
  validates :bid, :ask,
            numericality: {greater_than: 0, message: 'invalid'}

  scope :on, lambda {|date|
    from = date.strftime('%F 00:00:00')
    to = date.strftime('%F 23:59:59')
    where('`time` BETWEEN ? AND ?', from, to)
  }

  def to_csv
    [time.strftime('%F %T'), pair, bid, ask]
  end
end
