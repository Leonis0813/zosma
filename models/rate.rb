class Rate < ApplicationRecord
  PAIR_LIST = %w[AUDJPY CADJPY CHFJPY EURJPY EURUSD GBPJPY NZDJPY USDJPY].freeze

  validates :time, :pair, :bid, :ask,
            presence: {message: 'absent'}
  validates :pair,
            inclusion: {in: PAIR_LIST, message: 'invalid'}
  validates :bid, :ask,
            numericality: {greater_than: 0, message: 'invalid'}

  scope :on, ->(date) { where('DATE(`time`) = ?', date.strftime('%F')) }

  def to_csv
    [time.strftime('%F %T'), pair, bid, ask]
  end
end
