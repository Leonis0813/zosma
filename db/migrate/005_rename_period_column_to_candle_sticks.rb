class RenamePeriodColumnToCandleSticks < ActiveRecord::Migration
  def change
    rename_column :candle_sticks, :period, :time_frame
  end
end
