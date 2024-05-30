class Top50ObjectsController < Top50BaseController
  skip_before_filter :require_login, only: [:show_info]
  skip_before_filter :require_admin_rights, only: [:show_info]

  Cpu = Struct.new(:id, :model, :family, :gen, :manufacturer, :cores_count, :frequency, :is_valid)

  # Type of attributes for CPU
  CPU = 6
  FAMILY = 27
  GEN = 29
  MODEL = 15
  MANUFACTURER = 20
  CORES = 4
  FREQUENCY = 25

  def index
    @top50_objects = Top50Object.all
  end
  
  def cpu_duplicates
    @top50_objects = Top50Object.all
    @cpu_table_titles = ["ID", "Модель", "Семейство", "Поколение", "Состояние", "Действия"]
    @manufacturers_table_titles = ["ID", "Производитель", "Статус", "Заменить на производителя с другим id:"]
    @families_table_titles = ["ID", "Семейство", "Статус", "Заменить на семейство с другим id:"]
    @gens_table_titles = ["ID", "Поколение", "Статус", "Заменить на поколение с другим id:"]
    @dict_elem = Top50DictionaryElem
    @cpus = construct_cpus_array()
    @cursed_cpus = get_cursed_cpus(@cpus)
    @families = @families.sort_by{|id| @dict_elem.find_by(id: id).name}
    @families_clusters = get_attribute_clusters(@families)
    @gens = @gens.sort_by{|id| @dict_elem.find_by(id: id).name}
    @gens_clusters = get_attribute_clusters(@gens)
  end

  def replace_cpu_attribute
    object_to_delete = Top50DictionaryElem.find_by(id: params[:id_to_delete])
    if object_to_delete == nil
      @wrong_id = true
      redirect_to(:back)
    end

    object_to_delete.replace(params[:replacing_id])
    object_to_delete.destroy
    redirect_to(:back)
  end

  def get_attribute_clusters(families_array)
    clusters = Hash.new
    done = Set.new
    families = families_array.sort_by{|id| -@dict_elem.find_by(id: id).name.length}
    families.each do |id1|
      if done.include?(id1)
        next
      end
      families.each do |id2|
        if done.include?(id2)
          next
        end

        if @dict_elem.find_by(id: id2).name.downcase.include?(@dict_elem.find_by(id: id1).name.downcase) and id2 != id1
          if clusters.include?(id1)
            clusters[id1] = clusters[id1] + [id2]
          else
            clusters[id1] = [id1, id2]
          end
          done.add(id1)
          done.add(id2)
        end

      end
    end

    return clusters
  end

  def index_type
    #top50_obj_gr = Top50Object.all.group(:type_id).count
    #@top50_object_types = Top50ObjectType.all.joins(top50_obj_gr)
    @top50_object_types = Top50ObjectType.select("top50_object_types.id, top50_object_types.name, top50_object_types.name_eng, count(1) as cnt").joins(:top50_objects).group("top50_object_types.id, top50_object_types.name, top50_object_types.name_eng")
  end
  
  def objects_of_type
    # if ['CPU', 'GPU', 'Coprocessor', 'Acceletator'] include? Top50ObjectType.find(params[:tid]).name_eng
    model_attrid = Top50Attribute.where(name_eng: "Accelerator model").first
    case Top50ObjectType.find(params[:tid]).name_eng
    when 'CPU'
      model_attrid = Top50Attribute.where(name_eng: "CPU model").first
    when 'GPU'
      model_attrid = Top50Attribute.where(name_eng: "GPU model").first
    when 'Coprocessor'
      model_attrid = Top50Attribute.where(name_eng: "Coprocessor model").first
    end
    @top50_objects = Top50Object.select("top50_objects.*, de.name").
      joins("left join top50_attribute_val_dicts avd on avd.obj_id = top50_objects.id").
      joins("left join top50_dictionary_elems de on de.id = avd.dict_elem_id").
      where("top50_objects.type_id = ? and (avd.attr_id = ? or avd.attr_id is null)", params[:tid], model_attrid).
      order("de.name, top50_objects.id") 
    cpu_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "CPU model"))
    @cpu_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cpu_model_attrs)
    gpu_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "GPU model"))
    @gpu_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(gpu_model_attrs)
  end

  def attribute_vals
    @top50_object = Top50Object.find(params[:id])
  end

  def show
    @top50_object = Top50Object.find(params[:id])
  end
  
  def show_info
    @top50_object = Top50Object.find(params[:id])
  end 

  def new_attribute_val_dbval
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val = Top50AttributeValDbval.new
  end

  def create_attribute_val_dbval
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val = @top50_object.top50_attribute_val_dbvals.build(top50_attr_val_dbval_params)
    if @top50_attr_val.save
      redirect_to @top50_object
    else
      render :new_attribute_val_dbval
    end
  end

  def edit_attribute_val_dbval
    @top50_attr_val = Top50AttributeValDbval.find(params[:avid])
    @top50_object = Top50Object.find(params[:id])
  end

  def save_attribute_val_dbval
    @top50_attr_val = Top50AttributeValDbval.find(params[:avid])
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val.update(top50_attr_val_dbval_params)
    @top50_attr_val.save!
    redirect_to @top50_object
  end

  def destroy_attribute_val_dbval
    @top50_attr_val = Top50AttributeValDbval.find(params[:avid])
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val.destroy!
    redirect_to @top50_object
  end

  def relations
    @top50_object = Top50Object.find(params[:id])
  end

  def new_relation
    @top50_object = Top50Object.find(params[:id])
    @top50_nested_object = Top50Object.new
    @top50_relation = Top50Relation.new
  end

  def create_relation
    @top50_object = Top50Object.find(params[:id])
    @top50_relation = @top50_object.top50_relations.build(top50_nested_object_params[:top50_relation])
    if top50_nested_object_params[:top50_object][:id].present?
      @top50_nested_object = Top50Object.find(top50_nested_object_params[:top50_object][:id])
    else
      @top50_nested_object = Top50Object.new(top50_nested_object_params[:top50_object])
      @top50_nested_object.save!
    end
    @top50_relation.sec_obj_id = @top50_nested_object.id
    if @top50_relation.save
      redirect_to @top50_object
    else
      render :new_relation
    end
  end

  def edit_relation
    @top50_object = Top50Object.find(params[:id])
    @top50_relation = Top50Relation.find(params[:relid])
  end

  def save_relation
    @top50_object = Top50Object.find(params[:id])
    @top50_relation = Top50Relation.find(params[:relid])
    @top50_relation.update(top50_relation_params)
    @top50_relation.save!
    redirect_to @top50_object
  end

  def destroy_relation
    @top50_object = Top50Object.find(params[:id])
    @top50_relation = Top50Relation.find(params[:relid])
    if @top50_relation.prim_obj_id == @top50_object.id
      @top50_relation.destroy!
    end
    redirect_to @top50_object
  end

  def new_attribute_val_dict_set_attr
    attr = Top50AttributeDict.find(params[:attr_id])
    redirect_to proc { new_top50_object_top50_attribute_val_dict_step2_path(params[:id], attr.id) }
    return
  end

  def new_attribute_val_dict_step2
    @top50_object = Top50Object.find(params[:id])
    attr = Top50AttributeDict.find(params[:attrid])
    @attr_id = attr.id
    @dict_id = attr.dict_id
  end

  def edit_attribute_val_dict
    @top50_attr_val = Top50AttributeValDict.find(params[:avid])
    attr = Top50AttributeDict.find(@top50_attr_val.attr_id)
    @attr_id = attr.id
    @dict_id = attr.dict_id
    @top50_object = Top50Object.find(params[:id])
  end

  def save_attribute_val_dict
    @top50_attr_val = Top50AttributeValDict.find(params[:avid])
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val.update(top50_attr_val_dict_params)
    @top50_attr_val.save!
    redirect_to @top50_object
  end

  def destroy_attribute_val_dict
    @top50_attr_val = Top50AttributeValDict.find(params[:avid])
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val.destroy!
    redirect_to @top50_object
  end

  def new_attribute_val_dict
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val = Top50AttributeValDict.new
  end

  def create_attribute_val_dict
    @top50_object = Top50Object.find(params[:id])
    @top50_attr_val = @top50_object.top50_attribute_val_dicts.build(top50_attr_val_dict_params)
    if @top50_attr_val.save
      redirect_to @top50_object
    else
      redirect_to proc { new_top50_object_top50_attribute_val_dict_step2_path(@top50_object, @top50_attr_val.attr_id) }
    end
  end

  def show
    @top50_object = Top50Object.find(params[:id])
  end
 
  def new
    @top50_object = Top50Object.new
  end

  def create
    @top50_object = Top50Object.new(top50_object_params)
    if @top50_object.save
      redirect_to @top50_object
    else
      render :new
    end
  end

  def edit
    @top50_object = Top50Object.find(params[:id])
  end

  def update
    @top50_object = Top50Object.find(params[:id])
    @top50_object.update_attributes(top50_object_params)
    redirect_to @top50_object
  end

  def destroy
    @top50_object = Top50Object.find(params[:id])
    @top50_object.destroy
    redirect_to :top50_objects
  end

  def default
    Top50Object.default!
  end

  private

  def top50_object_params
    params.require(:top50_object).permit(:type_id, :is_valid)
  end

  def top50_attr_val_dbval_params
    params.require(:top50_attribute_val_dbval).permit(:attr_id, :value, :is_valid)
  end

  def top50_attr_val_dict_params
    params.require(:top50_attribute_val_dict).permit(:attr_id, :dict_elem_id, :is_valid)
  end

  def top50_nested_object_params
    params.require(:top50_relation).permit(:top50_relation => [:type_id, :sec_obj_qty, :is_valid], :top50_object => [:id, :type_id, :is_valid])
  end

  def top50_relation_params
    params.require(:top50_relation).permit(:type_id, :sec_obj_qty, :is_valid, :sec_obj_id)
  end

  def construct_cpus_array()
    cpus = []
    cpus_objects = Top50Object.where(type_id: CPU).to_a
    @dict_elems = Top50DictionaryElem
    @manufacturers = Set.new
    @gens = Set.new
    @families = Set.new
    cpus_objects.each do |obj|

      dict_values = obj.top50_attribute_val_dicts
      model = nil
      gen = nil
      family = nil
      manufacturer = nil
      cores_count = nil
      frequency = nil
      
      dict_values.each do |value|
        attr_name = value.top50_dictionary_elem.name 
        case value.top50_attribute_dict.top50_attribute.id
        when FAMILY
          family = attr_name
          @families.add(value.top50_dictionary_elem.id)
        when GEN
          gen = attr_name
          @gens.add(value.top50_dictionary_elem.id)
        when MODEL
          model = attr_name
        when MANUFACTURER
          manufacturer = attr_name
          @manufacturers.add(value.top50_dictionary_elem.id)
        end
      end

      values = obj.top50_attribute_val_dbvals
      values.each do |value|
        case value.top50_attribute_dbval.top50_attribute.id
        when CORES
          cores_count = value.value
        when FREQUENCY
          frequency = value.value
        end
      end

      cpus << Cpu.new(obj.id, model, family, gen, manufacturer, cores_count, frequency, obj.is_valid)
    end
    return cpus
  end

  def get_cursed_cpus(cpus)
    cursed = []
    cpus.each do |cpu|
      if cpu.model == nil
        next
      end
      if cpu.model.downcase.include? "ghz"
        cursed << cpu
      end
    end

    return cursed
  end

end
