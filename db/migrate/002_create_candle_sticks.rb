class CreateCandleSticks < ActiveRecord::Migration[4.2]
  def change
    create_table :candle_sticks do |t|
      t.datetime :from, null: false
      t.datetime :to, null: false
      t.string :pair, null: false
      t.string :period, null: false
      t.float :open, null: false
      t.float :close, null: false
      t.float :high, null: false
      t.float :low, null: false
      t.timestamps null: false
    end

    add_index :candle_sticks, %i[from to pair period], unique: true
  end
end
