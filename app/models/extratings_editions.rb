class ExtratingsEditions < ActiveRecord::Base
    belongs_to :extratings_list, class_name: 'ExtratingsList'
    has_many :extratings_entries, class_name: 'ExtraitingsEntry', foreign_key: 'extratings_edition_id'
  
    validates :edition_number, :publication_date, :edition_multiplier, presence: true
  end