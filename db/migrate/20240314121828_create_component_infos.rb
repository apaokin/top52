class CreateComponentInfos < ActiveRecord::Migration
  def change
    create_table :component_infos do |t|
      t.timestamp :date_announced
      t.belongs_to :component
      t.timestamps null: false
    end
  end
end

class ModifyComponentInfosColumns < ActiveRecord::Migration
  def change
    change_column :component_infos, :date_announced, :date
  end
end