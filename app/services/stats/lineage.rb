module Stats
  class Lineage
    def self.precedes_child_to_parent_map
      precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
      return {} unless precedes_type_id

      rels = Top50Relation.where(type_id: precedes_type_id, is_valid: [1, 2]).order(:id)
      rels.each_with_object({}) { |r, h| h[r.sec_obj_id] ||= r.prim_obj_id }
    end

    def self.branch_key_machine_id(machine_id, map = nil)
      return nil if machine_id.nil?

      map ||= precedes_child_to_parent_map
      child_count_by_parent = Hash.new(0)
      map.each_value { |parent_id| child_count_by_parent[parent_id] += 1 }

      mid = machine_id
      while map[mid]
        parent = map[mid]
        break if child_count_by_parent[parent].to_i > 1

        mid = parent
      end
      mid
    end
  end
end
