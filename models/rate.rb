class Rate < ApplicationRecord
  PAIR_LIST = %w[AUDJPY CADJPY CHFJPY EURJPY EURUSD GBPJPY NZDJPY USDJPY].freeze

  validates :time, :pair, :bid, :ask,
            presence: {message: 'absent'}
  validates :pair,
            inclusion: {in: PAIR_LIST, message: 'invalid'}
  validates :bid, :ask,
            numericality: {greater_than: 0, message: 'invalid'}

  def self.load_data(file_name)
    headers = self.attribute_names - %w[id created_at updated_at]
    ids = headers.size.times.map {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "#{header}=@#{i}" }
    variables += %w[created_at=now() updated_at=now()]
    super(file_name, ids, variables, self.table_name)

    sql = "ALTER TABLE #{self.table_name} AUTO_INCREMENT = #{last.id + 1}"
    ActiveRecord::Base.connection.execute(sql)
  end
end
