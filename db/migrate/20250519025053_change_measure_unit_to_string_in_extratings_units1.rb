class ChangeMeasureUnitToStringInExtratingsUnits1 < ActiveRecord::Migration
  def change
    change_column :extratings_units, :measure_unit, :string
  end
end
