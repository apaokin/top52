class CreateExtratingsUnits < ActiveRecord::Migration
  def change
    create_table :extratings_units do |t|
      t.string :name_ru
      t.string :name_eng
      t.string :measure_unit
      t.decimal :base_multiplier, precision: 10, scale: 4 

      t.timestamps
    end
  end
end