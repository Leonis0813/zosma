class CreateCandleSticks < ActiveRecord::Migration
  def change
    create_table :candle_sticks do |t|
      t.datetime :from, :null => false
      t.datetime :to, :null => false
      t.string :pair, :null => false
      t.string :interval, :null => false
      t.float :open, :null => false
      t.float :close, :null => false
      t.float :high, :null => false
      t.float :low, :null => false
      t.timestamps :null => false
    end

    add_index :candle_sticks, [:from, :to, :pair, :interval], :unique => true
  end
end
