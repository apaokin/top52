module Stats
  class AttributeValueCache
    def initialize
      @dbval_cache = {}
      @dict_cache = {}
    end

    def dbval_for(obj_id, attr_id)
      key = [obj_id, attr_id]
      @dbval_cache[key] ||= Top50AttributeValDbval.find_by(obj_id: obj_id, attr_id: attr_id)
    end

    def warm_dbvals(obj_ids:, attr_ids:)
      objs = Array(obj_ids).compact.uniq
      attrs = Array(attr_ids).compact.uniq
      return if objs.empty? || attrs.empty?

      Top50AttributeValDbval.where(obj_id: objs, attr_id: attrs).find_each do |rec|
        @dbval_cache[[rec.obj_id, rec.attr_id]] = rec
      end
    end

    def dict_name_for(obj_id, attr_id)
      key = [obj_id, attr_id]
      avd = @dict_cache[key]
      if avd.nil?
        avd = Top50AttributeValDict.find_by(obj_id: obj_id, attr_id: attr_id)
        @dict_cache[key] = avd
      end
      avd&.top50_dictionary_elem&.name
    end

    def warm_dict(obj_ids:, attr_ids:)
      objs = Array(obj_ids).compact.uniq
      attrs = Array(attr_ids).compact.uniq
      return if objs.empty? || attrs.empty?

      Top50AttributeValDict.includes(:top50_dictionary_elem).where(obj_id: objs, attr_id: attrs).find_each do |rec|
        @dict_cache[[rec.obj_id, rec.attr_id]] = rec
      end
    end
  end
end
