class CreateMovingAverages < ActiveRecord::Migration[4.2]
  def change
    create_table :moving_averages do |t|
      t.datetime :time, :null => false
      t.string :pair, :null => false
      t.string :time_frame, :null => false
      t.integer :period, :null => false
      t.float :value, :null => false
      t.timestamps :null => false
    end

    add_index :moving_averages, [:time, :pair, :time_frame, :period], :unique => true
  end
end
