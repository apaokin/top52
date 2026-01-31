# frozen_string_literal: true

class ReorderComponentInfosColumns < ActiveRecord::Migration
  def up
    # Recreate table with order: component_id, date_announced, date_mentioned, created_at, updated_at
    create_table :component_infos_new do |t|
      t.integer  :component_id
      t.date     :date_announced
      t.date     :date_mentioned
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    execute <<-SQL
      INSERT INTO component_infos_new (component_id, date_announced, date_mentioned, created_at, updated_at)
      SELECT component_id, date_announced, date_mentioned, created_at, updated_at
      FROM component_infos
    SQL

    drop_table :component_infos
    rename_table :component_infos_new, :component_infos
  end

  def down
    create_table :component_infos_old do |t|
      t.date     :date_announced
      t.integer  :component_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.date     :date_mentioned
    end

    execute <<-SQL
      INSERT INTO component_infos_old (date_announced, component_id, created_at, updated_at, date_mentioned)
      SELECT date_announced, component_id, created_at, updated_at, date_mentioned
      FROM component_infos
    SQL

    drop_table :component_infos
    rename_table :component_infos_old, :component_infos
  end
end
