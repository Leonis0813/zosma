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

  def self.load_data(file_name)
    headers = self.attribute_names - %w[id created_at updated_at]
    ids = headers.size.times.map {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
    variables += %w[created_at=now() updated_at=now()]
    super(file_name, ids, variables, self.table_name)

    sql = "ALTER TABLE #{self.table_name} AUTO_INCREMENT = #{last.id + 1}"
    ActiveRecord::Base.connection.execute(sql)
  end
end
