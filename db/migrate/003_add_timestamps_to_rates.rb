class AddTimestampsToRates < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:rates, :null => false)
  end
end
