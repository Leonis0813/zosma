class RenamePeriodColumnToCandleSticks < ActiveRecord::Migration[4.2]
  def change
    rename_column :candle_sticks, :period, :time_frame
  end
end
