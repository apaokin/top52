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

    def dict_name_for(obj_id, attr_id)
      key = [obj_id, attr_id]
      avd = @dict_cache[key]
      if avd.nil?
        avd = Top50AttributeValDict.find_by(obj_id: obj_id, attr_id: attr_id)
        @dict_cache[key] = avd
      end
      avd&.top50_dictionary_elem&.name
    end
  end
end
