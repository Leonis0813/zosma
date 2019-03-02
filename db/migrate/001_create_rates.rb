class CreateRates < ActiveRecord::Migration[4.2]
  def change
    create_table :rates do |t|
      t.datetime :time, :null => false
      t.string :pair, :null => false
      t.float :bid, :null => false
      t.float :ask, :null => false
    end

    add_index :rates, [:time, :pair], :unique => true
  end
end
