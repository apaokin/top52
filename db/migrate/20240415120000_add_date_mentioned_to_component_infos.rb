# frozen_string_literal: true

class AddDateMentionedToComponentInfos < ActiveRecord::Migration
  def change
    add_column :component_infos, :date_mentioned, :date
  end
end
