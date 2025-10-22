class ExtratingsEntry < ActiveRecord::Base
    belongs_to :system, class_name: 'Top50Relation', foreign_key: 'system_id'
    belongs_to :extratings_edition, class_name: 'ExtratingsEditions'
    has_many :extratings_scores, foreign_key: :extratings_entry_id
  
    validates :system_id, presence: true
  end