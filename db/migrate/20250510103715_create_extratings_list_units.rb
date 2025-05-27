class CreateExtratingsListUnits < ActiveRecord::Migration
  def change
    create_table :extratings_list_units do |t|
      t.references :extratings_list, null: false, foreign_key: true
      t.references :extratings_unit, null: false, foreign_key: { to_table: :extratings_units }
      t.integer :priority

      t.timestamps
    end
  end
end