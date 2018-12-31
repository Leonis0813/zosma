class AddTimestampsToRates < ActiveRecord::Migration
  def change
    add_timestamps(:rates, :null => false)
  end
end
