class ExtratingsScore < ActiveRecord::Base
    belongs_to :extratings_entry, class_name: 'ExtratingsEntry', foreign_key: :extratings_entry_id
    belongs_to :extratings_list_unit, class_name: 'ExtratingsListUnit', foreign_key: :extratings_list_unit_id
  
    validates :extratings_entry, :extratings_list_unit, presence: true
  end
  