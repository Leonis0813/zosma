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

  def self.load_data(file_name)
    headers = MovingAverage.attribute_names - %w[id created_at updated_at]
    ids = headers.size.times.map {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
    variables += %w[created_at=now() updated_at=now()]
    super(file_name, ids, variables, self.table_name)

    sql = "ALTER TABLE #{self.table_name} AUTO_INCREMENT = #{last.id + 1}"
    ActiveRecord::Base.connection.execute(sql)
  end
end
