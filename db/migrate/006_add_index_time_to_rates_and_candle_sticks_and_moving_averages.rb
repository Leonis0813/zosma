class AddIndexTimeToRatesAndCandleSticksAndMovingAverages < ActiveRecord::Migration[4.2]
  def change
    add_index :rates, :time
    add_index :candle_sticks, :to
    add_index :moving_averages, :time
  end
end
