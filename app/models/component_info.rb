# Stores component upgradability data from open sources:
# date_announced — when the component was announced (from open sources)
# date_mentioned — first appearance in the Top50 rating 
class ComponentInfo < ActiveRecord::Base
  belongs_to :component, class_name: 'Top50Object', foreign_key: :component_id
end
