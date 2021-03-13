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

  def self.create_infile(src_file, dst_file)
    CSV.open(dst_file, 'w') do |csv|
      rates = CSV.read(src_file, converters: :all).map do |rate|
        [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
      end

      rates.uniq! {|rate| [rate[0], rate[1]] }
      rates.each {|rate| csv << rate }
    end
  end

  def to_csv
    [time.strftime('%F %T'), pair, bid, ask]
  end
end
