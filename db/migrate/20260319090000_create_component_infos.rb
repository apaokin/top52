class CreateComponentInfos < ActiveRecord::Migration
  def change
    create_table :component_infos do |t|
      t.integer :component_id
      t.date :date_announced
      t.date :date_mentioned
      t.timestamps null: false
    end

    add_index :component_infos, :component_id, unique: true, name: "index_component_infos_on_component_id"
  end
end
