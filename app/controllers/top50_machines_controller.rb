# encoding: UTF-8
class Top50MachinesController < Top50BaseController
  skip_before_filter :require_login, only: [:list, :get_archive, :get_archive_by_vendor, :get_archive_by_org, :get_archive_by_city, :get_archive_by_country, :get_archive_by_vendor_excl, :get_archive_by_comp, :get_archive_by_comp_attrd, :get_archive_by_attr_dict, :archive, :archive_lists, :archive_by_vendor, :archive_by_org, :archive_by_city, :archive_by_country, :archive_by_vendor_excl, :archive_by_comp, :archive_by_comp_attrd, :archive_by_attr_dict, :show, :stats, :get_ext_stats, :ext_stats, :get_stats_per_list, :stats_per_list, :download_certificate, :app_form_new, :app_form_new_post, :app_form_upgrade, :app_form_upgrade_post, :app_form_step1, :app_form_step1_presave, :app_form_step2_presave, :app_form_step3_presave, :app_form_step4_presave, :app_form_confirm_post, :app_form_finish, :download_archive]
  skip_before_filter :require_admin_rights, only: [:list, :get_archive, :get_archive_by_vendor, :get_archive_by_org, :get_archive_by_city, :get_archive_by_country, :get_archive_by_vendor_excl, :get_archive_by_comp, :get_archive_by_comp_attrd, :get_archive_by_attr_dict, :archive, :archive_lists, :archive_by_vendor, :archive_by_org, :archive_by_city, :archive_by_country, :archive_by_vendor_excl, :archive_by_comp, :archive_by_comp_attrd, :archive_by_attr_dict, :show, :stats, :get_ext_stats, :ext_stats, :get_stats_per_list, :stats_per_list, :download_certificate, :app_form_new, :app_form_new_post, :app_form_upgrade, :app_form_upgrade_post, :app_form_step1, :app_form_step1_presave, :app_form_step2_presave, :app_form_step3_presave, :app_form_step4_presave, :app_form_confirm_post, :app_form_finish, :download_archive]
  def index
    @top50_machines = Top50Machine.all
  end

  def download_certificate
    if params[:path] and params[:path].start_with?("public/cert_create/certificates")
      send_file params[:path], filename: "Certificate.pdf", type:"application/pdf"
    else
      redirect_to :back
    end
  end

  def get_rel_contain_id
    return Top50RelationType.where(name_eng: 'Contains').first.id
  end

  def get_rel_precede_id
    return Top50RelationType.where(name_eng: 'Precedes').first.id
  end

  def get_name_eng_attr_id
    return Top50Attribute.where(name_eng: "Name(eng)").first.id
  end

  def get_preview_bunch_id
    return Top50Object.select("top50_objects.id").
      joins("join top50_object_types on top50_object_types.id = top50_objects.type_id and top50_object_types.name_eng = 'Bunch of benchmarks'").
      joins("join top50_attribute_val_dbvals dbv on dbv.obj_id = top50_objects.id and dbv.attr_id = #{get_name_eng_attr_id} and dbv.value = 'Top50 preview'").first.id
  end

  def get_bunch_id
    return Top50Object.select("top50_objects.id").
      joins("join top50_object_types on top50_object_types.id = top50_objects.type_id and top50_object_types.name_eng = 'Bunch of benchmarks'").
      joins("join top50_attribute_val_dbvals dbv on dbv.obj_id = top50_objects.id and dbv.attr_id = #{get_name_eng_attr_id} and dbv.value = 'Top50 position'").first.id
  end

  def get_avail_bunches
    res = [get_bunch_id]
    if current_user and current_user.may_preview?
      res << get_preview_bunch_id
    end
    return res
  end

  def calc_machine_attrs
    list_num_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition number"))
    @num_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_num_attrs)
    list_date_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition date"))
    @date_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_date_attrs)

    @rmax_res = Top50BenchmarkResult.all.joins(:top50_benchmark).merge(Top50Benchmark.where(name_eng: "Linpack"))
    cpu_qty_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Number of CPUs"))
    @cpu_qty_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(cpu_qty_attrs)
    core_qty_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Number of cores"))
    @core_qty_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(core_qty_attrs)
    rpeak_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Rpeak (MFlop/s)"))
    @rpeak_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(rpeak_attrs)
    com_net_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Communication network"))
    @com_net_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(com_net_attrs)
    serv_net_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Service network"))
    @serv_net_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(serv_net_attrs)
    tran_net_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Transport network"))
    @tran_net_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(tran_net_attrs)
    app_area_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Application area"))
    @app_area_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(app_area_attrs)
    ram_size_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "RAM size (GB)"))
    @ram_size_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(ram_size_attrs)
    cpu_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "CPU model"))
    @cpu_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cpu_model_attrs)
    cpu_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "CPU Vendor"))
    @cpu_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cpu_vendor_attrs)
    gpu_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "GPU model"))
    @gpu_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(gpu_model_attrs)
    gpu_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "GPU Vendor"))
    @gpu_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(gpu_vendor_attrs)
    cop_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Coprocessor model"))
    @cop_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cop_model_attrs)
    cop_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Coprocessor Vendor"))
    @cop_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cop_vendor_attrs)
    @cop_objects = Top50Object.all.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "Coprocessor"))
    @cpu_objects = Top50Object.all.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "CPU"))
    @gpu_objects = Top50Object.all.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "GPU"))
    @acc_objects = Top50Object.all.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "Accelerator").first.top50_object_types)
    comp_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where("name_eng LIKE '% model'"))
    @comp_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(comp_model_attrs)
    comp_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where("name_eng LIKE '% Vendor'"))
    @comp_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(comp_vendor_attrs)
    nmax_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Linpack Nmax"))
    @nmax_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(nmax_attrs)
    prec_relation = Top50Relation.all.joins(:top50_relation_type).merge(Top50RelationType.where(name_eng: "Precedes"))
    @prec_machines = prec_relation.joins(:top50_object).merge(Top50Object.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "Machine")))
    node_platform_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Node platform"))
    @node_platform_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(node_platform_attrs)
    node_platform_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Node platform Vendor"))
    @node_platform_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(node_platform_vendor_attrs)

    microcore_qty_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Number of micro cores"))
    @microcore_qty_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(microcore_qty_attrs)
    
    @name_eng_attrid = get_name_eng_attr_id
    @rel_contain_id = get_rel_contain_id
    @top50_bunch_id = get_bunch_id
    @top50_preview_bunch_id = get_preview_bunch_id
    @top50_benchmarks = Top50Relation.where(prim_obj_id: get_avail_bunches, type_id: @rel_contain_id).pluck(:sec_obj_id)
    @top50_published_benchmarks = Top50Relation.where(prim_obj_id: @top50_bunch_id, type_id: @rel_contain_id).pluck(:sec_obj_id)
    @top50_preview_benchmarks = Top50Relation.where(prim_obj_id: @top50_preview_bunch_id, type_id: @rel_contain_id).pluck(:sec_obj_id)
    @ed_num_attrid = Top50Attribute.where(name_eng: "Edition number").first.id
    @ed_date_attrid = Top50Attribute.where(name_eng: "Edition date").first.id
    @cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first.id
    @acc_typeid = Top50ObjectType.where(name_eng: "Accelerator").first.id
    @acc_all_typeids = Top50ObjectType.where(parent_id: @acc_typeid).pluck(:id)
    @gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first.id
    @cop_typeid = Top50ObjectType.where(name_eng: "Coprocessor").first.id
    @ram_size_attrid = Top50Attribute.where(name_eng: "RAM size (GB)").first.id
    @com_net_attrid = Top50Attribute.where(name_eng: "Communication network").first.id
    @serv_net_attrid = Top50Attribute.where(name_eng: "Service network").first.id
    @tran_net_attrid = Top50Attribute.where(name_eng: "Transport network").first.id
    @rpeak_attrid = Top50Attribute.where(name_eng: "Rpeak (MFlop/s)").first.id
    @app_area_attrid = Top50Attribute.where(name_eng: "Application area").first.id
    @cpu_qty_attrid = Top50Attribute.where(name_eng: "Number of CPUs").first.id
    @core_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first.id
    @microcore_qty_attrid = Top50Attribute.where(name_eng: "Number of micro cores").first.id
    @cpu_model_attrid = Top50Attribute.where(name_eng: "CPU model").first.id
    @cpu_vendor_attrid = Top50Attribute.where(name_eng: "CPU Vendor").first.id
    @gpu_model_attrid = Top50Attribute.where(name_eng: "GPU model").first.id
    @gpu_vendor_attrid = Top50Attribute.where(name_eng: "GPU Vendor").first.id
    @cop_model_attrid = Top50Attribute.where(name_eng: "Coprocessor model").first.id
    @cop_vendor_attrid = Top50Attribute.where(name_eng: "Coprocessor Vendor").first.id
    @rmax_benchid = Top50Benchmark.where(name_eng: "Linpack").first.id
    @place_measureid = Top50MeasureUnit.where(name_eng: 'place').first.id
    @perf_measureid = Top50MeasureUnit.where(name_eng: 'MFlop/s').first.id
    @node_platform_attrid = Top50Attribute.where(name_eng: "Node platform").first.id
    @node_platform_vendor_attrid = Top50Attribute.where(name_eng: "Node platform Vendor").first.id
    
  end
  
  def prepare_archive(edition_id)
    @bench = Top50Benchmark.find(edition_id)
    date_attr = @date_vals.find_by(obj_id: @bench.id)
    ldate = date_attr.value
    @list_year = ldate.split(".")[2]
    @list_month = ldate.split(".")[1]
    @rated_pos = Top50BenchmarkResult.where(benchmark_id: edition_id).order(result: :asc)
    ed_num = (Top50AttributeValDbval.where(attr_id: @ed_num_attrid, obj_id: edition_id).first.value).to_i

    if ed_num == 1
      ed_num = 2
    end
    top50_prev_id = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id, encode(top50_attribute_val_dbvals.value, 'escape') as num").
      where(attr_id: @ed_num_attrid, obj_id: @top50_benchmarks, value: "#{ed_num - 1}").first.obj_id
    @prev_rated_pos = Top50BenchmarkResult.where(benchmark_id: top50_prev_id)
    
    @mach_x_l1 = Top50BenchmarkResult.select("top50_benchmark_results.machine_id as id, top50_benchmark_results.result as pos, ar.sec_obj_id as l1_id, ar.sec_obj_qty as l1_cnt, ao.type_id as l1_typeid").
      joins("join top50_relations ar on ar.prim_obj_id = top50_benchmark_results.machine_id and ar.type_id = #{@rel_contain_id}").
      joins("join top50_objects ao on ao.id = ar.sec_obj_id").
      where("top50_benchmark_results.benchmark_id = #{edition_id}").
      map(&:attributes)
    
    _nested_obj = Struct.new('NestedObject', :id, :type_id, :cnt)
    @mach_l1_hash = Hash.new{|h, k| h[k] = []}
    @l1_objects = []
    @mach_x_l1.each do |rec|
      @mach_l1_hash[rec["id"]] << _nested_obj.new(rec["l1_id"], rec["l1_typeid"], rec["l1_cnt"])
      @l1_objects << rec["l1_id"]
    end
    
    @l1_x_l2 = Top50Relation.select("top50_relations.prim_obj_id as l1_id, top50_relations.sec_obj_id as l2_id, top50_relations.sec_obj_qty as l2_cnt, o.type_id as l2_typeid").
      joins("join top50_objects o on o.id = top50_relations.sec_obj_id").
      where("top50_relations.type_id = #{@rel_contain_id} AND top50_relations.prim_obj_id IN (?)", @l1_objects).
      map(&:attributes)
    
    @l1_l2_hash = Hash.new{|h, k| h[k] = []}
    @l2_objects = []
    @l1_x_l2.each do |rec|
      @l1_l2_hash[rec["l1_id"]] << _nested_obj.new(rec["l2_id"], rec["l2_typeid"], rec["l2_cnt"])
      @l2_objects << rec["l2_id"]
    end
    
    @mach_x_attrd = Top50BenchmarkResult.select("top50_benchmark_results.machine_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, dict_elems.id as elem_id, dict_elems.name as elem_name").
      joins("join top50_attribute_val_dicts avd on avd.obj_id = top50_benchmark_results.machine_id").
      joins("join top50_attributes on top50_attributes.id = avd.attr_id").
      joins("join top50_dictionary_elems dict_elems on dict_elems.id = avd.dict_elem_id").
      where("top50_benchmark_results.benchmark_id = #{edition_id}").
      map(&:attributes)
    
    _attrd_val = Struct.new('AttrDictValue', :attr_id, :attr_name, :elem_id, :elem_name)
    @mach_attrd_hash = Hash.new{|h, k| h[k] = []}
    @mach_x_attrd.each do |rec|
      @mach_attrd_hash[rec["id"]] << _attrd_val.new(rec["attr_id"], rec["attr_name"], rec["elem_id"], rec["elem_name"])
    end
    
    @mach_x_attrdb = Top50BenchmarkResult.select("top50_benchmark_results.machine_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, avd.value").
      joins("join top50_attribute_val_dbvals avd on avd.obj_id = top50_benchmark_results.machine_id").
      joins("join top50_attributes on top50_attributes.id = avd.attr_id").
      where("top50_benchmark_results.benchmark_id = #{edition_id}").
      map(&:attributes)
      
    _attrdb_val = Struct.new('AttrDbValue', :attr_id, :attr_name, :value)
    @mach_attrdb_hash = Hash.new{|h, k| h[k] = []}
    @mach_x_attrdb.each do |rec|
      @mach_attrdb_hash[rec["id"]] << _attrdb_val.new(rec["attr_id"], rec["attr_name"], rec["value"])
    end

    @mach_x_bench = Top50BenchmarkResult.select("top50_benchmark_results.machine_id as id, b.id as benchmark_id, b.name as benchmark_name, br.result, mu.id as measure_id, mu.name as measure_name").
      joins("join top50_benchmark_results br on br.machine_id = top50_benchmark_results.machine_id").
      joins("join top50_benchmarks b on b.id = br.benchmark_id").
      joins("join top50_measure_units mu on mu.id = b.measure_id").
      where("top50_benchmark_results.benchmark_id = #{edition_id}").
      map(&:attributes)

    _bench_res = Struct.new('BenchResult', :benchmark_id, :benchmark_name, :result, :measure_id, :measure_name)
    @mach_bench_hash = Hash.new{|h, k| h[k] = []}
    @mach_x_bench.each do |rec|
      @mach_bench_hash[rec["id"]] << _bench_res.new(rec["benchmark_id"], rec["benchmark_name"], rec["result"], rec["measure_id"], rec["measure_name"])
    end

    @l1_x_attrd = Top50AttributeValDict.select("top50_attribute_val_dicts.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, dict_elems.id as elem_id, dict_elems.name as elem_name").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dicts.attr_id").
      joins("join top50_dictionary_elems dict_elems on dict_elems.id = top50_attribute_val_dicts.dict_elem_id").
      where("top50_attribute_val_dicts.obj_id in (?)", @l1_objects).
      map(&:attributes)
    
    @l1_attrd_hash = Hash.new{|h, k| h[k] = []}
    @l1_x_attrd.each do |rec|
      @l1_attrd_hash[rec["id"]] << _attrd_val.new(rec["attr_id"], rec["attr_name"], rec["elem_id"], rec["elem_name"])
    end
    
    @l1_x_attrdb = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, top50_attribute_val_dbvals.value").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dbvals.attr_id").
      where("top50_attribute_val_dbvals.obj_id in (?)", @l1_objects).
      map(&:attributes)

    @l1_attrdb_hash = Hash.new{|h, k| h[k] = []}
    @l1_x_attrdb.each do |rec|
      @l1_attrdb_hash[rec["id"]] << _attrdb_val.new(rec["attr_id"], rec["attr_name"], rec["value"])
    end
    
    @l2_x_attrd = Top50AttributeValDict.select("top50_attribute_val_dicts.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, dict_elems.id as elem_id, dict_elems.name as elem_name").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dicts.attr_id").
      joins("join top50_dictionary_elems dict_elems on dict_elems.id = top50_attribute_val_dicts.dict_elem_id").
      where("top50_attribute_val_dicts.obj_id in (?)", @l2_objects).
      map(&:attributes)
    
    @l2_attrd_hash = Hash.new{|h, k| h[k] = []}
    @l2_x_attrd.each do |rec|
      @l2_attrd_hash[rec["id"]] << _attrd_val.new(rec["attr_id"], rec["attr_name"], rec["elem_id"], rec["elem_name"])
    end
    
    @l2_x_attrdb = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, top50_attribute_val_dbvals.value").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dbvals.attr_id").
      where("top50_attribute_val_dbvals.obj_id in (?)", @l2_objects).
      map(&:attributes)

    @l2_attrdb_hash = Hash.new{|h, k| h[k] = []}
    @l2_x_attrdb.each do |rec|
      @l2_attrdb_hash[rec["id"]] << _attrdb_val.new(rec["attr_id"], rec["attr_name"], rec["value"])
    end
    
    
  end

  def list
  
    calc_machine_attrs
    
    top50_current_id = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id, encode(top50_attribute_val_dbvals.value, 'escape') as num").
      where(attr_id: @ed_num_attrid, obj_id: @top50_benchmarks).
      order("cast(encode(top50_attribute_val_dbvals.value, 'escape') as int) desc").first.obj_id

    prepare_archive(top50_current_id)

    @top50_machines = Top50Machine.select("top50_machines.*, ed_results.result").
      joins("join top50_benchmark_results ed_results on ed_results.machine_id = top50_machines.id and ed_results.benchmark_id = #{top50_current_id}").
      order("ed_results.result asc").
      map(&:attributes)

  end

  def new_list
    top50_lists = get_top50_lists.pluck(:id)
    list_num_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition number"))
    @list_nums = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_num_attrs)
    list_date_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition date"))
    @date_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_date_attrs)
    @top50_slists = Top50Benchmark.where("name_eng like 'Top50 position%' and id not in (?)", top50_lists).order("updated_at, created_at")

    calc_machine_attrs
    if params.include?(:id)
      top50_current_id = params[:id].to_i
      @editing = true
      @ed_num = (Top50AttributeValDbval.where(attr_id: @ed_num_attrid, obj_id: top50_current_id).first.value).to_i
      @pdate = Date.strptime(Top50AttributeValDbval.where(attr_id: @ed_date_attrid, obj_id: top50_current_id).first.value, '%d.%m.%Y')
      top50_prev = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id, encode(top50_attribute_val_dbvals.value, 'escape') as num").
        where("attr_id = ? and obj_id in (?) and cast(encode(top50_attribute_val_dbvals.value, 'escape') as int) < ?", @ed_num_attrid, @top50_benchmarks, @ed_num).
        order("cast(encode(top50_attribute_val_dbvals.value, 'escape') as int) desc").first
      if top50_prev.present?
        top50_prev_id = top50_prev.obj_id
      else
        top50_prev_id = 0
      end
      @bench = Top50Benchmark.find(top50_current_id)
    else
      top50_prev = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id, encode(top50_attribute_val_dbvals.value, 'escape') as num").
        where(attr_id: @ed_num_attrid, obj_id: @top50_benchmarks).
        order("cast(encode(top50_attribute_val_dbvals.value, 'escape') as int) desc").first
      if top50_prev.present?
        top50_prev_id = top50_prev.obj_id
      else
        top50_prev_id = 0
      end

      @ed_num = (Top50AttributeValDbval.where(attr_id: @ed_num_attrid, obj_id: top50_prev_id).first.value).to_i + 1
      if params.include?(:list_date)
        @pdate = Date.parse(params[:list_date])
      else
        @pdate = Date.today
      end
      @bench = Top50Benchmark.find(top50_prev_id)
    end

    @prev_rated_pos = Top50BenchmarkResult.where(benchmark_id: top50_prev_id)
    
    @mach_x_l1 = Top50Machine.select("top50_machines.id as id, 0 as pos, top50_machines.is_valid as status, ar.sec_obj_id as l1_id, ar.sec_obj_qty as l1_cnt, ao.type_id as l1_typeid").
      joins("join top50_relations ar on ar.prim_obj_id = top50_machines.id and ar.type_id = #{@rel_contain_id}").
      joins("join top50_objects ao on ao.id = ar.sec_obj_id").
      where("top50_machines.is_valid > 0").
      map(&:attributes)
    
    _nested_obj = Struct.new('NestedObject', :id, :type_id, :cnt)
    @mach_l1_hash = Hash.new{|h, k| h[k] = []}
    @l1_objects = []
    @mach_x_l1.each do |rec|
      @mach_l1_hash[rec["id"]] << _nested_obj.new(rec["l1_id"], rec["l1_typeid"], rec["l1_cnt"])
      @l1_objects << rec["l1_id"]
    end
    
    @l1_x_l2 = Top50Relation.select("top50_relations.prim_obj_id as l1_id, top50_relations.sec_obj_id as l2_id, top50_relations.sec_obj_qty as l2_cnt, o.type_id as l2_typeid").
      joins("join top50_objects o on o.id = top50_relations.sec_obj_id").
      where("top50_relations.type_id = #{@rel_contain_id} AND top50_relations.prim_obj_id IN (?)", @l1_objects).
      map(&:attributes)
    
    @l1_l2_hash = Hash.new{|h, k| h[k] = []}
    @l2_objects = []
    @l1_x_l2.each do |rec|
      @l1_l2_hash[rec["l1_id"]] << _nested_obj.new(rec["l2_id"], rec["l2_typeid"], rec["l2_cnt"])
      @l2_objects << rec["l2_id"]
    end
    
    @mach_x_attrd = Top50Machine.select("top50_machines.id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, dict_elems.id as elem_id, dict_elems.name as elem_name").
      joins("join top50_attribute_val_dicts avd on avd.obj_id = top50_machines.id").
      joins("join top50_attributes on top50_attributes.id = avd.attr_id").
      joins("join top50_dictionary_elems dict_elems on dict_elems.id = avd.dict_elem_id").
      where("top50_machines.is_valid > 0").
      map(&:attributes)
    
    _attrd_val = Struct.new('AttrDictValue', :attr_id, :attr_name, :elem_id, :elem_name)
    @mach_attrd_hash = Hash.new{|h, k| h[k] = []}
    @mach_x_attrd.each do |rec|
      @mach_attrd_hash[rec["id"]] << _attrd_val.new(rec["attr_id"], rec["attr_name"], rec["elem_id"], rec["elem_name"])
    end
    
    @mach_x_attrdb = Top50Machine.select("top50_machines.id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, avd.value").
      joins("join top50_attribute_val_dbvals avd on avd.obj_id = top50_machines.id").
      joins("join top50_attributes on top50_attributes.id = avd.attr_id").
      where("top50_machines.is_valid > 0").
      map(&:attributes)
      
    _attrdb_val = Struct.new('AttrDbValue', :attr_id, :attr_name, :value)
    @mach_attrdb_hash = Hash.new{|h, k| h[k] = []}
    @mach_x_attrdb.each do |rec|
      @mach_attrdb_hash[rec["id"]] << _attrdb_val.new(rec["attr_id"], rec["attr_name"], rec["value"])
    end
    
    @l1_x_attrd = Top50AttributeValDict.select("top50_attribute_val_dicts.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, dict_elems.id as elem_id, dict_elems.name as elem_name").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dicts.attr_id").
      joins("join top50_dictionary_elems dict_elems on dict_elems.id = top50_attribute_val_dicts.dict_elem_id").
      where("top50_attribute_val_dicts.obj_id in (?)", @l1_objects).
      map(&:attributes)
    
    @l1_attrd_hash = Hash.new{|h, k| h[k] = []}
    @l1_x_attrd.each do |rec|
      @l1_attrd_hash[rec["id"]] << _attrd_val.new(rec["attr_id"], rec["attr_name"], rec["elem_id"], rec["elem_name"])
    end
    
    @l1_x_attrdb = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, top50_attribute_val_dbvals.value").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dbvals.attr_id").
      where("top50_attribute_val_dbvals.obj_id in (?)", @l1_objects).
      map(&:attributes)

    @l1_attrdb_hash = Hash.new{|h, k| h[k] = []}
    @l1_x_attrdb.each do |rec|
      @l1_attrdb_hash[rec["id"]] << _attrdb_val.new(rec["attr_id"], rec["attr_name"], rec["value"])
    end
    
    @l2_x_attrd = Top50AttributeValDict.select("top50_attribute_val_dicts.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, dict_elems.id as elem_id, dict_elems.name as elem_name").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dicts.attr_id").
      joins("join top50_dictionary_elems dict_elems on dict_elems.id = top50_attribute_val_dicts.dict_elem_id").
      where("top50_attribute_val_dicts.obj_id in (?)", @l2_objects).
      map(&:attributes)
    
    @l2_attrd_hash = Hash.new{|h, k| h[k] = []}
    @l2_x_attrd.each do |rec|
      @l2_attrd_hash[rec["id"]] << _attrd_val.new(rec["attr_id"], rec["attr_name"], rec["elem_id"], rec["elem_name"])
    end
    
    @l2_x_attrdb = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id as id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, top50_attribute_val_dbvals.value").
      joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dbvals.attr_id").
      where("top50_attribute_val_dbvals.obj_id in (?)", @l2_objects).
      map(&:attributes)

    @l2_attrdb_hash = Hash.new{|h, k| h[k] = []}
    @l2_x_attrdb.each do |rec|
      @l2_attrdb_hash[rec["id"]] << _attrdb_val.new(rec["attr_id"], rec["attr_name"], rec["value"])
    end
    
    if params.include?(:id)
      @rated_pos_hash = Top50BenchmarkResult.where(benchmark_id: top50_current_id).map(&:attributes)
      @top50_machines = Top50Machine.select("top50_machines.*, ed_results.result, 1 as in_top50").
        joins("join top50_benchmark_results ed_results on ed_results.machine_id = top50_machines.id and ed_results.benchmark_id = #{@rmax_benchid}").
        order("ed_results.result desc").
        where("(top50_machines.is_valid > 0 and (top50_machines.start_date is null or top50_machines.start_date <= '#{@pdate}') and (top50_machines.end_date is null or top50_machines.end_date > '#{@pdate}')) or top50_machines.id in (?)", @rated_pos_hash.collect{ |x| x['machine_id'] }).
        limit(50).
        map(&:attributes)
      @top50_machines.concat(Top50Machine.select("top50_machines.*, ed_results.result, 0 as in_top50").
        joins("join top50_benchmark_results ed_results on ed_results.machine_id = top50_machines.id and ed_results.benchmark_id = #{@rmax_benchid}").
        order("ed_results.result desc").
        where("((top50_machines.is_valid > 1 and (top50_machines.start_date is null or top50_machines.start_date <= '#{@pdate}') and (top50_machines.end_date is null or top50_machines.end_date > '#{@pdate}')) or top50_machines.id in (?)) and top50_machines.id not in (?)", @rated_pos_hash.collect{ |x| x['machine_id'] }, @top50_machines.collect{ |x| x['id'] }).
        map(&:attributes)
      )
    else    
      @top50_machines = Top50Machine.select("top50_machines.*, ed_results.result, 1 as in_top50").
        joins("join top50_benchmark_results ed_results on ed_results.machine_id = top50_machines.id and ed_results.benchmark_id = #{@rmax_benchid}").
        order("ed_results.result desc").
        where("top50_machines.is_valid > 0 and (top50_machines.start_date is null or top50_machines.start_date <= '#{@pdate}') and (top50_machines.end_date is null or top50_machines.end_date > '#{@pdate}')").
        limit(50).
        map(&:attributes)
      @top50_machines.concat(Top50Machine.select("top50_machines.*, coalesce(ed_results.result, 0) as result, 0 as in_top50").
        joins("left join top50_benchmark_results ed_results on ed_results.machine_id = top50_machines.id and ed_results.benchmark_id = #{@rmax_benchid}").
        order("coalesce(ed_results.result, 0) desc").
        where("(top50_machines.is_valid > 1 and (top50_machines.start_date is null or top50_machines.start_date <= '#{@pdate}') and (top50_machines.end_date is null or top50_machines.end_date > '#{@pdate}')) and top50_machines.id not in (?)", @top50_machines.collect{ |x| x['id'] }).
        map(&:attributes)
      )
    end
  end

  def submit_list_fail(err_msg)
    flash[:error] = err_msg
    new_list
    render :new_list
    return
  end
  
  def admin_links
  end

  def moderate
    if params.include?(:id)
      @top50_machine = Top50Machine.find(params[:id].to_i)
      if @top50_machine.contact_id.present?
        @contact = Top50Contact.find(@top50_machine.contact_id)
      end
      @rel_contain_id = get_rel_contain_id
      @nodes = Top50Relation.select("top50_relations.id as rel_id, ao.id as id, 0 as fake_id, top50_relations.sec_obj_qty as cnt, ao.type_id as type_id, 1 as existing").
        joins("join top50_objects ao on ao.id = top50_relations.sec_obj_id").
        where("top50_relations.prim_obj_id = #{@top50_machine.id} and top50_relations.type_id = #{@rel_contain_id}").
        map(&:attributes)
        
      @comps = Top50Relation.select("top50_relations.id as rel_id, top50_relations.prim_obj_id as node_id, 0 as fake_node_id, ao.id as id, 0 as fake_id, top50_relations.sec_obj_qty as cnt, ao.type_id as type_id, 1 as existing").
        joins("join top50_objects ao on ao.id = top50_relations.sec_obj_id").
        where("top50_relations.type_id = #{@rel_contain_id} AND top50_relations.prim_obj_id IN (?)", @nodes.collect{ |x| x['id'] }).
        map(&:attributes)

      all_obj_ids = [@top50_machine.id] + @nodes.collect{ |x| x['id'] } + @comps.collect{ |x| x['id'] }

      all_obj_x_attrd = Top50AttributeValDict.select("top50_attribute_val_dicts.obj_id as obj_id, 0 as fake_obj_id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, dict_elems.id as elem_id, dict_elems.name as elem_name, 1 as existing").
        joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dicts.attr_id").
        joins("join top50_dictionary_elems dict_elems on dict_elems.id = top50_attribute_val_dicts.dict_elem_id").
        where("top50_attribute_val_dicts.obj_id in (?)", all_obj_ids).
        map(&:attributes)
      
      all_obj_x_attrdb = Top50AttributeValDbval.select("top50_attribute_val_dbvals.obj_id as obj_id, 0 as fake_obj_id, top50_attributes.id as attr_id, top50_attributes.name as attr_name, top50_attribute_val_dbvals.value, 1 as existing").
        joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dbvals.attr_id").
        where("top50_attribute_val_dbvals.obj_id in (?)", all_obj_ids).
        map(&:attributes)
      
      @mach_x_attrd = all_obj_x_attrd.select{ |x| x['obj_id'] == @top50_machine.id }
      @nodes_x_attrd =  all_obj_x_attrd.select{ |x| (@nodes.collect{ |y| y['id'] }).include?(x['obj_id']) }
      @comps_x_attrd = all_obj_x_attrd.select{ |x| (@comps.collect{ |y| y['id'] }).include?(x['obj_id']) }
   
      @mach_x_attrdb = all_obj_x_attrdb.select{ |x| x['obj_id'] == @top50_machine.id }
      @nodes_x_attrdb =  all_obj_x_attrdb.select{ |x| (@nodes.collect{ |y| y['id'] }).include?(x['obj_id']) }
      @comps_x_attrdb = all_obj_x_attrdb.select{ |x| (@comps.collect{ |y| y['id'] }).include?(x['obj_id']) }
      
      @cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first.id
      @acc_typeid = Top50ObjectType.where(name_eng: "Accelerator").first.id
      @acc_all_typeids = Top50ObjectType.where(parent_id: @acc_typeid).pluck(:id)
      @gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first.id
      @cop_typeid = Top50ObjectType.where(name_eng: "Coprocessor").first.id
      @ram_size_attrid = Top50Attribute.where(name_eng: "RAM size (GB)").first.id
      @com_net_attrid = Top50Attribute.where(name_eng: "Communication network").first.id
      @serv_net_attrid = Top50Attribute.where(name_eng: "Service network").first.id
      @tran_net_attrid = Top50Attribute.where(name_eng: "Transport network").first.id
      @rpeak_attrid = Top50Attribute.where(name_eng: "Rpeak (MFlop/s)").first.id
      @app_area_attrid = Top50Attribute.where(name_eng: "Application area").first.id
      @cpu_qty_attrid = Top50Attribute.where(name_eng: "Number of CPUs").first.id
      @core_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first.id
      @microcore_qty_attrid = Top50Attribute.where(name_eng: "Number of micro cores").first.id
      @cpu_model_attrid = Top50Attribute.where(name_eng: "CPU model").first.id
      @cpu_vendor_attrid = Top50Attribute.where(name_eng: "CPU Vendor").first.id
      @gpu_model_attrid = Top50Attribute.where(name_eng: "GPU model").first.id
      @gpu_vendor_attrid = Top50Attribute.where(name_eng: "GPU Vendor").first.id
      @cop_model_attrid = Top50Attribute.where(name_eng: "Coprocessor model").first.id
      @cop_vendor_attrid = Top50Attribute.where(name_eng: "Coprocessor Vendor").first.id

      @prev_machine_ids = Top50Relation.where(sec_obj_id: @top50_machine.id, type_id: get_rel_precede_id).pluck(:prim_obj_id)

    else
      @top50_machine = Top50Machine.new
    end

  end

  def set_attr(o, k, v)
    if v.present?
      o[k] = v
    else
      o[k] = nil
    end
  end
    

  def set_attrs_from_hash(o, h)
    h.each do |k, v|
      set_attr(o, k, v)
    end
  end

  def pre_save
    @obj_to_destroy = params['obj_to_destroy']
    if not @obj_to_destroy.present?
      @obj_to_destroy = []
    end
    moderate
    set_attrs_from_hash(@top50_machine, params['machine'])
    if params.include? 'contact'
      if not @contact.present?
        @contact = Top50Contact.new
      end
      set_attrs_from_hash(@contact, params['contact'])
    end
    case params[:commit]
    when 'Добавить контактное лицо'
      @contact = Top50Contact.new
    when 'Удалить контактное лицо'
      if @contact.id.present?
        @contact.destroy
        @top50_machine[:contact_id] = nil
      end
      @contact = nil
    when 'Добавить группу узлов'
      @nodes.append({
        'rel_id' => nil,
        'id' => nil,
        'fake_id' => nil,
        'cnt' => 0,
        'type_id' => Top50ObjectType.where(name_eng: "CPU").first.id,
        'existing' => 0
      })      
    end
    @top50_machine.save!
    render :moderate
    return
  end

  def change
  end

  def add_preview_list
    list = Top50Benchmark.find(params[:id])
    Top50Relation.create(
      type_id: get_rel_contain_id,
      prim_obj_id: get_preview_bunch_id,
      sec_obj_id: list.id,
    )
    redirect_to proc { top50_machines_archive_path(list.id) }
  end

  def delete_preview_list
    list = Top50Benchmark.find(params[:id])
    r = Top50Relation.find_by(
      type_id: get_rel_contain_id,
      prim_obj_id: get_preview_bunch_id,
      sec_obj_id: list.id,
    )
    if r.present?
      r.destroy
    end
    redirect_to proc { top50_machines_archive_path(list.id) }
  end

  def publish_list
    list = Top50Benchmark.find(params[:id])
    r = Top50Relation.find_by(
      type_id: get_rel_contain_id,
      prim_obj_id: get_preview_bunch_id,
      sec_obj_id: list.id,
    )
    if r.present?
      r.destroy
    end
    Top50Relation.create(
      type_id: get_rel_contain_id,
      prim_obj_id: get_bunch_id,
      sec_obj_id: list.id,
    )
    redirect_to proc { top50_machines_archive_path(list.id) }
  end

  def unpublish_list
    list = Top50Benchmark.find(params[:id])
    r = Top50Relation.find_by(
      type_id: get_rel_contain_id,
      prim_obj_id: get_bunch_id,
      sec_obj_id: list.id,
    )
    if r.present?
      r.destroy
    end
    redirect_to proc { top50_machines_archive_path(list.id) }
  end

  def destroy_list
    list = Top50Benchmark.find(params[:id])
    list.destroy
    redirect_to :top50_machines_archive_lists
  end

  def submit_list
    flash.delete(:error)
    @pdate = Date.parse(params[:list_date])
    @ldate = @pdate.strftime("%d.%m.%Y")
    @new_ed_num = params[:list_num].to_i
    @pos_hash = params['pos']
    @status_hash = params['status']
    res_hash = {}
    if params['commit'] == 'Подтверждаю'
      params['status'].each do |id, val|
        if not [1, 3, 0].include? val.to_i
          submit_list_fail('При подтверждении списка все системы должны иметь статус 0, 1 или 3')
          return
        end
        if val.to_i == 3 and params['pos'][id].to_i <= 0
          submit_list_fail('Системе со статусом 3 должно быть присвоено место в списке! (от 1 до 50)')
          return
        end
      end
          
      params['pos'].each do |id, val|
        pos = val.to_i 
        if pos < 0 or pos > 50
          submit_list_fail(format('Позиция системы в списке не может иметь значние %d', pos))
          return
        end
        if pos > 0
          if res_hash.has_key? pos
            submit_list_fail(format('Позиция %d присвоена нескольким системам!', pos))
            return
          end
          if not [1, 3].include? params['status'][id].to_i
            submit_list_fail(format('Система с позицией %d не может иметь статус %d', pos, params['status'][id].to_i))
            return
          end
          t = Top50BenchmarkResult.new
          t[:machine_id] = id
          t[:result] = pos
          t[:is_valid] = 1
          t[:comment] = format('Top50 place for edition %d', @new_ed_num)
          res_hash[pos] = t
        end
      end

      for i in 1..50
        if not res_hash.has_key? i
          submit_list_fail(format('Позиция %d не присвоена ни одной из систем!', i))
          return
        end
      end

      ed_num_attrid = Top50Attribute.where(name_eng: "Edition number").first.id
      ed_date_attrid = Top50Attribute.where(name_eng: "Edition date").first.id
      if params.include?(:id)
        @list_id = params[:id]
        Top50AttributeValDbval.where({ attr_id: ed_num_attrid, obj_id: @list_id }).delete_all
        Top50AttributeValDbval.where({ attr_id: ed_date_attrid, obj_id: @list_id }).delete_all
      else
        n_list = Top50Benchmark.new 
        n_list[:comment] = format('New Top50 list no. %d by %s', @new_ed_num, @ldate)
        n_list[:name] = format('Позиция в Top50 (#%d)', @new_ed_num)
        n_list[:name_eng] = format('Top50 position (#%d)', @new_ed_num)
        n_list[:is_valid] = 1
        n_list[:measure_id] = Top50MeasureUnit.where(name_eng: 'place').first.id
        n_list.save!
        
        @list_id = n_list.id
      end
      ed_attr = Top50AttributeValDbval.new
      ed_attr[:attr_id] = ed_num_attrid
      ed_attr[:obj_id] = @list_id
      ed_attr[:value] = format('%d', @new_ed_num)
      ed_attr[:is_valid] = 1


      d_attr = Top50AttributeValDbval.new
      d_attr[:attr_id] = ed_date_attrid
      d_attr[:obj_id] = @list_id
      d_attr[:value] = @ldate
      d_attr[:is_valid] = 1

      if not ed_attr.save or not d_attr.save
        if n_list.present?
          n_list.destroy
        end
        raise 'Attribute setting failed!'
      end

      if not params.include?(:id)
        res_hash.each do |k, v|
          v[:benchmark_id] = n_list.id
          if not v.save
            n_list.destroy
            raise 'Result saving failed!'
          end
        end
      end
    end

    params['status'].each do |id, value|
      mach = Top50Machine.find(id.to_i)
      if mach.is_valid != value.to_i
        if value.to_i == 1
          mach.confirm
        else
          mach.update(is_valid: value.to_i)
        end
      end
    end

    if params['commit'] == 'Обновить статусы'
      redirect_to proc { top50_machines_new_list_with_date_path(@pdate.to_s(:db)) }
      return
    end

  end

  def get_top50_lists
    return Top50Benchmark.select("top50_benchmarks.*").joins("join top50_relations on top50_benchmarks.id = top50_relations.sec_obj_id").where("top50_relations.prim_obj_id in (?) and top50_relations.type_id = ?", get_avail_bunches, get_rel_contain_id)
  end 

  def get_top50_lists_sorted
    top50_lists = get_top50_lists
    ed_num_attrid = Top50Attribute.where(name_eng: "Edition number").first.id
    return top50_lists.select("top50_benchmarks.*, encode(top50_attribute_val_dbvals.value, 'escape') as num").joins("join top50_attribute_val_dbvals on top50_attribute_val_dbvals.obj_id = top50_benchmarks.id").where("top50_attribute_val_dbvals.attr_id = ?", ed_num_attrid).order("cast(encode(top50_attribute_val_dbvals.value, 'escape') as int) desc")
  end

  def archive_lists
    @top50_lists = get_top50_lists
    list_num_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition number"))
    @list_nums = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_num_attrs)
    list_date_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition date"))
    @date_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_date_attrs)
    @top50_slists = get_top50_lists_sorted
  end
  
  def get_list_id_by_date(year, month)
    ed_date_attrid = Top50Attribute.where(name_eng: "Edition date").first.id
    attr = Top50AttributeValDbval.find_by("attr_id = ? and obj_id in (?) and value like '__.#{month}.#{year}'", ed_date_attrid, get_top50_lists.pluck(:id))
    if attr.present?
      return attr.obj_id
    else
      return 0
    end
  end

  def fetch_archive_list(list_id)
    if current_user and current_user.may_edit_top50?
      list = Top50Benchmark.find(list_id)
    else
      avail_lists = get_top50_lists
      list = avail_lists.find(list_id)
    end
    calc_machine_attrs
    prepare_archive(list.id)
    return Top50Machine.select("top50_machines.*, ed_results.result").
      joins("join top50_benchmark_results ed_results on ed_results.machine_id = top50_machines.id and ed_results.benchmark_id = #{list.id}")
  end
  #1 BEGIN: my code (упрощенная функция сбора списков)
  def fetch_archive_list_simple(list_id)
    Top50Machine.select("top50_machines.*, ed_results.result")
                .joins("JOIN top50_benchmark_results ed_results ON ed_results.machine_id = top50_machines.id")
                .where("ed_results.benchmark_id = ?", list_id)
  end  
  #1 END: my code
  def archive_common(list_id)
    @top50_machines = fetch_archive_list(list_id).
      order("ed_results.result asc").
      map(&:attributes)
  end
 
  def get_archive
    year = params[:year]
    month = params[:month]
    archive_common(get_list_id_by_date(year, month))
    render :archive
    return
  end

  def archive
    eid = params[:eid].to_i
    archive_common(eid)
  end
  
  #2 BEGIN: my code (Скачивание архивов, контроллер)
  def get_dict_attr(obj_id, attr_name)
    attr = Top50Attribute.find_by(name_eng: attr_name)
    return "н/д" unless attr
  
    Top50AttributeValDict
      .includes(:top50_dictionary_elem)
      .find_by(obj_id: obj_id, attr_id: attr.id)&.top50_dictionary_elem&.name || "н/д"
  end
  

  def prepare_csv_data(list_id)
    machines = fetch_archive_list(list_id)
  
    machines.map do |machine|
      rank_pos = @rated_pos.find_by(machine_id: machine.id)
      prev_rank_pos = @prev_rated_pos.find_by(machine_id: machine.id)
  
      org = machine.top50_organization
      city = org&.top50_city&.name
  
      vendor_names = machine.vendor_ids.map { |v_id| Top50Vendor.find_by(id: v_id)&.name }.compact.join(", ")
  
      com_net  = @com_net_attr_vals.find_by(obj_id: machine.id)&.top50_dictionary_elem&.name || "н/д"
      serv_net = @serv_net_attr_vals.find_by(obj_id: machine.id)&.top50_dictionary_elem&.name || "н/д"
      tran_net = @tran_net_attr_vals.find_by(obj_id: machine.id)&.top50_dictionary_elem&.name || "н/д"
  
      app_area = get_dict_attr(machine.id, "Application area")
      os = get_dict_attr(machine.id, "Operating System")
  
      rmax_record = @rmax_res.find_by(machine_id: machine.id)
      rpeak_record = @rpeak_attr_vals.find_by(obj_id: machine.id)
      nmax_val = @nmax_attr_vals.find_by(obj_id: rmax_record&.id)&.value
  
      node_rels = Top50Relation.where(prim_obj_id: machine.id, type_id: @rel_contain_id)
      node_count = node_rels.sum(:sec_obj_qty)
  
      cpu_count, gpu_count, cop_count, ram_per_node = 0, 0, 0, nil
      cpu_info, gpu_info, cop_info = [], [], []
  
      node_rels.each do |node_rel|
        node = Top50Object.find_by(id: node_rel.sec_obj_id)
        next unless node
  
        ram_val = Top50AttributeValDbval.find_by(obj_id: node.id, attr_id: @ram_size_attrid)
        ram_per_node ||= ram_val&.value.to_f if ram_val.present?
  
        child_rels = Top50Relation.where(prim_obj_id: node.id, type_id: @rel_contain_id)
  
        child_rels.each do |child_rel|
          obj = Top50Object.find_by(id: child_rel.sec_obj_id)
          next unless obj
  
          qty = child_rel.sec_obj_qty * node_rel.sec_obj_qty
  
          case obj.type_id
          when @cpu_typeid
            cpu_count += qty
            vendor = @l2_attrd_hash[obj.id].find { |x| x.attr_id == @cpu_vendor_attrid }&.elem_name
            model = @l2_attrd_hash[obj.id].find { |x| x.attr_id == @cpu_model_attrid }&.elem_name
            core = @l2_attrdb_hash[obj.id].find { |x| x.attr_id == @core_qty_attrid }&.value
            cpu_info << "#{qty}x #{vendor} #{model} (#{core} cores)"
          when @gpu_typeid
            gpu_count += qty
            vendor = @l2_attrd_hash[obj.id].find { |x| x.attr_id == @gpu_vendor_attrid }&.elem_name
            model = @l2_attrd_hash[obj.id].find { |x| x.attr_id == @gpu_model_attrid }&.elem_name
            core = @l2_attrdb_hash[obj.id].find { |x| x.attr_id == @core_qty_attrid }&.value
            gpu_info << "#{qty}x #{vendor} #{model} (#{core} cores)"
          when @cop_typeid
            cop_count += qty
            vendor = @l2_attrd_hash[obj.id].find { |x| x.attr_id == @cop_vendor_attrid }&.elem_name
            model = @l2_attrd_hash[obj.id].find { |x| x.attr_id == @cop_model_attrid }&.elem_name
            core = @l2_attrdb_hash[obj.id].find { |x| x.attr_id == @core_qty_attrid }&.value
            cop_info << "#{qty}x #{vendor} #{model} (#{core} cores)"
          end
        end
      end
  
      dbvals = @mach_attrdb_hash[machine.id].map { |x| "#{x.attr_name}: #{x.value}" }
      dictvals = @mach_attrd_hash[machine.id].map { |x| "#{x.attr_name}: #{x.elem_name}" }
  
      {
        id: machine.id,
        name: machine.name,
        rank: rank_pos&.result&.to_i,
        previous_rank: prev_rank_pos&.result&.to_i,
        edition: @bench&.name_eng,
        start_date: machine.start_date,
        end_date: machine.end_date,
        organization: org&.name,
        city: city,
        vendors: vendor_names,
        cpu_count: cpu_count,
        gpu_count: gpu_count,
        cop_count: cop_count,
        node_count: node_count,
        ram_per_node: ram_per_node,
        rmax: rmax_record&.result,
        rpeak: rpeak_record&.value,
        nmax: nmax_val,
        benchmark: rmax_record&.top50_benchmark&.name,
        measure: rmax_record&.top50_benchmark&.top50_measure_unit&.name,
        cpu_info: cpu_info.join(" / "),
        gpu_info: gpu_info.join(" / "),
        cop_info: cop_info.join(" / "),
        communication_network: com_net,
        service_network: serv_net,
        transport_network: tran_net,
        application_area: app_area,
        operating_system: os,
        other_db_attributes: dbvals.join(" | "),
        other_dictionary_attributes: dictvals.join(" | ")
      }
    end
  end
  def download_archive
    year = params[:year]
    month = params[:month]
    calc_machine_attrs
    list_id = get_list_id_by_date(year, month)
  
    return redirect_to archive_path, alert: 'Архив не найден.' if list_id.zero?
    prepare_archive(list_id)
  
    csv_data = CSV.generate(headers: true) do |csv|
      headers = [
        "ID", "Name", "Rank", "Previous Rank", "Edition", "Start Date", "End Date",
        "Organization", "City", "Vendors",
        "CPU Count", "GPU Count", "COP Count", "Node Count", "RAM per Node",
        "Rmax", "Rpeak", "Nmax", "Benchmark", "Measure",
        "CPU Info", "GPU Info", "COP Info",
        "Communication Network", "Service Network", "Transport Network",
        "Application Area", "Operating System",
        "Other DB Attributes", "Other Dictionary Attributes"
      ]
      csv << headers
  
      prepare_csv_data(list_id).each do |row|
        csv << headers.map { |h| row[h.parameterize.underscore.to_sym] }
      end
    end
  
    send_data csv_data, filename: "top50_export_#{year}_#{month}.csv", type: 'text/csv; charset=utf-8'
  end
#2 END: my code
  def archive_by_vendor_common(list_id)
    @vendor = Top50Vendor.find(params[:vid])
    @top50_machines = fetch_archive_list(list_id).
      where("#{@vendor.id} = ANY(top50_machines.vendor_ids)").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_vendor
    year = params[:year]
    month = params[:month]
    archive_by_vendor_common(get_list_id_by_date(year, month))
    render :archive_by_vendor
    return
  end

  def archive_by_vendor
    eid = params[:eid].to_i
    archive_by_vendor_common(eid)
  end
    
  def archive_by_vendor_excl_common(list_id)
    @vendor = Top50Vendor.find(params[:vid])
    @top50_machines = fetch_archive_list(list_id).
      where("#{@vendor.id} = ALL(top50_machines.vendor_ids)").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_vendor_excl
    year = params[:year]
    month = params[:month]
    archive_by_vendor_excl_common(get_list_id_by_date(year, month))
    render :archive_by_vendor_excl
    return
  end

  def archive_by_vendor_excl
    eid = params[:eid].to_i
    archive_by_vendor_excl_common(eid)
  end
    
  def archive_by_org_common(list_id)
    @org = Top50Organization.find(params[:oid])
    @top50_machines = fetch_archive_list(list_id).
      where("top50_machines.org_id in (select #{@org.id} union all select sec_obj_id from top50_relations a where a.prim_obj_id = #{@org.id} and a.type_id = #{get_rel_contain_id})").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_org
    year = params[:year]
    month = params[:month]
    archive_by_org_common(get_list_id_by_date(year, month))
    render :archive_by_org
    return
  end

  def archive_by_org
    eid = params[:eid].to_i
    archive_by_org_common(eid)
  end

  def archive_by_city_common(list_id)
    @city = Top50City.find(params[:cid])
    @top50_machines = fetch_archive_list(list_id).
      where("top50_machines.org_id in (select id from top50_organizations a where a.city_id = #{@city.id})").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_city
    year = params[:year]
    month = params[:month]
    archive_by_city_common(get_list_id_by_date(year, month))
    render :archive_by_city
    return
  end

  def archive_by_city
    eid = params[:eid].to_i
    archive_by_city_common(eid)
  end
  
  def archive_by_country_common(list_id)
    @country = Top50Country.find(params[:cid])
    @top50_machines = fetch_archive_list(list_id).
      where("top50_machines.org_id in (select a.id from top50_organizations a join top50_cities b on a.city_id = b.id join top50_regions c on b.region_id = c.id where c.country_id = #{@country.id})").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_country
    year = params[:year]
    month = params[:month]
    archive_by_country_common(get_list_id_by_date(year, month))
    render :archive_by_country
    return
  end

  def archive_by_country
    eid = params[:eid].to_i
    archive_by_country_common(eid)
  end
   
  def archive_by_comp_common(list_id)
    @comp = Top50Object.find(params[:oid])
    @top50_machines = fetch_archive_list(list_id).
      where("exists(select 1 from top50_relations a join top50_relations b on b.prim_obj_id = a.sec_obj_id where b.sec_obj_id = #{@comp.id} and a.prim_obj_id = top50_machines.id and a.type_id = #{get_rel_contain_id} and b.type_id = #{get_rel_contain_id})").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_comp
    year = params[:year]
    month = params[:month]
    archive_by_comp_common(get_list_id_by_date(year, month))
    render :archive_by_comp
    return
  end

  def archive_by_comp
    eid = params[:eid].to_i
    archive_by_comp_common(eid)
  end
    
  def archive_by_comp_attrd_common(list_id)
    @dict_elem = Top50DictionaryElem.find(params[:elid])
    @top50_machines = fetch_archive_list(list_id).
      where("exists(select 1 from top50_relations a join top50_relations b on b.prim_obj_id = a.sec_obj_id join top50_attribute_val_dicts d on d.obj_id = b.sec_obj_id where d.dict_elem_id = #{@dict_elem.id} and a.prim_obj_id = top50_machines.id and a.type_id = #{get_rel_contain_id} and b.type_id = #{get_rel_contain_id})").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_comp_attrd
    year = params[:year]
    month = params[:month]
    archive_by_comp_attrd_common(get_list_id_by_date(year, month))
    render :archive_by_comp_attrd
    return
  end

  def archive_by_comp_attrd
    eid = params[:eid].to_i
    archive_by_comp_attrd_common(eid)
  end
    
  def archive_by_attr_dict_common(list_id)
    @attr = Top50Attribute.find(params[:aid])
    @dict_elem = Top50DictionaryElem.find(params[:elid])
    @top50_machines = fetch_archive_list(list_id).
      where("exists(select 1 from top50_attribute_val_dicts where dict_elem_id = #{@dict_elem.id} and obj_id = top50_machines.id and attr_id = #{@attr.id})").
      order("ed_results.result asc").
      map(&:attributes)
  end

  def get_archive_by_attr_dict
    year = params[:year]
    month = params[:month]
    archive_by_attr_dict_common(get_list_id_by_date(year, month))
    render :archive_by_attr_dict
    return
  end

  def archive_by_attr_dict
    eid = params[:eid].to_i
    archive_by_attr_dict_common(eid)
  end
 
  def benchmark_results
    @top50_machine = Top50Machine.find(params[:id])
  end

  def add_benchmark_result
    @top50_machine = Top50Machine.find(params[:id])
  end

  def create_benchmark_result
    @top50_machine = Top50Machine.find(params[:id])
    @top50_benchmark_result = @top50_machine.top50_benchmark_results.build(top50_benchmark_result_params)
    if @top50_benchmark_result.save
      redirect_to proc { top50_machine_top50_benchmark_results_path(@top50_machine.id) }
    else
      render :new_top50_machine_top50_benchmark_result
    end
  end

  def edit_benchmark_result
    @top50_benchmark_result = Top50BenchmarkResult.find(params[:brid])
    @top50_machine = Top50Machine.find(params[:id])
  end

  def save_benchmark_result
    @top50_benchmark_result = Top50BenchmarkResult.find(params[:brid])
    @top50_machine = Top50Machine.find(params[:id])
    @top50_benchmark_result.update(top50_benchmark_result_params)
    @top50_benchmark_result.save!
    redirect_to proc { top50_machine_top50_benchmark_results_path(@top50_machine.id) }
  end

  def destroy_benchmark_result
    @top50_benchmark_result = Top50BenchmarkResult.find(params[:brid])
    @top50_machine = Top50Machine.find(params[:id])
    @top50_benchmark_result.destroy!
    redirect_to proc { top50_machine_top50_benchmark_results_path(@top50_machine.id) }
  end

  def tree_prec_sql(obj_id)
    "with recursive r as (
     select prim_obj_id, sec_obj_id, rel.id, 1 as level
     from top50_relations rel
     join top50_relation_types rel_t on rel_t.id = rel.type_id and rel_t.name_eng = 'Precedes'
     where sec_obj_id = #{obj_id}

     union all

     select rel.prim_obj_id, rel.sec_obj_id, rel.id, r.level + 1 as level
     from top50_relations rel
     join top50_relation_types rel_t on rel_t.id = rel.type_id and rel_t.name_eng = 'Precedes'
     join r
     on rel.sec_obj_id = r.prim_obj_id
     )
     select prim_obj_id from r
     union all
     select #{obj_id}"
  end
  
  
  def show
    if current_user and current_user.may_preview?
      @top50_machine = Top50Machine.find(params[:id])
    else
      @top50_machine = Top50Machine.where(is_valid: 1).find(params[:id])
    end
    calc_machine_attrs
    @perf_measured_attrs = [@rpeak_attrid]

    @top50_lists = get_top50_lists
    @top50_slists = get_top50_lists_sorted
    list_num_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition number"))
    @list_nums = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_num_attrs)
    list_date_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition date"))
    @date_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_date_attrs)
    @top50_res = Top50BenchmarkResult.all.joins(:top50_benchmark).merge(@top50_lists)
    @top50_incl = @top50_res.select("top50_benchmark_results.*, encode(top50_attribute_val_dbvals.value, 'escape') as num").joins("join top50_attribute_val_dbvals on top50_attribute_val_dbvals.obj_id = top50_benchmark_results.benchmark_id").joins("join top50_attributes on top50_attributes.id = top50_attribute_val_dbvals.attr_id and top50_attributes.name_eng = 'Edition number'").where("top50_benchmark_results.machine_id IN (#{tree_prec_sql(@top50_machine.id)})").order("cast(encode(top50_attribute_val_dbvals.value, 'escape') as int)")

    #5 BEGIN: my code (Линия жизни на поверхности в разделе расширенной статистики)
    list_date_attr_id = Top50Attribute.find_by(name_eng: "Edition date").id
    date_vals_map = Top50AttributeValDbval.where(attr_id: list_date_attr_id, obj_id: @top50_slists.map(&:id)).index_by(&:obj_id)
    
    @edition_labels = @top50_slists.map do |list|
      date_vals_map[list.id]&.value || "??.??.????"
    end
    
    @ranks          = (1..50).to_a
    @z_data         = Array.new(50) { [] }
    @machine_names  = Array.new(50) { [] }
    @machine_ids    = Array.new(50) { [] }
    @machine_status = Array.new(50) { [] }
    @life_line_segments = []
    
    rmax_bench = Top50Benchmark.find_by(name_eng: "Linpack")
    rmax_by_machine = Top50BenchmarkResult.where(benchmark_id: rmax_bench.id).index_by(&:machine_id)
    
    life_machine_ids = ActiveRecord::Base.connection.execute(tree_prec_sql(@top50_machine.id)).values.flatten.map(&:to_i)
    
    precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
    @prec_machines = precedes_type_id ? Top50Relation.where(type_id: precedes_type_id, is_valid: [1, 2]) : []
    
    current_segment = { x: [], y: [], z: [], ids: [], update_flags: [], name: @top50_machine.name }
    previous_idx = nil
    
    @top50_slists.each_with_index do |list, idx|
      machines = fetch_archive_list_simple(list.id)
    
      prev_rated_pos_map = {}
      if idx + 1 < @top50_slists.size
        prev_list = @top50_slists[idx + 1]
        prev_machines = fetch_archive_list_simple(prev_list.id)
        prev_rated_pos_map = prev_machines.index_by(&:id)
      end
    
      machines_with_rmax = machines.map do |machine|
        rmax = rmax_by_machine[machine.id]
        status = :new
    
        prec_rel = @prec_machines.find { |rel| rel.sec_obj_id == machine.id }
        if prec_rel
          prev_machine_id = prec_rel.prim_obj_id
          if prev_rated_pos_map.key?(prev_machine_id)
            status = :upgrade
          elsif prev_rated_pos_map.key?(machine.id)
            status = :existing
          end
        elsif prev_rated_pos_map.key?(machine.id)
          status = :existing
        end
    
        [machine, rmax&.result.to_f || 0.0001, status]
      end
    
      top50_sorted = machines_with_rmax.sort_by { |_, rmax, _| -rmax }.first(50)
    
      rmax_values = top50_sorted.map { |_, rmax, _| (rmax / 1_000_000.0).round(4) }
      names       = top50_sorted.map { |m, _, _| m.name.presence || m.top50_organization&.name || "н/д" }
      ids         = top50_sorted.map { |m, _, _| m.id }
      statuses    = top50_sorted.map { |_, _, status| status.to_s }
    
      rmax_values.fill(0.0001, rmax_values.size...50)
      names.fill("н/д", names.size...50)
      ids.fill(nil, ids.size...50)
      statuses.fill("none", statuses.size...50)
    
      rmax_values.each_with_index { |val, i| @z_data[i] << val }
      names.each_with_index      { |val, i| @machine_names[i] << val }
      ids.each_with_index        { |val, i| @machine_ids[i] << val }
      statuses.each_with_index  { |val, i| @machine_status[i] << val }
    
      top50_sorted.each_with_index do |(machine, rmax, _), i|
        if life_machine_ids.include?(machine.id)
          if previous_idx && idx - previous_idx > 1
            if current_segment[:x].any?
              @life_line_segments << current_segment
              current_segment = { x: [], y: [], z: [], ids: [], update_flags: [], name: @top50_machine.name }
            end
          end
    
          current_segment[:x] << i + 1
          current_segment[:y] << @edition_labels[idx]
          current_segment[:z] << (rmax / 1_000_000.0).round(4)
          current_segment[:ids] << machine.id
    
          status = @machine_status[i][idx] rescue nil
          current_segment[:update_flags] << (status == 'upgrade')
    
          previous_idx = idx
        end
      end
    end
    
   
    @life_line_segments << current_segment if current_segment[:x].any?
    

    @z_data         = @z_data.transpose
    @machine_names  = @machine_names.transpose
    @machine_ids    = @machine_ids.transpose
    @machine_status = @machine_status.transpose
    
  end

  def stats_common

    @top50_lists = get_top50_lists
    @top50_slists = get_top50_lists_sorted

    all_res = Top50BenchmarkResult.all.joins(:top50_benchmark).merge(@top50_lists)
    
    list_num_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition number"))
    @num_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_num_attrs)
    list_date_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition date"))
    @date_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_date_attrs)
    
  end
  
  def stats_per_list_common(eid)
    @list_id = get_top50_lists.find(eid).id
    stats(1)
    @top50_mtypes = get_avail_mtypes
    @back_to_stats_url = if @upgradability_section_keys && @stat_section.present? && @upgradability_section_keys.include?(@stat_section)
                           top50_upgradability_stats_path(@stat_section)
                         elsif @stat_section.present?
                           top50_stats_path(@stat_section)
                         else
                           top50_stats_def_path
                         end
  end

  def get_stats_per_list
    stats_per_list_common(get_list_id_by_date(params[:year], params[:month]))
    render :stats_per_list
    return
  end

  def stats_per_list
    stats_per_list_common(params[:eid].to_i)
  end

  #4 BEGIN: my code (Дебаг)
  def debug_attributes_for(obj, level = 0)
    indent = "  " * level
    puts "\n#{indent}>>> Объект ID=#{obj.id}, Тип=#{obj.try(:top50_object_type)&.name_eng || 'Top50Machine'}"
    puts "#{indent}  Название: #{obj.name}" if obj.respond_to?(:name)
  
    puts "#{indent}  Start Date: #{obj.start_date}" if obj.respond_to?(:start_date) && obj.start_date
    puts "#{indent}  End Date: #{obj.end_date}" if obj.respond_to?(:end_date) && obj.end_date
  
    if obj.respond_to?(:org_id) && obj.org_id
      org = Top50Organization.find_by(id: obj.org_id)
      if org
        puts "#{indent}  Организация: #{org.name}"
        puts "#{indent}  Город: #{org.top50_city&.name}" if org.top50_city
      end
    end
  
    if obj.respond_to?(:vendor_ids)
      vendors = Top50Vendor.where(id: obj.vendor_ids)
      puts "#{indent}  Разработчики: #{vendors.map(&:name).join(', ')}"
    end
  
    Top50AttributeValDbval
      .includes(top50_attribute_dbval: :top50_attribute)
      .where(obj_id: obj.id)
      .each do |val|
        attr = val.top50_attribute_dbval.top50_attribute
        puts "#{indent}  [DBVAL] #{attr.name_eng}: #{val.value}"
      end

    Top50AttributeValDict
      .includes(top50_attribute_dict: :top50_attribute, top50_dictionary_elem: {})
      .where(obj_id: obj.id)
      .each do |val|
        attr = val.top50_attribute_dict.top50_attribute
        name = val.top50_dictionary_elem&.name || "?"
        puts "#{indent}  [DICT]  #{attr.name_eng}: #{name}"
      end
  
    Top50BenchmarkResult
      .includes(:top50_benchmark)
      .where(machine_id: obj.id)
      .each do |res|
        bench = res.top50_benchmark
        puts "#{indent}  [BENCH] #{bench.name_eng}: #{res.result}"
      end

    if obj.respond_to?(:id)
      %w[Communication network Service network Transport network].each do |network_type|
        attr = Top50Attribute.find_by(name_eng: network_type)
        next unless attr
        dict_val = Top50AttributeValDict.find_by(obj_id: obj.id, attr_id: attr.id)
        net_val = dict_val&.top50_dictionary_elem&.name
        puts "#{indent}  #{network_type}: #{net_val || 'н/д'}"
      end
    end
  
    if defined?(@prev_rated_pos)
      prev = @prev_rated_pos.find { |p| p.machine_id == obj.id }
      if prev
        puts "#{indent}  Предыдущее место: #{prev.result}"
      end
    end
  
    rel_type = Top50RelationType.find_by(name_eng: "Contains")
    return unless rel_type
  
    Top50Relation
      .includes(:top50_object)
      .where(prim_obj_id: obj.id, type_id: rel_type.id)
      .each do |rel|
        child = rel.top50_object
        puts "#{indent}  [CONTAINS] ID=#{child.id}, Тип=#{child.top50_object_type&.name_eng || 'N/A'} (кол-во: #{rel.sec_obj_qty})"
        debug_attributes_for(child, level + 1)
      end
  end
  #4 END: my code
  
  def stats(ext = 0)
    @stat_section = params[:section]
    
    @section_headers = {}
    @section_headers["performance"] = "производительность систем"
    @section_headers["performance_3d"] = "производительность систем (LINPACK, 3D)"
    @section_headers["area"] = "область применения"
    @section_headers["city"] = "расположение систем"
    @section_headers["type"] = "типы систем"
    @section_headers["hybrid_inter"] = "гибридность систем (количество узлов разных типов)"
    @section_headers["hybrid_intra"] = "гибридность систем (наличие ускорителей на узлах)"
    @section_headers["vendors"] = "разработчики вычислительных систем"
    @section_headers["cpu_vendor"] = "производители CPU"
    @section_headers["cpu_vendor_3d"] = "производители CPU (3D)"
    @section_headers["acc_vendor_3d"] = "производители ускорителей (3D)"
    @section_headers["cpu_fam"] = "семейства CPU"
    @section_headers["cpu_gen"] = "микроархитектура CPU"
    @section_headers["cpu_cnt"] = "количество CPU"
    @section_headers["freshest_components_lag"] = "отставание самых свежих компонент"
    @section_headers["new_upg"] = "количество новых и обновлённых систем и их доля в производительности"
    @section_headers["ram_stats"] = "среднее количество памяти"
    @section_headers["component_stats"] = "количество компонент"
    @section_headers["freshest_comp_stats"] = "статистика новых компонент"
    @section_headers["list_upg"] = "изменение позиций машин в рейтинге"
    @section_headers["core_cnt"] = "количество вычислительных ядер"
    @section_headers["comm_net"] = "семейства коммуникационных сетей"
    @section_headers["comm_net_sep"] = "коммуникационные сети"
    @section_headers["performance_3d_with_machine_status"] = "обновляемость систем (3D)"
    @section_headers["heatmap_streaks"] = "количество лет в рейтинге от номера редакции"
    @section_headers["heatmap_rank_vs_years"] = "количество лет в рейтинге от начальной позиции"
    @section_headers["upgradability"] = "обновляемость"

    # Subsections under stats/upgradability/ (welcome = freshest_components_lag, rest choosable)
    @upgradability_section_keys = %w[
      freshest_components_lag
      new_upg
      ram_stats
      component_stats
      freshest_comp_stats
      list_upg
      performance_3d_with_machine_status
      heatmap_streaks
      heatmap_rank_vs_years
    ].freeze
    # Main stats dropdown: exclude upgradability subsections (they live under stats/upgradability)
    @main_section_headers = @section_headers.reject { |k, _| @upgradability_section_keys.include?(k) }

    # Upgradability landing: show welcome section (freshest_components_lag); load its data
    go_section = params[:go].is_a?(Array) ? params[:go].first : params[:go]
    if @stat_section == "upgradability" && go_section.present? && @upgradability_section_keys.include?(go_section)
      redirect_to top50_upgradability_stats_path(go_section), allow_other_host: false and return
    end
    @stat_section_for_loading = (@stat_section == "upgradability") ? "freshest_components_lag" : @stat_section

    @header_text = "Статистика: " + @section_headers["performance"]
    if @stat_section.present?
      if @stat_section == "upgradability" || (@upgradability_section_keys && @upgradability_section_keys.include?(@stat_section))
        @header_text = "Статистика: " + @section_headers["upgradability"]
      elsif @section_headers.has_key?(@stat_section)
        @header_text = "Статистика: " + @section_headers[@stat_section]
      elsif @stat_section[0..6] == 'vendors'
        @header_text = "Статистика: " + @section_headers["vendors"]
      end
    end
    
    if ext == 1
      _top50_cat = Struct.new('Top50Category', :id, :name)
    end
          
    list_num_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition number"))
    @num_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_num_attrs)
    list_date_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Edition date"))
    @date_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(list_date_attrs)
    rel_contain_id = get_rel_contain_id
    top50_benchmarks = Top50Relation.where(prim_obj_id: get_avail_bunches, type_id: rel_contain_id).pluck(:sec_obj_id)
    @mach_approved = Top50BenchmarkResult.where(:benchmark_id => top50_benchmarks).pluck(:machine_id)
    if ext == 1
      @mach_approved = Top50BenchmarkResult.where(:benchmark_id => @list_id).pluck(:machine_id)
    end
    @top50_lists = get_top50_lists
    @top50_slists = get_top50_lists_sorted
    if @stat_section == 'hybrid_inter'
      comp_node_id = Top50ObjectType.where(name_eng: 'Compute node').first.id
      @hybrid_mach = {}
      machines = Top50Machine.select("top50_machines.id").
          joins("join top50_relations r on r.prim_obj_id = top50_machines.id and r.type_id = #{rel_contain_id}").
          joins("join top50_objects o on o.id = r.sec_obj_id and o.type_id = #{comp_node_id}").
          group("top50_machines.id")
      (1..20).each do |i|
        ids = machines.having("count(1) = #{i}").
          pluck("top50_machines.id")
        if ids.count > 0
          @hybrid_mach[i] = ids
        end
      end
    elsif @stat_section == 'hybrid_intra'
      acc_type_id = Top50ObjectType.where(name_eng: 'Accelerator').first.id
      acc_child_types = Top50ObjectType.where(parent_id: acc_type_id).pluck(:id)
      @hybrid_mach = Top50Machine.select("top50_machines.id").
        joins("join top50_relations ar on ar.prim_obj_id = top50_machines.id and ar.type_id = #{rel_contain_id}").
        joins("join top50_relations br on br.prim_obj_id = ar.sec_obj_id and br.type_id = #{rel_contain_id}").
        joins("join top50_objects o on o.id = br.sec_obj_id").
        where("o.type_id IN (?)", acc_child_types).
        pluck("distinct top50_machines.id")
    elsif @stat_section == 'cpu_vendor'
      cpu_vendor_dict_id = Top50Dictionary.where(name_eng: 'CPU Vendor').first.id
      @mach_x_cpuvendors = Top50DictionaryElem.all.select("top50_dictionary_elems.id, top50_dictionary_elems.name, top50_machines.id mach_id").
        joins("join top50_attribute_val_dicts on top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id").
        joins("join top50_machines on exists (
                select 1 from top50_relations ar join top50_relations br on br.prim_obj_id = ar.sec_obj_id 
                 where ar.prim_obj_id = top50_machines.id 
                   and br.sec_obj_id = top50_attribute_val_dicts.obj_id
                   and ar.type_id = #{rel_contain_id}
                   and br.type_id = #{rel_contain_id}
              )").
        where("top50_dictionary_elems.dict_id = #{cpu_vendor_dict_id}
           AND top50_machines.id IN (?)", @mach_approved).
        map(&:attributes)
      _cpuvendor = Struct.new('CPUVendor', :id, :name)
      @cpuvendor_id_hash = Hash.new{|h, k| h[k] = []}
      @top50_cpuvendors = []
      @mach_x_cpuvendors.each do |rec|
        if @cpuvendor_id_hash[rec["id"]].empty?
          @top50_cpuvendors << _cpuvendor.new(rec["id"], rec["name"])
        end
        @cpuvendor_id_hash[rec["id"]] << rec["mach_id"]
      end
    elsif @stat_section == 'cpu_fam' or @stat_section == 'cpu_gen'
      if @stat_section == 'cpu_fam'
        cpu_fam_dict_id = Top50Dictionary.where(name_eng: 'CPU families').first.id
        @chart_title = "Распределение систем по типам CPU"
      else
        cpu_fam_dict_id = Top50Dictionary.where(name_eng: 'CPU generations').first.id
        @chart_title = "Распределение систем по микроархитектурам CPU"
      end
      @mach_x_cpufams = Top50DictionaryElem.all.select("top50_dictionary_elems.id fam_id, top50_dictionary_elems.name fam_name, top50_machines.id mach_id").
        joins("join top50_attribute_val_dicts on top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id").
        joins("join top50_machines on exists (
                select 1 from top50_relations ar join top50_relations br on br.prim_obj_id = ar.sec_obj_id 
                 where ar.prim_obj_id = top50_machines.id 
                   and br.sec_obj_id = top50_attribute_val_dicts.obj_id
                   and ar.type_id = #{rel_contain_id}
                   and br.type_id = #{rel_contain_id}
              )").
        where("top50_dictionary_elems.dict_id = #{cpu_fam_dict_id}
           AND top50_machines.id IN (?)", @mach_approved).
        map(&:attributes)
      _cpufam = Struct.new('CPUFam', :fam_id, :fam_name)
      @cpufam_id_hash = Hash.new{|h, k| h[k] = []}
      top50_cpufams_all = []
      @top50_cats_all = []
      @mach_x_cpufams.each do |rec|
        if @cpufam_id_hash[rec["fam_id"]].empty?
          top50_cpufams_all << _cpufam.new(rec["fam_id"], rec["fam_name"])
          if ext == 1
            @top50_cats_all << _top50_cat.new(rec["fam_id"], rec["fam_name"])
          end
        end
        @cpufam_id_hash[rec["fam_id"]] << rec["mach_id"]
      end
      sorted_cpufam_id_hash = @cpufam_id_hash.sort_by { |k, v| -v.size }
      @top50_cpufams = []
      sorted_cpufam_id_hash[1..10].each { |k| @top50_cpufams << top50_cpufams_all.find{|x| x.fam_id == k[0]} }
      if ext == 1        
        @sorted_cat_id_hash = sorted_cpufam_id_hash
        @top50_cat_id_hash = @cpufam_id_hash
        @top50_cats = []
        sorted_cpufam_id_hash[1..10].each do |k| 
          cpu_fam = top50_cpufams_all.find{|x| x.fam_id == k[0]}
          @top50_cats << _top50_cat.new(cpu_fam.fam_id, cpu_fam.fam_name)
        end
      end
    #3 BEGIN: my code (Реализация методов представления, контроллер)
    elsif @stat_section == 'performance_3d'
      
      # relation = Top50Relation.joins(:top50_relation_type)
      #   .where(sec_obj_id: 511)
      #   .where(top50_relation_types: { name_eng: "Precedes" })
      # puts "=== DEBUG: Precedes relation for machine 511 ==="
      # puts relation.first&.inspect || "not found"
      # puts "==============================================="
      list_date_attr_id = Top50Attribute.where(name_eng: "Edition date").first.id
      date_vals_map = Top50AttributeValDbval.where(attr_id: list_date_attr_id, obj_id: @top50_slists.map(&:id)).index_by(&:obj_id)
      @edition_labels = @top50_slists.map do |list|
        date_val = date_vals_map[list.id]
        date_val ? date_val.value : "??.??.????"
      end
     
      @edition_labels_for_select = @edition_labels.reverse

      @ranks = (1..50).to_a
      @z_data = Array.new(50) { [] }
      @machine_names = Array.new(50) { [] }
    
      rmax_bench = Top50Benchmark.find_by(name_eng: "Linpack")
      all_rmax = Top50BenchmarkResult.where(benchmark_id: rmax_bench.id)
      rmax_by_machine = all_rmax.index_by(&:machine_id)
    
      @top50_slists.each_with_index do |list, idx|
        machines = fetch_archive_list_simple(list.id)
    
        machines_with_rmax = machines.map do |machine|
          rmax = rmax_by_machine[machine.id]
          [machine, rmax&.result.to_f || 0.0001]
        end
    
        top50_sorted = machines_with_rmax.sort_by { |_, rmax| -rmax }.first(50)
    
        rmax_values = top50_sorted.map { |_, rmax| (rmax / 1_000_000.0).round(4) }
        names = top50_sorted.map do |machine, _|
          machine.name.presence || machine.top50_organization&.name || "н/д"
        end
    
        rmax_values.fill(0.0001, rmax_values.size...50)
        names.fill("н/д", names.size...50)
    
        rmax_values.each_with_index { |val, i| @z_data[i] << val }
        names.each_with_index     { |val, i| @machine_names[i] << val }
      end
    
      @z_data = @z_data.transpose
      #@machine_names = @machine_names.reverse
      #@edition_labels = @edition_labels.reverse
      # puts "==============================================="
      # puts "==============================================="
      # puts "==============================================="
      # puts "Z structure: #{@z_data.size} x #{@z_data.first.size}"
      # puts "Names structure: #{@machine_names.size} x #{@machine_names.first.size}"
      # puts "==============================================="
      # puts "==============================================="
      # puts "==============================================="

    elsif @stat_section == 'heatmap_streaks'
      require 'set'
      @top50_slists = get_top50_lists_sorted

      ed_num_attr_id = Top50Attribute.find_by(name_eng: "Edition number")&.id
      @ed_num_attrid = ed_num_attr_id
      ed_num_vals = Top50AttributeValDbval.where(attr_id: ed_num_attr_id, obj_id: @top50_slists.map(&:id)).index_by(&:obj_id)

      list_date_attr_id = Top50Attribute.find_by(name_eng: "Edition date")&.id
      date_vals_map = Top50AttributeValDbval.where(attr_id: list_date_attr_id, obj_id: @top50_slists.map(&:id)).index_by(&:obj_id)

      @top50_slists = @top50_slists.sort_by { |ed| ed_num_vals[ed.id]&.value.to_i || 0 }
      @ed_num_map = @top50_slists.map { |ed| [ed.id, ed_num_vals[ed.id]&.value.to_i] }.to_h

      @x_labels = @top50_slists.map do |list|
        raw_date = date_vals_map[list.id]&.value
        if raw_date && raw_date.match?(/^\d{2}\.\d{2}\.\d{4}$/)
          raw_date.slice(3..-1)
        else
          "??.????"
        end
      end
      

      precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
      @prec_machines = precedes_type_id ? Top50Relation.where(type_id: precedes_type_id, is_valid: [1, 2]) : []
      precedes_map = @prec_machines.pluck(:sec_obj_id, :prim_obj_id).to_h

      def find_root_machine(machine_id, precedes_map)
        while precedes_map[machine_id]
          machine_id = precedes_map[machine_id]
        end
        machine_id
      end

      all_results = Top50BenchmarkResult.where(benchmark_id: @ed_num_map.keys)
      machines_by_edition = Hash.new { |h, k| h[k] = [] }

      all_results.each do |res|
        ed_num = @ed_num_map[res.benchmark_id]
        next unless ed_num
        root_id = find_root_machine(res.machine_id, precedes_map)
        machines_by_edition[ed_num] << { machine_id: res.machine_id, root_id: root_id }
      end

      ed_num_to_index = {}
      ed_num_to_date = {}
      @top50_slists.each_with_index do |ed, idx|
        ed_num = ed_num_vals[ed.id]&.value.to_i
        ed_num_to_index[ed_num] = idx
        ed_date_str = date_vals_map[ed.id]&.value
        ed_num_to_date[ed_num] = Date.parse(ed_date_str) rescue nil
      end

      machine_first_appearance = {}
      current_streaks = Hash.new(0)
      matrix_years = Array.new(@top50_slists.size) { Hash.new(0) }

      @top50_slists.each_with_index do |ed, idx|
        ed_num = ed_num_vals[ed.id]&.value.to_i
        ed_date = ed_num_to_date[ed_num]
        next unless ed_date

        machines = machines_by_edition[ed_num] || []
        seen_roots = Set.new

        machines.group_by { |m| m[:root_id] }.each do |root_id, group|
          seen_roots << root_id

          machine_first_appearance[root_id] ||= ed_date
          start_date = machine_first_appearance[root_id]

          years_in_list = ed_date.year - start_date.year
          years_in_list -= 1 if ed_date.month < start_date.month
          years_in_list = [years_in_list, 0].max

          group.each do |_machine|
            matrix_years[idx][years_in_list] += 1
          end

          current_streaks[root_id] += 1
        end

        current_streaks.keys.each do |root_id|
          current_streaks[root_id] = 0 unless seen_roots.include?(root_id)
        end
      end

      max_years = matrix_years.flat_map(&:keys).max || 0
      @y_labels = (0..max_years).to_a
      @z_data = matrix_years.map { |row| @y_labels.map { |y| row[y] || 0 } }

      # puts "\n===== DEBUG: Z-DATA (Edition Index → Years in List Count) ====="
      # {
      #   first: 0,
      #   second: 1,
      #   last: @x_labels.size - 1
      # }.each do |label, idx|
      #   ed_label = @x_labels[idx]
      #   puts "Edition #{idx} (#{label}, date #{ed_label}): #{@z_data[idx].inspect}"
      # end

      # puts "\n===== DEBUG: Присутствие машин по root_id ====="
      # puts "x_labels.size = #{@x_labels.size}"
      # puts "z_data.size   = #{@z_data.size}"

      # root_to_editions = Hash.new { |h, k| h[k] = Set.new }
      # machines_by_edition.each do |ed_num, machines|
      #   machines.each { |m| root_to_editions[m[:root_id]] << ed_num }
      # end

      # root_to_editions.each do |root_id, editions|
      #   puts "Machine #{root_id}: editions #{editions.to_a.sort.inspect}"
      # end
    
    elsif @stat_section == 'heatmap_rank_vs_years'
      require 'set'
      @top50_slists = get_top50_lists_sorted
    
      ed_num_attr_id = Top50Attribute.find_by(name_eng: "Edition number")&.id
      date_attr_id   = Top50Attribute.find_by(name_eng: "Edition date")&.id
    
      ed_num_vals   = Top50AttributeValDbval.where(attr_id: ed_num_attr_id, obj_id: @top50_slists.map(&:id)).index_by(&:obj_id)
      date_vals_map = Top50AttributeValDbval.where(attr_id: date_attr_id,   obj_id: @top50_slists.map(&:id)).index_by(&:obj_id)
    
      @top50_slists = @top50_slists.sort_by { |ed| ed_num_vals[ed.id]&.value.to_i || 0 }

    
      ed_num_to_date = {}
      @top50_slists.each do |ed|
        ed_num = ed_num_vals[ed.id]&.value.to_i
        ed_date_str = date_vals_map[ed.id]&.value
        ed_num_to_date[ed_num] = Date.parse(ed_date_str) rescue nil
      end
    
      precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
      precedes_map = Top50Relation.where(type_id: precedes_type_id, is_valid: [1, 2]).pluck(:sec_obj_id, :prim_obj_id).to_h
    
      def find_root(machine_id, precedes_map)
        while precedes_map[machine_id]
          machine_id = precedes_map[machine_id]
        end
        machine_id
      end
    
      rmax_bench = Top50Benchmark.find_by(name_eng: "Linpack")
      all_rmax = Top50BenchmarkResult.where(benchmark_id: rmax_bench.id)
      rmax_by_machine = all_rmax.index_by(&:machine_id)
    
      appearances = Hash.new { |h, k| h[k] = [] }
    
      @top50_slists.each do |ed|
        ed_num = ed_num_vals[ed.id]&.value.to_i
        ed_date = ed_num_to_date[ed_num]
        next unless ed_date
    
        machines = fetch_archive_list_simple(ed.id)
    
        sorted_machines = machines.sort_by do |machine|
          -(rmax_by_machine[machine.id]&.result.to_f || 0.0)
        end
    
        sorted_machines.each_with_index do |machine, rank|
          root_id = find_root(machine.id, precedes_map)
          appearances[root_id] << {
            ed_num: ed_num,
            ed_date: ed_date,
            rank: rank + 1,
            machine_id: machine.id,
            name: machine.name.presence || machine.top50_organization&.name || "н/д"
          }
        end
      end
    
      matrix = Hash.new { |h, k| h[k] = Hash.new(0) }
      @series_by_cell = Hash.new { |h, k| h[k] = [] }
    
      appearances.each do |root_id, records|
        records = records.sort_by { |r| r[:ed_num] }
        streaks = []
        current_streak = []
    
        records.each_with_index do |entry, idx|
          if idx == 0 || (entry[:ed_num] - records[idx - 1][:ed_num] <= 1)
            current_streak << entry
          else
            streaks << current_streak
            current_streak = [entry]
          end
        end
        streaks << current_streak unless current_streak.empty?
    
        streaks.each do |streak|
          next if streak.empty?
          start = streak.first
          stop  = streak.last
    
          years = stop[:ed_date].year - start[:ed_date].year
          years -= 1 if stop[:ed_date].month < start[:ed_date].month
          years = [years, 0].max
    
          rank = start[:rank]
          matrix[rank][years] += 1
    
          last_machine_id = stop[:machine_id]
          last_name = stop[:name] || "н/д"
    
          @series_by_cell[[rank, years]] << {
            root_id: root_id,
            rank: rank,
            years: years,
            start: start[:ed_date].to_s,
            end: stop[:ed_date].to_s,
            name: last_name,
            machine_id: last_machine_id
          }
        end
      end
    
      all_ranks = matrix.keys.sort
      all_years = matrix.values.flat_map(&:keys).uniq.sort
    
      @x_labels = all_ranks.map(&:to_s)
      @y_labels = all_years
      @z_data = all_ranks.map { |rank| @y_labels.map { |y| matrix[rank][y] || 0 } }.transpose
    
      @series_by_cell_js = @series_by_cell.transform_keys { |(rank, years)| "#{rank}-#{years}" }
    
    
    elsif @stat_section == 'cpu_vendor_3d'
      list_date_attr_id = Top50Attribute.find_by(name_eng: "Edition date")&.id
      date_vals_map = Top50AttributeValDbval.where(attr_id: list_date_attr_id, obj_id: @top50_slists.map(&:id)).index_by(&:obj_id)

      @edition_labels = @top50_slists.map do |list|
        date_vals_map[list.id]&.value || "??.??.????"
      end

      @edition_labels_for_select = @edition_labels.reverse

      @ranks = (1..50).to_a
      @z_data = Array.new(50) { [] }
      @vendor_data = Array.new(50) { [] }
      @machine_names = Array.new(50) { [] }
      @machine_ids = Array.new(50) { [] }

      cpu_vendor_dict_id = Top50Dictionary.find_by(name_eng: 'CPU Vendor')&.id
      cop_vendor_dict_id = Top50Dictionary.find_by(name_eng: 'Coprocessor Vendor')&.id
      rel_contain_id = Top50RelationType.find_by(name_eng: "Contains")&.id

      vendor_by_machine = Hash.new { |h, k| h[k] = [] }

      @mach_x_cpuvendors = Top50DictionaryElem
        .select("top50_dictionary_elems.id, top50_dictionary_elems.name, top50_machines.id AS mach_id")
        .joins("JOIN top50_attribute_val_dicts ON top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id")
        .joins("JOIN top50_machines ON EXISTS (
                  SELECT 1 FROM top50_relations ar
                  JOIN top50_relations br ON br.prim_obj_id = ar.sec_obj_id
                  WHERE ar.prim_obj_id = top50_machines.id
                  AND br.sec_obj_id = top50_attribute_val_dicts.obj_id
                  AND ar.type_id = #{rel_contain_id}
                  AND br.type_id = #{rel_contain_id}
                )")
        .where("top50_dictionary_elems.dict_id = ?", cpu_vendor_dict_id)

      @mach_x_cpuvendors.each do |rec|
        vendor_by_machine[rec["mach_id"]] << rec["name"]
      end

      @mach_x_copvendors = Top50DictionaryElem
        .select("top50_dictionary_elems.id, top50_dictionary_elems.name, top50_machines.id AS mach_id")
        .joins("JOIN top50_attribute_val_dicts ON top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id")
        .joins("JOIN top50_machines ON EXISTS (
                  SELECT 1 FROM top50_relations ar
                  JOIN top50_relations br ON br.prim_obj_id = ar.sec_obj_id
                  WHERE ar.prim_obj_id = top50_machines.id
                  AND br.sec_obj_id = top50_attribute_val_dicts.obj_id
                  AND ar.type_id = #{rel_contain_id}
                  AND br.type_id = #{rel_contain_id}
                )")
        .where("top50_dictionary_elems.dict_id = ?", cop_vendor_dict_id)

      @mach_x_copvendors.each do |rec|
        if vendor_by_machine[rec["mach_id"]].empty?
          vendor_by_machine[rec["mach_id"]] << rec["name"]
        end
      end

      machine_vendor_map = {}
      vendor_by_machine.each do |mach_id, vendors|
        uniq_vendors = vendors.uniq
        machine_vendor_map[mach_id] = uniq_vendors.size == 1 ? uniq_vendors.first : "Hybrid"
      end

      vendor_indices = {}
      vendor_counter = 0

      rmax_bench = Top50Benchmark.find_by(name_eng: "Linpack")
      all_rmax = Top50BenchmarkResult.where(benchmark_id: rmax_bench.id)
      rmax_by_machine = all_rmax.index_by(&:machine_id)

      @top50_slists.each_with_index do |list, idx|
        machines = fetch_archive_list_simple(list.id)

        machines_with_rmax = machines.map do |machine|
          rmax = rmax_by_machine[machine.id]
          [machine, rmax&.result.to_f || 0.0001]
        end

        top50_sorted = machines_with_rmax.sort_by { |_, rmax| -rmax }.first(50)

        rmax_values = top50_sorted.map { |_, rmax| (rmax / 1_000_000.0).round(4) }
        names = top50_sorted.map { |m, _| m.name.presence || m.top50_organization&.name || "н/д" }

        vendor_values = top50_sorted.map do |machine, _|
          vendor = machine_vendor_map[machine.id] || "Unknown"
          vendor_indices[vendor] ||= vendor_counter
          vendor_counter += 1 if vendor_indices[vendor] == vendor_counter
          vendor_indices[vendor]
        end

        ids = top50_sorted.map { |m, _| m.id }

        rmax_values.fill(0.0001, rmax_values.size...50)
        names.fill("н/д", names.size...50)
        vendor_values.fill(vendor_indices["Unknown"], vendor_values.size...50)
        ids.fill(nil, ids.size...50)

        rmax_values.each_with_index { |val, i| @z_data[i] << val }
        vendor_values.each_with_index { |val, i| @vendor_data[i] << val }
        names.each_with_index       { |val, i| @machine_names[i] << val }
        ids.each_with_index         { |val, i| @machine_ids[i] << val }
      end

      @z_data = @z_data.transpose
      @vendor_data = @vendor_data.transpose
      @machine_names = @machine_names.transpose
      @machine_ids = @machine_ids.transpose
      @vendor_labels = vendor_indices.invert

    
    elsif @stat_section == 'acc_vendor_3d'

      list_date_attr_id = Top50Attribute.find_by(name_eng: "Edition date")&.id
      date_vals_map = Top50AttributeValDbval
                        .where(attr_id: list_date_attr_id, obj_id: @top50_slists.map(&:id))
                        .index_by(&:obj_id)

      @edition_labels = @top50_slists.map do |list|
        date_vals_map[list.id]&.value || "??.??.????"
      end

      @edition_labels_for_select = @edition_labels.reverse

      @ranks = (1..50).to_a
      @z_data = Array.new(50) { [] }
      @vendor_data = Array.new(50) { [] }
      @machine_names = Array.new(50) { [] }
      @machine_ids   = Array.new(50) { [] }

      rel_contain_id = Top50RelationType.find_by(name_eng: "Contains")&.id
      gpu_vendor_dict_id = Top50Dictionary.find_by(name_eng: "GPU Vendor")&.id
      cop_vendor_dict_id = Top50Dictionary.find_by(name_eng: "Coprocessor Vendor")&.id

      if rel_contain_id.nil?
        Rails.logger.warn("Relation type 'Contains' not found")
        @vendor_labels = {}
        return
      end

      gpu_by_machine = Hash.new { |h, k| h[k] = [] }

      if gpu_vendor_dict_id
        Top50DictionaryElem
          .select("top50_dictionary_elems.id, top50_dictionary_elems.name, top50_machines.id AS mach_id")
          .joins("JOIN top50_attribute_val_dicts ON top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id")
          .joins("JOIN top50_machines ON EXISTS (
                    SELECT 1 FROM top50_relations ar
                    JOIN top50_relations br ON br.prim_obj_id = ar.sec_obj_id
                    WHERE ar.prim_obj_id = top50_machines.id
                    AND br.sec_obj_id = top50_attribute_val_dicts.obj_id
                    AND ar.type_id = #{rel_contain_id}
                    AND br.type_id = #{rel_contain_id}
                  )")
          .where("top50_dictionary_elems.dict_id = ?", gpu_vendor_dict_id)
          .each do |rec|
            gpu_by_machine[rec["mach_id"]] << rec["name"]
          end
      end

      if cop_vendor_dict_id
        Top50DictionaryElem
          .select("top50_dictionary_elems.id, top50_dictionary_elems.name, top50_machines.id AS mach_id")
          .joins("JOIN top50_attribute_val_dicts ON top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id")
          .joins("JOIN top50_machines ON EXISTS (
                    SELECT 1 FROM top50_relations ar
                    JOIN top50_relations br ON br.prim_obj_id = ar.sec_obj_id
                    WHERE ar.prim_obj_id = top50_machines.id
                    AND br.sec_obj_id = top50_attribute_val_dicts.obj_id
                    AND ar.type_id = #{rel_contain_id}
                    AND br.type_id = #{rel_contain_id}
                  )")
          .where("top50_dictionary_elems.dict_id = ?", cop_vendor_dict_id)
          .each do |rec|
            gpu_by_machine[rec["mach_id"]] << rec["name"] if gpu_by_machine[rec["mach_id"]].empty?
          end
      end

      machine_vendor_map = {}
      gpu_by_machine.each do |mach_id, vendors|
        uniq_vendors = vendors.uniq
        machine_vendor_map[mach_id] = uniq_vendors.size == 1 ? uniq_vendors.first : "Hybrid"
      end

      vendor_indices = {}
      vendor_counter = 0

      rmax_bench = Top50Benchmark.find_by(name_eng: "Linpack")
      rmax_by_machine = Top50BenchmarkResult
                          .where(benchmark_id: rmax_bench.id)
                          .index_by(&:machine_id)

      @top50_slists.each_with_index do |list, idx|
        machines = fetch_archive_list_simple(list.id)

        machines_with_rmax = machines.map do |machine|
          rmax = rmax_by_machine[machine.id]
          [machine, rmax&.result.to_f || 0.0001]
        end

        top50_sorted = machines_with_rmax.sort_by { |_, rmax| -rmax }.first(50)

        rmax_values = top50_sorted.map { |_, rmax| (rmax / 1_000_000.0).round(4) }
        names = top50_sorted.map { |m, _| m.name.presence || m.top50_organization&.name || "н/д" }
        ids   = top50_sorted.map { |m, _| m.id }

        vendor_values = top50_sorted.map do |machine, _|
          vendor = machine_vendor_map[machine.id] || "Unknown"
          vendor_indices[vendor] ||= vendor_counter
          vendor_counter += 1 if vendor_indices[vendor] == vendor_counter
          vendor_indices[vendor]
        end

        rmax_values.fill(0.0001, rmax_values.size...50)
        vendor_values.fill(vendor_indices["Unknown"], vendor_values.size...50)
        names.fill("н/д", names.size...50)
        ids.fill(nil, ids.size...50)

        rmax_values.each_with_index { |val, i| @z_data[i] << val }
        vendor_values.each_with_index { |val, i| @vendor_data[i] << val }
        names.each_with_index       { |val, i| @machine_names[i] << val }
        ids.each_with_index         { |val, i| @machine_ids[i] << val }
      end

      @z_data = @z_data.transpose
      @vendor_data = @vendor_data.transpose
      @machine_names = @machine_names.transpose
      @machine_ids = @machine_ids.transpose
      @vendor_labels = vendor_indices.invert

    elsif @stat_section == 'performance_3d_with_machine_status'
      precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
      @prec_machines = precedes_type_id ? Top50Relation.where(type_id: precedes_type_id, is_valid: [1, 2]) : []
    
      list_date_attr_id = Top50Attribute.find_by(name_eng: "Edition date")&.id
      date_vals_map = Top50AttributeValDbval
                        .where(attr_id: list_date_attr_id, obj_id: @top50_slists.map(&:id))
                        .index_by(&:obj_id)
    
      @edition_labels = @top50_slists.map do |list|
        date_vals_map[list.id]&.value || "??.??.????"
      end

      @edition_labels_for_select = @edition_labels.reverse
    
      @ranks = (1..50).to_a
      @z_data = Array.new(50) { [] }
      @machine_names = Array.new(50) { [] }
      @machine_status = Array.new(50) { [] }
      @machine_ids = Array.new(50) { [] }
    
      rmax_bench_id = Top50Benchmark.find_by(name_eng: "Linpack")&.id
      all_rmax = Top50BenchmarkResult.where(benchmark_id: rmax_bench_id)
      rmax_by_machine = all_rmax.index_by(&:machine_id)
    
      @debug_machine = nil
    
      @top50_slists.each_with_index do |list, idx|
        machines = fetch_archive_list_simple(list.id)
    
        prev_rated_pos_map = {}
        if idx + 1 < @top50_slists.size
          prev_list = @top50_slists[idx + 1]
          prev_rated_pos = Top50BenchmarkResult.where(benchmark_id: prev_list.id)
          prev_rated_pos_map = prev_rated_pos.index_by(&:machine_id)
        end
    
        machines_with_rmax = machines.map do |machine|
          rmax = rmax_by_machine[machine.id]
          status = :new
    
          prec_rel = @prec_machines.find_by(sec_obj_id: machine.id)
          if prec_rel.present?
            prev_machine_id = prec_rel.prim_obj_id
            if prev_rated_pos_map[prev_machine_id].present?
              status = :upgrade
            elsif prev_rated_pos_map[machine.id].present?
              status = :existing
            end
          elsif prev_rated_pos_map[machine.id].present?
            status = :existing
          end
    
          [machine, rmax&.result.to_f || 0.0001, status]
        end
    
        top50_sorted = machines_with_rmax.sort_by { |_, rmax, _| -rmax }.first(50)
    
        # if @edition_labels[idx] == "31.03.2015" && top50_sorted[4]
        #   m, r, s = top50_sorted[4]
        #   @debug_machine = {
        #     name: m.name,
        #     id: m.id,
        #     rmax: r,
        #     status: s,
        #     date: @edition_labels[idx],
        #     rank: 5
        #   }
        # end
    
        rmax_values = top50_sorted.map { |_, rmax, _| (rmax / 1_000_000.0).round(4) }
        names   = top50_sorted.map { |machine, _, _| machine.name.presence || machine.top50_organization&.name || "н/д" }
        statuses = top50_sorted.map { |_, _, status| status.to_s }
        ids     = top50_sorted.map { |machine, _, _| machine.id }
    
        rmax_values.fill(0.0001, rmax_values.size...50)
        names.fill("н/д", names.size...50)
        statuses.fill("none", statuses.size...50)
        ids.fill(nil, ids.size...50)
    
        rmax_values.each_with_index { |val, i| @z_data[i] << val }
        names.each_with_index       { |val, i| @machine_names[i] << val }
        statuses.each_with_index   { |val, i| @machine_status[i] << val }
        ids.each_with_index        { |val, i| @machine_ids[i] << val }
      end
    
      @z_data = @z_data.transpose
      @machine_names = @machine_names.transpose
      @machine_status = @machine_status.transpose
      @machine_ids = @machine_ids.transpose
    
      # if @debug_machine
      #   puts "== DEBUG MACHINE INFO =="
      #   puts "Date: #{@debug_machine[:date]}"
      #   puts "Rank: #{@debug_machine[:rank]}"
      #   puts "Machine ID: #{@debug_machine[:id]}"
      #   puts "Name: #{@debug_machine[:name]}"
      #   puts "Rmax: #{@debug_machine[:rmax]}"
      #   puts "Status: #{@debug_machine[:status]}"
      # else
      #   puts "DEBUG: @debug_machine is still nil!"
      # end
    #3 END: my code  
    elsif @stat_section.present? and @stat_section[0..6] == 'vendors'
      @vendors_headers = {}
      @vendors_headers["vendors"] = "Количество систем"
      @vendors_headers["vendors_rmax"] = "Суммарная производительность Rmax (ПФлоп/с)"
      @vendors_headers["vendors_rpeak"] = "Суммарная производительность Rpeak (ПФлоп/с)"
      @vendors_headers["vendors_rmax_avg"] = "Средняя производительность Rmax (ПФлоп/с)"
      @vendors_headers["vendors_int"] = "Количество интеграторов"
      @vendors_headers["vendors_cnt_rmax"] = "Количество систем + Rmax (ПФлоп/с)"

      @vendors_header_text = @vendors_headers["vendors"]
      if @vendors_headers.has_key?(@stat_section)
        @vendors_header_text = @vendors_headers[@stat_section]
      end
      
      @top50_vendors = Top50Vendor.all.select("coalesce(v2.id, top50_vendors.id) as id, coalesce(v2.name, top50_vendors.name) as name, count(1) cnt").joins("left join (select prim_obj_id, sec_obj_id from top50_relations join top50_relation_types on top50_relation_types.id = top50_relations.type_id and top50_relation_types.name_eng = 'Precedes') pr_v on top50_vendors.id = pr_v.prim_obj_id").joins("left join top50_vendors v2 on v2.id = pr_v.sec_obj_id").joins("join top50_machines on top50_vendors.id = ANY(top50_machines.vendor_ids)").joins("join top50_benchmark_results on top50_benchmark_results.machine_id = top50_machines.id").joins("join top50_benchmarks on top50_benchmarks.id = top50_benchmark_results.benchmark_id").joins("join top50_relations on top50_benchmarks.id = top50_relations.sec_obj_id").joins("join top50_relation_types on top50_relation_types.id = top50_relations.type_id and top50_relation_types.name_eng = 'Contains'").where("top50_relations.prim_obj_id IN (?)", get_avail_bunches).group("coalesce(v2.id, top50_vendors.id), coalesce(v2.name, top50_vendors.name)").order("cnt desc").having("count(1) > 70")

      prec_relation = Top50Relation.all.joins(:top50_relation_type).merge(Top50RelationType.where(name_eng: "Precedes"))
      @prec_vendors = prec_relation.joins(:top50_object).merge(Top50Object.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "Vendor")))
    elsif  @stat_section == 'type'
      @top50_mtypes = get_avail_mtypes
    elsif (@stat_section_for_loading || @stat_section) == 'freshest_components_lag'
      calc_machine_attrs
      @cpu_model_attrid_lag = Top50Attribute.where(name_eng: "CPU model").first&.id
      @gpu_model_attrid_lag = Top50Attribute.where(name_eng: "GPU model").first&.id
      @cpu_vendor_attrid_lag = Top50Attribute.where(name_eng: "CPU Vendor").first&.id
      @gpu_vendor_attrid_lag = Top50Attribute.where(name_eng: "GPU Vendor").first&.id
      @all_ratings_data = []
      top50_slists = get_top50_lists_sorted
      top_50_dates = []

      # Same tree as /systems/:id: Precedes chain (sec=newer, prim=older). No is_valid filter to match tree_prec_sql.
      precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
      precedes_map = precedes_type_id ? Top50Relation.where(type_id: precedes_type_id).pluck(:sec_obj_id, :prim_obj_id).to_h : {}
      # Root = oldest in chain; same grouping as tree_prec_sql(obj_id) on the systems page
      find_root = ->(mid) { mid.nil? ? nil : (while precedes_map[mid]; mid = precedes_map[mid]; end; mid) }

      # Получаем список дат для каждой редакции
      top50_slists.each do |top50_list|
        list_num = @num_vals.find_by(obj_id: top50_list.id)
        date_val = @date_vals.find_by(obj_id: top50_list.id)
        list_year = date_val.value.split(".")[2]
        list_month = date_val.value.split(".")[1]
        top_50_dates.push([list_year, list_month])
      end

      # Display name: machine name or organization (as on list/archive) — after top_50_dates is populated
      all_list_ids_lag = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
      all_machine_ids_lag = all_list_ids_lag.any? ? Top50BenchmarkResult.where(benchmark_id: all_list_ids_lag).pluck(:machine_id).uniq : []
      machine_display_names_lag = all_machine_ids_lag.any? ? Top50Machine.where(id: all_machine_ids_lag).includes(:top50_organization).each_with_object({}) { |m, h| h[m.id] = m.name.presence || m.top50_organization&.name.presence || "н/д" } : {}
    
      # Для каждой даты собираем данные (minimal structure). Order by list position so rank matches /systems/ and archive.
      top_50_dates.each do |top50_date|
        list_id = get_list_id_by_date(top50_date[0], top50_date[1])
        top50_machines = fetch_archive_list(list_id).order("ed_results.result asc")
        list_date = @date_vals.find_by(obj_id: list_id)&.value
        rating_data = {
          date: top50_date,
          list_date: list_date,
          machines: top50_machines,
          mach_l1_hash: @mach_l1_hash.dup,
          l1_l2_hash: @l1_l2_hash.dup
        }
        @all_ratings_data << rating_data
      end
    
      @cpu_data = []
      @gpu_data = []
      @combined_data = []
      @edition_dates_lag = Array.new(@all_ratings_data.size)
    
      # Заполняем данные для CPU, GPU и комбинированных значений
      @all_ratings_data.each_with_index do |rating_data, reverse_edition_index|
        edition = @all_ratings_data.size - reverse_edition_index
        machines = rating_data[:machines]
        list_date = rating_data[:list_date]
        if list_date.present?
          parts = list_date.split(".")
          @edition_dates_lag[edition - 1] = parts.size >= 3 ? "#{parts[1]}.#{parts[2][-2..-1]}" : list_date
        end
        next unless list_date.present?

        machines.each_with_index do |machine, rank_index|
          newest_cpu_diff = Float::INFINITY
          newest_gpu_diff = Float::INFINITY
          cpu_count = 0
          gpu_count = 0
          freshest_cpu_count = 0
          freshest_gpu_count = 0
          cpu_component_name = nil
          cpu_vendor_name = nil
          cpu_announced_after_mention = nil
          gpu_component_name = nil
          gpu_vendor_name = nil
          gpu_announced_after_mention = nil

          mach_l1_nodes = rating_data[:mach_l1_hash][machine["id"]] || []
          mach_l1_nodes.each do |node|
            cpus = rating_data[:l1_l2_hash][node.id].select { |x| x.type_id == @cpu_typeid }
            gpus = rating_data[:l1_l2_hash][node.id].select { |x| x.type_id == @gpu_typeid }

            cpus.each do |cpu|
              component_info = ComponentInfo.find_by(component_id: cpu.id)
              if component_info&.date_announced && component_info&.date_mentioned
                list_date_parsed = Date.parse(list_date)
                # Lag = d_l - d_a (list date minus announcement date); one metric, no mixing.
                da = component_info.date_announced.to_date
                dm = component_info.date_mentioned.to_date
                diff = (list_date_parsed - da).to_i
                if diff < newest_cpu_diff
                  newest_cpu_diff = diff
                  freshest_cpu_count = cpu.cnt
                  cpu_announced_after_mention = (da > dm)
                  if @cpu_model_attrid_lag.present?
                    avd = Top50AttributeValDict.find_by(obj_id: cpu.id, attr_id: @cpu_model_attrid_lag)
                    cpu_component_name = avd&.top50_dictionary_elem&.name
                  end
                  if @cpu_vendor_attrid_lag.present?
                    avd_v = Top50AttributeValDict.find_by(obj_id: cpu.id, attr_id: @cpu_vendor_attrid_lag)
                    cpu_vendor_name = avd_v&.top50_dictionary_elem&.name
                  end
                elsif diff == newest_cpu_diff
                  freshest_cpu_count += cpu.cnt
                end
                cpu_count += cpu.cnt
              end
            end

            gpus.each do |gpu|
              component_info = ComponentInfo.find_by(component_id: gpu.id)
              if component_info&.date_announced && component_info&.date_mentioned
                list_date_parsed = Date.parse(list_date)
                da = component_info.date_announced.to_date
                dm = component_info.date_mentioned.to_date
                diff = (list_date_parsed - da).to_i
                if diff < newest_gpu_diff
                  newest_gpu_diff = diff
                  freshest_gpu_count = gpu.cnt
                  gpu_announced_after_mention = (da > dm)
                  if @gpu_model_attrid_lag.present?
                    avd = Top50AttributeValDict.find_by(obj_id: gpu.id, attr_id: @gpu_model_attrid_lag)
                    gpu_component_name = avd&.top50_dictionary_elem&.name
                  end
                  if @gpu_vendor_attrid_lag.present?
                    avd_v = Top50AttributeValDict.find_by(obj_id: gpu.id, attr_id: @gpu_vendor_attrid_lag)
                    gpu_vendor_name = avd_v&.top50_dictionary_elem&.name
                  end
                elsif diff == newest_gpu_diff
                  freshest_gpu_count += gpu.cnt
                end
                gpu_count += gpu.cnt
              end
            end
          end

          newest_cpu_diff = nil if newest_cpu_diff == Float::INFINITY
          newest_gpu_diff = nil if newest_gpu_diff == Float::INFINITY
          freshest_cpu_count = nil if newest_cpu_diff.nil?
          freshest_gpu_count = nil if newest_gpu_diff.nil?

          # Combined lag: min(CPU, GPU); component/vendor from the one that defines the min
          combined_diff = if newest_cpu_diff && newest_gpu_diff
                            [newest_cpu_diff, newest_gpu_diff].min
                          elsif newest_cpu_diff
                            newest_cpu_diff
                          elsif newest_gpu_diff
                            newest_gpu_diff
                          end
          freshest_combined_count = if newest_cpu_diff && newest_gpu_diff
                                       newest_cpu_diff <= newest_gpu_diff ? freshest_cpu_count : freshest_gpu_count
                                     elsif newest_cpu_diff
                                       freshest_cpu_count
                                     elsif newest_gpu_diff
                                       freshest_gpu_count
                                     end
          combined_component_name = if newest_cpu_diff && newest_gpu_diff
                                       newest_cpu_diff <= newest_gpu_diff ? cpu_component_name : gpu_component_name
                                     elsif newest_cpu_diff
                                       cpu_component_name
                                     elsif newest_gpu_diff
                                       gpu_component_name
                                     end
          combined_vendor_name = if newest_cpu_diff && newest_gpu_diff
                                    newest_cpu_diff <= newest_gpu_diff ? cpu_vendor_name : gpu_vendor_name
                                  elsif newest_cpu_diff
                                    cpu_vendor_name
                                  elsif newest_gpu_diff
                                    gpu_vendor_name
                                  end
          combined_announced_after_mention = if newest_cpu_diff && newest_gpu_diff
                                                newest_cpu_diff <= newest_gpu_diff ? cpu_announced_after_mention : gpu_announced_after_mention
                                              elsif newest_cpu_diff
                                                cpu_announced_after_mention
                                              elsif newest_gpu_diff
                                                gpu_announced_after_mention
                                              end

          # Pink contour only when announced after mention AND lag < 0 (list date still before announcement)
          show_cpu_contour_lag = cpu_announced_after_mention && newest_cpu_diff.present? && newest_cpu_diff < 0
          show_gpu_contour_lag = gpu_announced_after_mention && newest_gpu_diff.present? && newest_gpu_diff < 0
          show_combined_contour_lag = combined_announced_after_mention && combined_diff.present? && combined_diff < 0

          machine_id = machine["id"]
          machine_name = machine_display_names_lag[machine_id] || "н/д"
          machine_key = find_root.call(machine_id)
          @cpu_data << { edition: edition, rank: rank_index + 1, lag: newest_cpu_diff, freshest_count: freshest_cpu_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: cpu_component_name, vendor_name: cpu_vendor_name, show_before_announce_contour: show_cpu_contour_lag }
          @gpu_data << { edition: edition, rank: rank_index + 1, lag: newest_gpu_diff, freshest_count: freshest_gpu_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: gpu_component_name, vendor_name: gpu_vendor_name, show_before_announce_contour: show_gpu_contour_lag }
          @combined_data << { edition: edition, rank: rank_index + 1, lag: combined_diff, freshest_count: freshest_combined_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: combined_component_name, vendor_name: combined_vendor_name, show_before_announce_contour: show_combined_contour_lag }
        end
      end
    
      # Only pass linear data; scale transforms (log_shifted, bidirectional, sqrt) computed client-side     
    
    elsif @stat_section == 'new_upg' 
      @all_ratings_data = []
      top50_slists = get_top50_lists_sorted
      top_50_dates = []
    
      # Получаем список дат для каждой редакции
      top50_slists.each do |top50_list|
        list_num = @num_vals.find_by(obj_id: top50_list.id)
        date_val = @date_vals.find_by(obj_id: top50_list.id)
        list_year = date_val.value.split(".")[2]
        list_month = date_val.value.split(".")[1]
        top_50_dates.push([list_year, list_month])
      end
    
      # Для каждой даты собираем данные
      top_50_dates.each do |top50_date|
        list_id = get_list_id_by_date(top50_date[0], top50_date[1])
        top50_machines = fetch_archive_list(list_id)
        rating_data = {
          list_id: list_id,
          date: top50_date,
          machines: top50_machines,
          num_vals: @num_vals.dup,
          date_vals: @date_vals.dup,
          prec_machines: @prec_machines.dup,
          ed_num_attrid:@ed_num_attrid.dup,
          ed_date_attrid:@ed_date_attrid.dup, 
          prev_rated_pos:@prev_rated_pos.dup
        }
        @all_ratings_data << rating_data
      end
      @ratings_summary = []

    rmax_by_machine = Top50BenchmarkResult.where(benchmark_id: @rmax_benchid).index_by(&:machine_id)
    rpeak_rows = ActiveRecord::Base.connection.select_all(
      "SELECT obj_id, cast(encode(value, 'escape') as double precision) as num FROM top50_attribute_val_dbvals WHERE attr_id = #{@rpeak_attrid}"
    )
    rpeak_by_machine = rpeak_rows.rows.each_with_object({}) do |row, h|
      val = (row[1] || 0).to_f
      h[row[0].to_i] = val
      h[row[0].to_s] = val
    end

    @all_ratings_data.pop
    @all_ratings_data.each do |rating|
      new_mach = 0
      upg_mach = 0
      sum_rmax_new = 0.0
      sum_rmax_upg = 0.0
      sum_rpeak_new = 0.0
      sum_rpeak_upg = 0.0
      sum_rmax_total = 0.0
      sum_rpeak_total = 0.0

      rating[:machines].each do |top50_machine|
        rank_pos = top50_machine["result"].to_i
        prev_rank_pos = rating[:prev_rated_pos].find { |pos| pos.machine_id == top50_machine["id"] }
        is_upg = false

        # Проверяем предшественника, если текущей машины нет в предыдущем рейтинге
        if prev_rank_pos.nil?
          prec_machine = rating[:prec_machines].find { |prec| prec["sec_obj_id"] == top50_machine["id"] }
          if prec_machine.present?
            prev_rank_pos = rating[:prev_rated_pos].find { |pos| pos.machine_id == prec_machine["prim_obj_id"] }
            is_upg = true if prev_rank_pos.present?
          end
        end

        # Количество новых и обновлённых — как было изначально
        if prev_rank_pos.present?
          if is_upg
            upg_mach += 1
          end
        else
          if prec_machine.present?
            upg_mach += 1
          else
            new_mach += 1
          end
        end

        mid = top50_machine["id"]
        rmax_rec = rmax_by_machine[mid] || (mid.respond_to?(:to_i) ? rmax_by_machine[mid.to_i] : nil)
        rmax_val = (rmax_rec&.result || 0).to_f
        rpeak_val = rpeak_by_machine[mid] || (mid.respond_to?(:to_i) ? rpeak_by_machine[mid.to_i] : nil) || 0.0
        sum_rmax_total += rmax_val
        sum_rpeak_total += rpeak_val
        if prev_rank_pos.present?
          if is_upg
            sum_rmax_upg += rmax_val
            sum_rpeak_upg += rpeak_val
          end
        else
          if prec_machine.present?
            sum_rmax_upg += rmax_val
            sum_rpeak_upg += rpeak_val
          else
            sum_rmax_new += rmax_val
            sum_rpeak_new += rpeak_val
          end
        end
      end
      
      # Сохраняем результат для текущего рейтинга
      @ratings_summary << {
        list_id: rating[:list_id],
        num_vals: rating[:num_vals],
        date_vals: rating[:date_vals],
        date: rating[:date].join('-'),
        new_machines: new_mach,
        upgraded_machines: upg_mach,
        total_machines: new_mach + upg_mach,
        sum_rmax_new: sum_rmax_new,
        sum_rmax_upg: sum_rmax_upg,
        sum_rmax_total: sum_rmax_total,
        sum_rpeak_new: sum_rpeak_new,
        sum_rpeak_upg: sum_rpeak_upg,
        sum_rpeak_total: sum_rpeak_total
      }
    end

    # Формируем данные для графика
    @ratings_chart_data = [
      {
        name: "Новые и обновлённые системы",
        data: @ratings_summary.map { |rating| [rating[:date], rating[:total_machines]] },
        color: "#0000FF"
      },
      {
        name: "Новые системы",
        data: @ratings_summary.map { |rating| [rating[:date], rating[:new_machines]] },
        color: "#2ca02c"
      },
      {
        name: "Обновлённые системы",
        data: @ratings_summary.map { |rating| [rating[:date], rating[:upgraded_machines]] },
        color: "#ff7f0e"
      }
    ]

    # Данные для графиков процентов Rpeak и Rmax (имена серий должны совпадать с draw_new_vs_upgraded_new)
    @ratings_rpeak_pct_chart_data = [
      {
        name: "Новые и обновлённые системы",
        data: @ratings_summary.map { |r|
          st = r[:sum_rpeak_total].to_f
          val = st > 0 ? ((r[:sum_rpeak_new].to_f + r[:sum_rpeak_upg].to_f) / st * 100).round(2) : 0
          [r[:date], val]
        },
        color: "#0000FF"
      },
      {
        name: "Новые системы",
        data: @ratings_summary.map { |r|
          st = r[:sum_rpeak_total].to_f
          val = st > 0 ? (r[:sum_rpeak_new].to_f / st * 100).round(2) : 0
          [r[:date], val]
        },
        color: "#2ca02c"
      },
      {
        name: "Обновлённые системы",
        data: @ratings_summary.map { |r|
          st = r[:sum_rpeak_total].to_f
          val = st > 0 ? (r[:sum_rpeak_upg].to_f / st * 100).round(2) : 0
          [r[:date], val]
        },
        color: "#ff7f0e"
      }
    ]
    @ratings_rmax_pct_chart_data = [
      {
        name: "Новые и обновлённые системы",
        data: @ratings_summary.map { |r|
          st = r[:sum_rmax_total].to_f
          val = st > 0 ? ((r[:sum_rmax_new].to_f + r[:sum_rmax_upg].to_f) / st * 100).round(2) : 0
          [r[:date], val]
        },
        color: "#0000FF"
      },
      {
        name: "Новые системы",
        data: @ratings_summary.map { |r|
          st = r[:sum_rmax_total].to_f
          val = st > 0 ? (r[:sum_rmax_new].to_f / st * 100).round(2) : 0
          [r[:date], val]
        },
        color: "#2ca02c"
      },
      {
        name: "Обновлённые системы",
        data: @ratings_summary.map { |r|
          st = r[:sum_rmax_total].to_f
          val = st > 0 ? (r[:sum_rmax_upg].to_f / st * 100).round(2) : 0
          [r[:date], val]
        },
        color: "#ff7f0e"
      }
    ]      
    elsif @stat_section == 'ram_stats'
      @ram_per_core_data = []
      @ram_per_cpu_data = []
      @ram_per_node_data = []
      
      # Initialize attribute IDs
      calc_machine_attrs
      @ram_size_attrid = Top50Attribute.where(name_eng: "RAM size (GB)").first&.id
      @core_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first&.id
      @cpu_qty_attrid_ram = Top50Attribute.where(name_eng: "Number of CPUs").first&.id
      @cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first&.id
      @gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first&.id
      @rel_contain_id = get_rel_contain_id

      top50_slists = get_top50_lists_sorted
      top_50_dates = []
      top50_slists.each do |top50_list|
        date_val = @date_vals.find_by(obj_id: top50_list.id)
        next unless date_val.present?
        list_year = date_val.value.split(".")[2]
        list_month = date_val.value.split(".")[1]
        top_50_dates.push([list_year, list_month])
      end

      # Same tree as /systems/:id for hover highlight
      precedes_type_id_ram = Top50RelationType.find_by(name_eng: "Precedes")&.id
      precedes_map_ram = precedes_type_id_ram ? Top50Relation.where(type_id: precedes_type_id_ram).pluck(:sec_obj_id, :prim_obj_id).to_h : {}
      find_root_ram = ->(mid) { mid.nil? ? nil : (while precedes_map_ram[mid]; mid = precedes_map_ram[mid]; end; mid) }
      all_list_ids_ram = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
      all_machine_ids_ram = all_list_ids_ram.any? ? Top50BenchmarkResult.where(benchmark_id: all_list_ids_ram).pluck(:machine_id).uniq : []
      machine_names_ram = all_machine_ids_ram.any? ? Top50Machine.where(id: all_machine_ids_ram).includes(:top50_organization).each_with_object({}) { |m, h| h[m.id] = m.name.presence || m.top50_organization&.name.presence || "н/д" } : {}

      @edition_dates_ram = Array.new(top_50_dates.size)
      top_50_dates.each_with_index do |top50_date, reverse_edition_index|
        list_id = get_list_id_by_date(top50_date[0], top50_date[1])
        list_date = @date_vals.find_by(obj_id: list_id)&.value
        edition = top_50_dates.size - reverse_edition_index
        if list_date.present?
          parts = list_date.split(".")
          @edition_dates_ram[edition - 1] = parts.size >= 3 ? "#{parts[1]}.#{parts[2][-2..-1]}" : list_date
        end
        # Get machines directly from the benchmark results for this specific list
        benchmark_results = Top50BenchmarkResult.where(benchmark_id: list_id).order(result: :asc).limit(50)

        benchmark_results.each_with_index do |benchmark_result, rank_index|
          rank = rank_index + 1
          machine_id = benchmark_result.machine_id
          total_ram = 0.0
          total_cores = 0
          total_cpus = 0
          total_nodes = 0
          has_gpu = false

          # Get nodes directly from database for this specific machine
          node_rels = Top50Relation.where(prim_obj_id: machine_id, type_id: @rel_contain_id)
          
          node_rels.each do |node_rel|
            node_id = node_rel.sec_obj_id
            node_qty = node_rel.sec_obj_qty
            total_nodes += node_qty
            
            # Get RAM directly from database for this specific node
            ram_val = Top50AttributeValDbval.find_by(obj_id: node_id, attr_id: @ram_size_attrid)
            if ram_val && ram_val.value.present?
              ram_per_node = ram_val.value.to_f
              if ram_per_node > 0
                total_ram += node_qty * ram_per_node
              end
            end
            
            # Get CPUs and GPUs directly from database for this specific node
            cpu_rels = Top50Relation.where(prim_obj_id: node_id, type_id: @rel_contain_id)
            cpu_rels.each do |cpu_rel|
              cpu_id = cpu_rel.sec_obj_id
              cpu_obj = Top50Object.find_by(id: cpu_id)
              
              if cpu_obj && cpu_obj.type_id == @cpu_typeid
                cpu_qty = cpu_rel.sec_obj_qty * node_qty
                total_cpus += cpu_qty
                
                # Get cores directly from database for this specific CPU
                cores_val = Top50AttributeValDbval.find_by(obj_id: cpu_id, attr_id: @core_qty_attrid)
                if cores_val && cores_val.value.present?
                  cores_per_cpu = cores_val.value.to_i
                  total_cores += cpu_qty * cores_per_cpu if cores_per_cpu > 0
                end
              elsif cpu_obj && cpu_obj.type_id == @gpu_typeid
                has_gpu = true
              end
            end
          end

          # Fallback to machine-level attributes when nodes do not contain info (like archive/show)
          if total_ram == 0 && @ram_size_attrid.present?
            ram_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @ram_size_attrid)
            total_ram = ram_val.value.to_f if ram_val.present? && ram_val.value.present?
          end
          if total_cpus == 0 && @cpu_qty_attrid_ram.present?
            cpu_qty_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @cpu_qty_attrid_ram)
            total_cpus = cpu_qty_val.value.to_i if cpu_qty_val.present?
          end
          if total_cores == 0 && @core_qty_attrid.present?
            core_qty_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @core_qty_attrid)
            total_cores = core_qty_val.value.to_i if core_qty_val.present?
          end

          # Calculate averages - return nil only if denominator is 0 or no valid data exists
          ram_per_core = (total_cores > 0 && total_ram > 0) ? (total_ram / total_cores) : nil
          ram_per_cpu = (total_cpus > 0 && total_ram > 0) ? (total_ram / total_cpus) : nil
          ram_per_node_val = (total_nodes > 0 && total_ram > 0) ? (total_ram / total_nodes) : nil

          machine_name_ram = machine_names_ram[machine_id] || "н/д"
          machine_key_ram = find_root_ram.call(machine_id)
          @ram_per_core_data << { edition: edition, rank: rank, lag: ram_per_core, has_gpu: has_gpu, machine_id: machine_id, machine_name: machine_name_ram, machine_key: machine_key_ram }
          @ram_per_cpu_data << { edition: edition, rank: rank, lag: ram_per_cpu, has_gpu: has_gpu, machine_id: machine_id, machine_name: machine_name_ram, machine_key: machine_key_ram }
          @ram_per_node_data << { edition: edition, rank: rank, lag: ram_per_node_val, has_gpu: has_gpu, machine_id: machine_id, machine_name: machine_name_ram, machine_key: machine_key_ram }
        end
      end

    elsif @stat_section == 'component_stats'
      @cpu_total_data = []
      @cpu_per_node_data = []
      @gpu_total_data = []
      @gpu_per_node_data = []
      @freshest_total_data = []
      @freshest_per_node_data = []
      @freshest_total_data_cpu_only = []
      @freshest_per_node_data_cpu_only = []
      @cores_total_data = []
      @cores_per_node_data = []
      @gpu_cores_total_data = []
      @gpu_cores_per_node_data = []
      @gpu_microcores_only_total_data = []
      @gpu_microcores_only_per_node_data = []
      
      # Initialize attribute IDs
      calc_machine_attrs
      @cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first&.id
      @gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first&.id
      @core_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first&.id
      @microcore_qty_attrid = Top50Attribute.where(name_eng: "Number of micro cores").first&.id
      @cpu_qty_attrid_comp = Top50Attribute.where(name_eng: "Number of CPUs").first&.id
      @gpu_qty_attrid_comp = Top50Attribute.where(name_eng: "Number of GPUs").first&.id
      @rel_contain_id = get_rel_contain_id

      top50_slists = get_top50_lists_sorted
      top_50_dates = []
      top50_slists.each do |top50_list|
        date_val = @date_vals.find_by(obj_id: top50_list.id)
        next unless date_val.present?
        list_year = date_val.value.split(".")[2]
        list_month = date_val.value.split(".")[1]
        top_50_dates.push([list_year, list_month])
      end

      # Same tree as /systems/:id for hover highlight
      precedes_type_id_comp = Top50RelationType.find_by(name_eng: "Precedes")&.id
      precedes_map_comp = precedes_type_id_comp ? Top50Relation.where(type_id: precedes_type_id_comp).pluck(:sec_obj_id, :prim_obj_id).to_h : {}
      find_root_comp = ->(mid) { mid.nil? ? nil : (while precedes_map_comp[mid]; mid = precedes_map_comp[mid]; end; mid) }
      all_list_ids_comp = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
      machine_names_comp = all_list_ids_comp.any? ? Top50Machine.where(id: Top50BenchmarkResult.where(benchmark_id: all_list_ids_comp).pluck(:machine_id).uniq).pluck(:id, :name).to_h : {}

      @edition_dates_component = Array.new(top_50_dates.size)
      top_50_dates.each_with_index do |top50_date, reverse_edition_index|
        list_id = get_list_id_by_date(top50_date[0], top50_date[1])
        list_date = @date_vals.find_by(obj_id: list_id)&.value
        edition = top_50_dates.size - reverse_edition_index
        if list_date.present?
          parts = list_date.split(".")
          @edition_dates_component[edition - 1] = parts.size >= 3 ? "#{parts[1]}.#{parts[2][-2..-1]}" : list_date
        end
        
        benchmark_results = Top50BenchmarkResult.where(benchmark_id: list_id).order(result: :asc).limit(50)

        benchmark_results.each_with_index do |benchmark_result, rank_index|
          rank = rank_index + 1
          machine_id = benchmark_result.machine_id
          total_cpus = 0
          total_gpus = 0
          total_cores = 0
          total_gpu_cores = 0
          total_gpu_microcores_only = 0
          total_nodes = 0
          min_lag = Float::INFINITY
          freshest_count = 0
          min_lag_cpu_only = Float::INFINITY
          freshest_cpu_only_count = 0

          # Get nodes directly from database for this specific machine
          node_rels = Top50Relation.where(prim_obj_id: machine_id, type_id: @rel_contain_id)
          
          node_rels.each do |node_rel|
            node_id = node_rel.sec_obj_id
            node_qty = node_rel.sec_obj_qty
            total_nodes += node_qty
            
            # Get components directly from database for this specific node
            component_rels = Top50Relation.where(prim_obj_id: node_id, type_id: @rel_contain_id)
            component_rels.each do |component_rel|
              component_id = component_rel.sec_obj_id
              component_obj = Top50Object.find_by(id: component_id)
              next unless component_obj
              
              component_qty = component_rel.sec_obj_qty * node_qty
              
              if component_obj.type_id == @cpu_typeid
                total_cpus += component_qty
                
                # Get cores directly from database for this specific CPU
                cores_val = Top50AttributeValDbval.find_by(obj_id: component_id, attr_id: @core_qty_attrid)
                if cores_val && cores_val.value.present?
                  cores_per_cpu = cores_val.value.to_i
                  total_cores += component_qty * cores_per_cpu if cores_per_cpu > 0
                end
                
                # Check for freshest components (CPU+GPU combined)
                component_info = ComponentInfo.find_by(component_id: component_id)
                if component_info&.date_announced && component_info&.date_mentioned && list_date.present?
                  used_date = component_info.date_mentioned < component_info.date_announced ? 
                              component_info.date_mentioned : 
                              component_info.date_announced
                  diff = (Date.parse(list_date) - used_date).to_i
                  if diff < min_lag
                    min_lag = diff
                    freshest_count = component_qty
                  elsif diff == min_lag
                    freshest_count += component_qty
                  end
                  # CPU-only freshest
                  if diff < min_lag_cpu_only
                    min_lag_cpu_only = diff
                    freshest_cpu_only_count = component_qty
                  elsif diff == min_lag_cpu_only
                    freshest_cpu_only_count += component_qty
                  end
                end
              elsif component_obj.type_id == @gpu_typeid
                total_gpus += component_qty
                # GPU cores (Number of cores = мультипроцессорные блоки / CUDA blocks)
                if @core_qty_attrid.present?
                  cores_val = Top50AttributeValDbval.find_by(obj_id: component_id, attr_id: @core_qty_attrid)
                  if cores_val&.value.present?
                    c = cores_val.value.to_i
                    total_gpu_cores += component_qty * c if c > 0
                  end
                end
                # GPU microcores (Number of micro cores = CUDA-ядра)
                if @microcore_qty_attrid.present?
                  microcores_val = Top50AttributeValDbval.find_by(obj_id: component_id, attr_id: @microcore_qty_attrid)
                  if microcores_val&.value.present?
                    mc = microcores_val.value.to_i
                    total_gpu_microcores_only += component_qty * mc if mc > 0
                  end
                end

                # Check for freshest components (CPU+GPU combined only)
                component_info = ComponentInfo.find_by(component_id: component_id)
                if component_info&.date_announced && component_info&.date_mentioned && list_date.present?
                  used_date = component_info.date_mentioned < component_info.date_announced ? 
                              component_info.date_mentioned : 
                              component_info.date_announced
                  diff = (Date.parse(list_date) - used_date).to_i
                  if diff < min_lag
                    min_lag = diff
                    freshest_count = component_qty
                  elsif diff == min_lag
                    freshest_count += component_qty
                  end
                end
              end
            end
          end

          # Fallback to machine-level attributes when nodes do not contain component info (like archive/show)
          if total_cpus == 0 && @cpu_qty_attrid_comp.present?
            cpu_qty_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @cpu_qty_attrid_comp)
            total_cpus = cpu_qty_val.value.to_i if cpu_qty_val.present?
          end
          if total_gpus == 0 && @gpu_qty_attrid_comp.present?
            gpu_qty_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @gpu_qty_attrid_comp)
            total_gpus = gpu_qty_val.value.to_i if gpu_qty_val.present?
          end
          if total_cores == 0 && @core_qty_attrid.present?
            core_qty_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @core_qty_attrid)
            total_cores = core_qty_val.value.to_i if core_qty_val.present?
          end

          # Calculate per-node averages
          cpu_per_node = (total_nodes > 0 && total_cpus > 0) ? (total_cpus.to_f / total_nodes) : nil
          gpu_per_node = (total_nodes > 0 && total_gpus > 0) ? (total_gpus.to_f / total_nodes) : nil
          cores_per_node = (total_nodes > 0 && total_cores > 0) ? (total_cores.to_f / total_nodes) : nil
          gpu_cores_per_node = (total_nodes > 0 && total_gpu_cores > 0) ? (total_gpu_cores.to_f / total_nodes) : nil
          gpu_microcores_only_per_node = (total_nodes > 0 && total_gpu_microcores_only > 0) ? (total_gpu_microcores_only.to_f / total_nodes) : nil
          freshest_per_node = (total_nodes > 0 && min_lag != Float::INFINITY && freshest_count > 0) ? (freshest_count.to_f / total_nodes) : nil
          freshest_per_node_cpu_only = (total_nodes > 0 && min_lag_cpu_only != Float::INFINITY && freshest_cpu_only_count > 0) ? (freshest_cpu_only_count.to_f / total_nodes) : nil
          
          freshest_total = (min_lag != Float::INFINITY && freshest_count > 0) ? freshest_count : nil
          freshest_total_cpu_only = (min_lag_cpu_only != Float::INFINITY && freshest_cpu_only_count > 0) ? freshest_cpu_only_count : nil

          machine_name_comp = machine_names_comp[machine_id] || "н/д"
          machine_key_comp = find_root_comp.call(machine_id)
          mk = { machine_id: machine_id, machine_name: machine_name_comp, machine_key: machine_key_comp }
          @cpu_total_data << { edition: edition, rank: rank, lag: (total_cpus > 0 ? total_cpus : nil) }.merge(mk)
          @cpu_per_node_data << { edition: edition, rank: rank, lag: cpu_per_node }.merge(mk)
          @gpu_total_data << { edition: edition, rank: rank, lag: (total_gpus > 0 ? total_gpus : nil) }.merge(mk)
          @gpu_per_node_data << { edition: edition, rank: rank, lag: gpu_per_node }.merge(mk)
          @cores_total_data << { edition: edition, rank: rank, lag: (total_cores > 0 ? total_cores : nil) }.merge(mk)
          @cores_per_node_data << { edition: edition, rank: rank, lag: cores_per_node }.merge(mk)
          @gpu_cores_total_data << { edition: edition, rank: rank, lag: (total_gpu_cores > 0 ? total_gpu_cores : nil) }.merge(mk)
          @gpu_cores_per_node_data << { edition: edition, rank: rank, lag: gpu_cores_per_node }.merge(mk)
          @gpu_microcores_only_total_data << { edition: edition, rank: rank, lag: (total_gpu_microcores_only > 0 ? total_gpu_microcores_only : nil) }.merge(mk)
          @gpu_microcores_only_per_node_data << { edition: edition, rank: rank, lag: gpu_microcores_only_per_node }.merge(mk)
          @freshest_total_data << { edition: edition, rank: rank, lag: freshest_total }.merge(mk)
          @freshest_per_node_data << { edition: edition, rank: rank, lag: freshest_per_node }.merge(mk)
          @freshest_total_data_cpu_only << { edition: edition, rank: rank, lag: freshest_total_cpu_only }.merge(mk)
          @freshest_per_node_data_cpu_only << { edition: edition, rank: rank, lag: freshest_per_node_cpu_only }.merge(mk)
        end
      end

    elsif @stat_section == 'freshest_comp_stats'
      @freshest_cpu_quantity_data = []
      @freshest_gpu_quantity_data = []
      @announce_to_mention_cpu_data = []
      @announce_to_mention_gpu_data = []
      @freshest_quantity_chart_dates = {}
      @freshest_cpu_model_ids_by_edition = Hash.new { |h, k| h[k] = Set.new }
      @freshest_gpu_model_ids_by_edition = Hash.new { |h, k| h[k] = Set.new }

      calc_machine_attrs
      @rpeak_attrid = Top50Attribute.where(name_eng: "Rpeak (MFlop/s)").first&.id
      @rmax_benchid = Top50Benchmark.where(name_eng: "Linpack").first&.id
      @cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first&.id
      @gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first&.id
      @rel_contain_id = get_rel_contain_id
      # Machine-level quantity attributes (used when node/component relations give 0, like archive/show)
      @cpu_qty_attrid = Top50Attribute.where(name_eng: "Number of CPUs").first&.id
      @gpu_qty_attrid = Top50Attribute.where(name_eng: "Number of GPUs").first&.id
      @cpu_model_attrid_fq = Top50Attribute.where(name_eng: "CPU model").first&.id
      @gpu_model_attrid_fq = Top50Attribute.where(name_eng: "GPU model").first&.id
      @cpu_vendor_attrid_fq = Top50Attribute.where(name_eng: "CPU Vendor").first&.id
      @gpu_vendor_attrid_fq = Top50Attribute.where(name_eng: "GPU Vendor").first&.id

      top50_slists = get_top50_lists_sorted
      top_50_dates = []
      top50_slists.each do |top50_list|
        date_val = @date_vals.find_by(obj_id: top50_list.id)
        next unless date_val.present?
        list_year = date_val.value.split(".")[2]
        list_month = date_val.value.split(".")[1]
        top_50_dates.push([list_year, list_month])
      end

      # Same tree as /systems/:id for hover highlight
      precedes_type_id_fq = Top50RelationType.find_by(name_eng: "Precedes")&.id
      precedes_map_fq = precedes_type_id_fq ? Top50Relation.where(type_id: precedes_type_id_fq).pluck(:sec_obj_id, :prim_obj_id).to_h : {}
      find_root_fq = ->(mid) { mid.nil? ? nil : (while precedes_map_fq[mid]; mid = precedes_map_fq[mid]; end; mid) }
      all_list_ids_fq = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
      all_machine_ids_fq = all_list_ids_fq.any? ? Top50BenchmarkResult.where(benchmark_id: all_list_ids_fq).pluck(:machine_id).uniq : []
      machine_names_fq = all_machine_ids_fq.any? ? Top50Machine.where(id: all_machine_ids_fq).includes(:top50_organization).each_with_object({}) { |m, h| h[m.id] = m.name.presence || m.top50_organization&.name.presence || "н/д" } : {}

      @edition_dates_freshest_quantity = Array.new(top_50_dates.size)
      top_50_dates.each_with_index do |top50_date, reverse_edition_index|
        list_year, list_month = top50_date[0], top50_date[1]
        list_id = get_list_id_by_date(list_year, list_month)
        list_date = @date_vals.find_by(obj_id: list_id)&.value
        edition = top_50_dates.size - reverse_edition_index
        if list_date.present?
          parts = list_date.split(".")
          @edition_dates_freshest_quantity[edition - 1] = parts.size >= 3 ? "#{parts[1]}.#{parts[2][-2..-1]}" : list_date
        end

        list_date_parsed = nil
        if list_date.present?
          begin
            list_date_parsed = Date.strptime(list_date, "%d.%m.%Y")
          rescue ArgumentError
            list_date_parsed = nil
          end
        end

        next unless list_date_parsed

        @freshest_quantity_chart_dates[edition] = list_date_parsed.strftime("%Y-%m")
        benchmark_results = Top50BenchmarkResult.where(benchmark_id: list_id).order(result: :asc).limit(50)
        benchmark_results.each_with_index do |benchmark_result, rank_index|
          rank = rank_index + 1
          machine_id = benchmark_result.machine_id
          freshest_cpu_count = 0
          freshest_gpu_count = 0
          total_cpu_count = 0
          total_gpu_count = 0
          min_cpu_announce_to_mention_days = nil
          min_gpu_announce_to_mention_days = nil
          cpu_contour_date_announced = nil
          gpu_contour_date_announced = nil
          cpu_component_name = nil
          gpu_component_name = nil
          cpu_vendor_name = nil
          gpu_vendor_name = nil
          cpu_new_component_name = nil
          gpu_new_component_name = nil
          cpu_new_vendor_name = nil
          gpu_new_vendor_name = nil

          node_rels = Top50Relation.where(prim_obj_id: machine_id, type_id: @rel_contain_id)
          node_rels.each do |node_rel|
            node_id = node_rel.sec_obj_id
            node_qty = node_rel.sec_obj_qty

            component_rels = Top50Relation.where(prim_obj_id: node_id, type_id: @rel_contain_id)
            component_rels.each do |component_rel|
              component_id = component_rel.sec_obj_id
              component_obj = Top50Object.find_by(id: component_id)
              next unless component_obj

              component_qty = component_rel.sec_obj_qty * node_qty
              if component_obj.type_id == @cpu_typeid
                total_cpu_count += component_qty
              elsif component_obj.type_id == @gpu_typeid
                total_gpu_count += component_qty
              end

              ci = ComponentInfo.find_by(component_id: component_id)
              next unless ci

              comp_model_name = nil
              comp_vendor_name = nil
              if component_obj.type_id == @cpu_typeid && @cpu_model_attrid_fq.present?
                avd = Top50AttributeValDict.find_by(obj_id: component_id, attr_id: @cpu_model_attrid_fq)
                comp_model_name = avd&.top50_dictionary_elem&.name
                if @cpu_vendor_attrid_fq.present?
                  avd_v = Top50AttributeValDict.find_by(obj_id: component_id, attr_id: @cpu_vendor_attrid_fq)
                  comp_vendor_name = avd_v&.top50_dictionary_elem&.name
                end
              elsif component_obj.type_id == @gpu_typeid && @gpu_model_attrid_fq.present?
                avd = Top50AttributeValDict.find_by(obj_id: component_id, attr_id: @gpu_model_attrid_fq)
                comp_model_name = avd&.top50_dictionary_elem&.name
                if @gpu_vendor_attrid_fq.present?
                  avd_v = Top50AttributeValDict.find_by(obj_id: component_id, attr_id: @gpu_vendor_attrid_fq)
                  comp_vendor_name = avd_v&.top50_dictionary_elem&.name
                end
              end

              dm = ci.date_mentioned
              da = ci.date_announced
              dm_date = dm.respond_to?(:to_date) ? dm.to_date : (dm.is_a?(Date) ? dm : nil)
              da_date = da.respond_to?(:to_date) ? da.to_date : (da.is_a?(Date) ? da : nil)

              # Difference (date_mentioned - date_announced) in days for announce-to-mention heatmaps
              if dm_date.present? && da_date.present?
                diff_days = (dm_date - da_date).to_i
                if component_obj.type_id == @cpu_typeid
                  if min_cpu_announce_to_mention_days.nil? || diff_days < min_cpu_announce_to_mention_days
                    min_cpu_announce_to_mention_days = diff_days
                    cpu_contour_date_announced = da_date if diff_days < 0
                    cpu_component_name = comp_model_name.presence
                    cpu_vendor_name = comp_vendor_name.presence
                  end
                elsif component_obj.type_id == @gpu_typeid
                  if min_gpu_announce_to_mention_days.nil? || diff_days < min_gpu_announce_to_mention_days
                    min_gpu_announce_to_mention_days = diff_days
                    gpu_contour_date_announced = da_date if diff_days < 0
                    gpu_component_name = comp_model_name.presence
                    gpu_vendor_name = comp_vendor_name.presence
                  end
                end
              end

              is_freshest = (dm_date.present? && dm_date == list_date_parsed) ||
                            (da_date.present? && da_date >= list_date_parsed)

              if is_freshest
                if component_obj.type_id == @cpu_typeid
                  freshest_cpu_count += component_qty
                  @freshest_cpu_model_ids_by_edition[edition].add(component_id)
                  cpu_new_component_name ||= comp_model_name.presence
                  cpu_new_vendor_name ||= comp_vendor_name.presence
                elsif component_obj.type_id == @gpu_typeid
                  freshest_gpu_count += component_qty
                  @freshest_gpu_model_ids_by_edition[edition].add(component_id)
                  gpu_new_component_name ||= comp_model_name.presence
                  gpu_new_vendor_name ||= comp_vendor_name.presence
                end
              end
            end
          end

          # Fallback to machine-level quantity attributes when nodes do not contain component info (like archive/show)
          if total_cpu_count == 0 && @cpu_qty_attrid.present?
            cpu_qty_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @cpu_qty_attrid)
            total_cpu_count = cpu_qty_val.value.to_i if cpu_qty_val.present?
          end
          if total_gpu_count == 0 && @gpu_qty_attrid.present?
            gpu_qty_val = Top50AttributeValDbval.find_by(obj_id: machine_id, attr_id: @gpu_qty_attrid)
            total_gpu_count = gpu_qty_val.value.to_i if gpu_qty_val.present?
          end

          machine_name_fq = machine_names_fq[machine_id] || "н/д"
          machine_key_fq = find_root_fq.call(machine_id)
          @freshest_cpu_quantity_data << { edition: edition, rank: rank, lag: (freshest_cpu_count > 0 ? freshest_cpu_count : nil), total_cpu: total_cpu_count, total_gpu: total_gpu_count, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, component_name: cpu_new_component_name, vendor_name: cpu_new_vendor_name }
          @freshest_gpu_quantity_data << { edition: edition, rank: rank, lag: (freshest_gpu_count > 0 ? freshest_gpu_count : nil), total_cpu: total_cpu_count, total_gpu: total_gpu_count, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, component_name: gpu_new_component_name, vendor_name: gpu_new_vendor_name }
          # Announce-to-mention diff heatmaps (lag-style: days from date_announced to date_mentioned)
          # Pink contour only when list date is before announcement (mentioned-before-announced case)
          show_cpu_contour = min_cpu_announce_to_mention_days.present? && min_cpu_announce_to_mention_days < 0 && cpu_contour_date_announced.present? && list_date_parsed < cpu_contour_date_announced
          show_gpu_contour = min_gpu_announce_to_mention_days.present? && min_gpu_announce_to_mention_days < 0 && gpu_contour_date_announced.present? && list_date_parsed < gpu_contour_date_announced
          @announce_to_mention_cpu_data << { edition: edition, rank: rank, lag: min_cpu_announce_to_mention_days, freshest_count: 1, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, is_new: (freshest_cpu_count > 0), show_before_announce_contour: show_cpu_contour, component_name: cpu_component_name, vendor_name: cpu_vendor_name }
          @announce_to_mention_gpu_data << { edition: edition, rank: rank, lag: min_gpu_announce_to_mention_days, freshest_count: 1, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, is_new: (freshest_gpu_count > 0), show_before_announce_contour: show_gpu_contour, component_name: gpu_component_name, vendor_name: gpu_vendor_name }
        end
      end

      # Summary per edition: systems with new CPU, new GPU, and union (CPU or GPU, no double count).
      # 1) systems with new CPU  2) systems with new GPU  3) intersection = both
      # Display: 1), 2), and union = 1) + 2) - 3).
      # Exclude the first list from the chart — in the first list all components appear "new"
      chart_editions = @freshest_quantity_chart_dates.keys.sort.drop(1)
      cpu_by_edition = @freshest_cpu_quantity_data.group_by { |h| h[:edition] }
      gpu_by_edition = @freshest_gpu_quantity_data.group_by { |h| h[:edition] }
      @freshest_quantity_summary = chart_editions.map do |ed|
        cpu_entries = cpu_by_edition[ed] || []
        gpu_entries = gpu_by_edition[ed] || []
        ranks_fresh_cpu = cpu_entries.select { |h| h[:lag].to_i > 0 }.map { |h| h[:rank] }.uniq
        ranks_fresh_gpu = gpu_entries.select { |h| h[:lag].to_i > 0 }.map { |h| h[:rank] }.uniq
        systems_fresh_cpu = ranks_fresh_cpu.size
        systems_fresh_gpu = ranks_fresh_gpu.size
        ranks_fresh_both = ranks_fresh_cpu & ranks_fresh_gpu
        systems_fresh_intersection = ranks_fresh_both.size
        systems_fresh_union = systems_fresh_cpu + systems_fresh_gpu - systems_fresh_intersection
        {
          edition: ed,
          date_label: @freshest_quantity_chart_dates[ed],
          systems_fresh_cpu: systems_fresh_cpu,
          systems_fresh_gpu: systems_fresh_gpu,
          systems_fresh_union: systems_fresh_union
        }
      end
      @freshest_quantity_chart_data = [
        { name: "С новыми CPU", data: @freshest_quantity_summary.map { |s| [s[:date_label], s[:systems_fresh_cpu]] }, color: "#2ca02c" },
        { name: "С новыми GPU", data: @freshest_quantity_summary.map { |s| [s[:date_label], s[:systems_fresh_gpu]] }, color: "#ff7f0e" },
        { name: "С новыми CPU или GPU", data: @freshest_quantity_summary.map { |s| [s[:date_label], s[:systems_fresh_union]] }, color: "#0000FF" }
      ]

      # Summary per edition: count of distinct new (fresh) component models (e.g. 2 new GPU models: A100, Tesla)
      @freshest_quantity_models_summary = chart_editions.map do |ed|
        cpu_ids = @freshest_cpu_model_ids_by_edition[ed] || Set.new
        gpu_ids = @freshest_gpu_model_ids_by_edition[ed] || Set.new
        models_fresh_cpu = cpu_ids.size
        models_fresh_gpu = gpu_ids.size
        models_fresh_union = (cpu_ids | gpu_ids).size
        {
          edition: ed,
          date_label: @freshest_quantity_chart_dates[ed],
          models_fresh_cpu: models_fresh_cpu,
          models_fresh_gpu: models_fresh_gpu,
          models_fresh_union: models_fresh_union
        }
      end
      @freshest_quantity_models_chart_data = [
        { name: "Новые модели CPU", data: @freshest_quantity_models_summary.map { |s| [s[:date_label], s[:models_fresh_cpu]] }, color: "#2ca02c" },
        { name: "Новые модели GPU", data: @freshest_quantity_models_summary.map { |s| [s[:date_label], s[:models_fresh_gpu]] }, color: "#ff7f0e" },
        { name: "Новые модели CPU + GPU", data: @freshest_quantity_models_summary.map { |s| [s[:date_label], s[:models_fresh_union]] }, color: "#0000FF" }
      ]

      # Summary per edition: total quantity of new (fresh) components (for second chart)
      @freshest_quantity_components_summary = chart_editions.map do |ed|
        cpu_entries = cpu_by_edition[ed] || []
        gpu_entries = gpu_by_edition[ed] || []
        components_fresh_cpu = cpu_entries.sum { |h| h[:lag].to_i }
        components_fresh_gpu = gpu_entries.sum { |h| h[:lag].to_i }
        components_fresh_both = components_fresh_cpu + components_fresh_gpu
        {
          edition: ed,
          date_label: @freshest_quantity_chart_dates[ed],
          components_fresh_cpu: components_fresh_cpu,
          components_fresh_gpu: components_fresh_gpu,
          components_fresh_both: components_fresh_both
        }
      end
      @freshest_quantity_components_chart_data = [
        { name: "Новые CPU", data: @freshest_quantity_components_summary.map { |s| [s[:date_label], s[:components_fresh_cpu]] }, color: "#2ca02c" },
        { name: "Новые GPU", data: @freshest_quantity_components_summary.map { |s| [s[:date_label], s[:components_fresh_gpu]] }, color: "#ff7f0e" },
        { name: "Новые CPU + GPU", data: @freshest_quantity_components_summary.map { |s| [s[:date_label], s[:components_fresh_both]] }, color: "#0000FF" }
      ]

      # Percentage of new components: all systems vs only systems with new components
      pct_all_data = []
      pct_new_systems_data = []
      chart_editions.each do |ed|
        cpu_entries = cpu_by_edition[ed] || []
        comp_summary = @freshest_quantity_components_summary.find { |s| s[:edition] == ed }
        components_fresh_cpu = comp_summary ? comp_summary[:components_fresh_cpu] : 0
        components_fresh_gpu = comp_summary ? comp_summary[:components_fresh_gpu] : 0
        components_fresh_both = comp_summary ? comp_summary[:components_fresh_both] : 0

        total_cpu_all = cpu_entries.sum { |h| h[:total_cpu].to_i }
        total_gpu_all = cpu_entries.sum { |h| h[:total_gpu].to_i }
        total_components_all = total_cpu_all + total_gpu_all

        ranks_fresh_cpu = cpu_entries.select { |h| h[:lag].to_i > 0 }.map { |h| h[:rank] }.uniq
        ranks_fresh_gpu = (gpu_by_edition[ed] || []).select { |h| h[:lag].to_i > 0 }.map { |h| h[:rank] }.uniq
        ranks_with_new = ranks_fresh_cpu | ranks_fresh_gpu
        entries_with_new = cpu_entries.select { |h| ranks_with_new.include?(h[:rank]) }
        total_cpu_new_systems = entries_with_new.sum { |h| h[:total_cpu].to_i }
        total_gpu_new_systems = entries_with_new.sum { |h| h[:total_gpu].to_i }
        total_components_new_systems = total_cpu_new_systems + total_gpu_new_systems

        pct_cpu_all = total_cpu_all > 0 ? 100.0 * components_fresh_cpu / total_cpu_all : 0.0
        pct_gpu_all = total_gpu_all > 0 ? 100.0 * components_fresh_gpu / total_gpu_all : 0.0
        pct_both_all = total_components_all > 0 ? 100.0 * components_fresh_both / total_components_all : 0.0

        pct_cpu_new = total_cpu_new_systems > 0 ? 100.0 * components_fresh_cpu / total_cpu_new_systems : 0.0
        pct_gpu_new = total_gpu_new_systems > 0 ? 100.0 * components_fresh_gpu / total_gpu_new_systems : 0.0
        pct_both_new = total_components_new_systems > 0 ? 100.0 * components_fresh_both / total_components_new_systems : 0.0

        date_label = @freshest_quantity_chart_dates[ed]
        pct_all_data << { date_label: date_label, pct_cpu: pct_cpu_all, pct_gpu: pct_gpu_all, pct_both: pct_both_all }
        pct_new_systems_data << { date_label: date_label, pct_cpu: pct_cpu_new, pct_gpu: pct_gpu_new, pct_both: pct_both_new }
      end

      @freshest_quantity_pct_all_chart_data = [
        { name: "Новые CPU, %", data: pct_all_data.map { |s| [s[:date_label], s[:pct_cpu]] }, color: "#2ca02c" },
        { name: "Новые GPU, %", data: pct_all_data.map { |s| [s[:date_label], s[:pct_gpu]] }, color: "#ff7f0e" },
        { name: "Новые CPU+GPU, %", data: pct_all_data.map { |s| [s[:date_label], s[:pct_both]] }, color: "#0000FF" }
      ]
      @freshest_quantity_pct_new_systems_chart_data = [
        { name: "Новые CPU, %", data: pct_new_systems_data.map { |s| [s[:date_label], s[:pct_cpu]] }, color: "#2ca02c" },
        { name: "Новые GPU, %", data: pct_new_systems_data.map { |s| [s[:date_label], s[:pct_gpu]] }, color: "#ff7f0e" },
        { name: "Новые CPU+GPU, %", data: pct_new_systems_data.map { |s| [s[:date_label], s[:pct_both]] }, color: "#0000FF" }
      ]

      # Rpeak/Rmax share of systems with new components (like new_upg section)
      if @rpeak_attrid.present? && @rmax_benchid.present?
        rmax_by_machine = Top50BenchmarkResult.where(benchmark_id: @rmax_benchid).index_by(&:machine_id)
        rpeak_rows = ActiveRecord::Base.connection.select_all(
          "SELECT obj_id, cast(encode(value, 'escape') as double precision) as num FROM top50_attribute_val_dbvals WHERE attr_id = #{@rpeak_attrid}"
        )
        rpeak_by_machine = rpeak_rows.rows.each_with_object({}) do |row, h|
          val = (row[1] || 0).to_f
          h[row[0].to_i] = val
          h[row[0].to_s] = val
        end

        rpeak_pct_cpu = []
        rpeak_pct_gpu = []
        rpeak_pct_union = []
        rmax_pct_cpu = []
        rmax_pct_gpu = []
        rmax_pct_union = []
        chart_editions.each do |ed|
          date_label = @freshest_quantity_chart_dates[ed]
          parts = date_label.to_s.split("-")
          next if parts.size < 2
          list_id = get_list_id_by_date(parts[0], parts[1])
          next if list_id.to_i <= 0
          benchmark_results = Top50BenchmarkResult.where(benchmark_id: list_id).order(result: :asc).limit(50)
          rank_to_machine = benchmark_results.each_with_index.map { |br, i| [i + 1, br.machine_id] }.to_h

          cpu_entries = cpu_by_edition[ed] || []
          ranks_fresh_cpu = cpu_entries.select { |h| h[:lag].to_i > 0 }.map { |h| h[:rank] }.uniq
          ranks_fresh_gpu = (gpu_by_edition[ed] || []).select { |h| h[:lag].to_i > 0 }.map { |h| h[:rank] }.uniq
          ranks_with_new = ranks_fresh_cpu | ranks_fresh_gpu

          sum_rpeak_total = rank_to_machine.values.sum { |mid| (rpeak_by_machine[mid] || rpeak_by_machine[mid.to_s] || 0).to_f }
          sum_rmax_total = rank_to_machine.values.sum { |mid| (rmax_by_machine[mid] || rmax_by_machine[mid.to_i])&.result.to_f || 0 }
          sum_rpeak_cpu = ranks_fresh_cpu.sum { |rank| (rpeak_by_machine[rank_to_machine[rank]] || rpeak_by_machine[rank_to_machine[rank].to_s] || 0).to_f }
          sum_rpeak_gpu = ranks_fresh_gpu.sum { |rank| (rpeak_by_machine[rank_to_machine[rank]] || rpeak_by_machine[rank_to_machine[rank].to_s] || 0).to_f }
          sum_rpeak_union = ranks_with_new.sum { |rank| (rpeak_by_machine[rank_to_machine[rank]] || rpeak_by_machine[rank_to_machine[rank].to_s] || 0).to_f }
          sum_rmax_cpu = ranks_fresh_cpu.sum { |rank| (rmax_by_machine[rank_to_machine[rank]] || rmax_by_machine[rank_to_machine[rank].to_i])&.result.to_f || 0 }
          sum_rmax_gpu = ranks_fresh_gpu.sum { |rank| (rmax_by_machine[rank_to_machine[rank]] || rmax_by_machine[rank_to_machine[rank].to_i])&.result.to_f || 0 }
          sum_rmax_union = ranks_with_new.sum { |rank| (rmax_by_machine[rank_to_machine[rank]] || rmax_by_machine[rank_to_machine[rank].to_i])&.result.to_f || 0 }

          pct_rpeak_cpu = sum_rpeak_total > 0 ? (100.0 * sum_rpeak_cpu / sum_rpeak_total).round(2) : 0.0
          pct_rpeak_gpu = sum_rpeak_total > 0 ? (100.0 * sum_rpeak_gpu / sum_rpeak_total).round(2) : 0.0
          pct_rpeak_u = sum_rpeak_total > 0 ? (100.0 * sum_rpeak_union / sum_rpeak_total).round(2) : 0.0
          pct_rmax_cpu = sum_rmax_total > 0 ? (100.0 * sum_rmax_cpu / sum_rmax_total).round(2) : 0.0
          pct_rmax_gpu = sum_rmax_total > 0 ? (100.0 * sum_rmax_gpu / sum_rmax_total).round(2) : 0.0
          pct_rmax_u = sum_rmax_total > 0 ? (100.0 * sum_rmax_union / sum_rmax_total).round(2) : 0.0
          rpeak_pct_cpu << [date_label, pct_rpeak_cpu]
          rpeak_pct_gpu << [date_label, pct_rpeak_gpu]
          rpeak_pct_union << [date_label, pct_rpeak_u]
          rmax_pct_cpu << [date_label, pct_rmax_cpu]
          rmax_pct_gpu << [date_label, pct_rmax_gpu]
          rmax_pct_union << [date_label, pct_rmax_u]
        end

        @freshest_quantity_rpeak_pct_chart_data = [
          { name: "С новыми CPU", data: rpeak_pct_cpu, color: "#2ca02c" },
          { name: "С новыми GPU", data: rpeak_pct_gpu, color: "#ff7f0e" },
          { name: "С новыми CPU или GPU", data: rpeak_pct_union, color: "#0000FF" }
        ]
        @freshest_quantity_rmax_pct_chart_data = [
          { name: "С новыми CPU", data: rmax_pct_cpu, color: "#2ca02c" },
          { name: "С новыми GPU", data: rmax_pct_gpu, color: "#ff7f0e" },
          { name: "С новыми CPU или GPU", data: rmax_pct_union, color: "#0000FF" }
        ]
      else
        @freshest_quantity_rpeak_pct_chart_data = []
        @freshest_quantity_rmax_pct_chart_data = []
      end

      # Table for export: one row per edition with all chart metrics
      @freshest_comp_stats_table = chart_editions.each_with_index.map do |ed, idx|
        sum = @freshest_quantity_summary.find { |s| s[:edition] == ed } || {}
        mod = @freshest_quantity_models_summary.find { |s| s[:edition] == ed } || {}
        comp = @freshest_quantity_components_summary.find { |s| s[:edition] == ed } || {}
        date_label = sum[:date_label] || @freshest_quantity_chart_dates[ed]
        parts = date_label.to_s.split("-")
        list_id = parts.size >= 2 ? get_list_id_by_date(parts[0], parts[1]) : nil
        row = {
          date_label: date_label,
          list_id: list_id,
          systems_cpu: sum[:systems_fresh_cpu],
          systems_gpu: sum[:systems_fresh_gpu],
          systems_union: sum[:systems_fresh_union],
          models_cpu: mod[:models_fresh_cpu],
          models_gpu: mod[:models_fresh_gpu],
          models_union: mod[:models_fresh_union],
          components_cpu: comp[:components_fresh_cpu],
          components_gpu: comp[:components_fresh_gpu],
          components_both: comp[:components_fresh_both],
          pct_all_cpu: @freshest_quantity_pct_all_chart_data[0][:data][idx]&.at(1),
          pct_all_gpu: @freshest_quantity_pct_all_chart_data[1][:data][idx]&.at(1),
          pct_all_both: @freshest_quantity_pct_all_chart_data[2][:data][idx]&.at(1),
          pct_new_cpu: @freshest_quantity_pct_new_systems_chart_data[0][:data][idx]&.at(1),
          pct_new_gpu: @freshest_quantity_pct_new_systems_chart_data[1][:data][idx]&.at(1),
          pct_new_both: @freshest_quantity_pct_new_systems_chart_data[2][:data][idx]&.at(1),
          pct_rpeak_cpu: nil,
          pct_rpeak_gpu: nil,
          pct_rpeak_union: nil,
          pct_rmax_cpu: nil,
          pct_rmax_gpu: nil,
          pct_rmax_union: nil
        }
        if (@freshest_quantity_rpeak_pct_chart_data || []).size >= 3 && (@freshest_quantity_rmax_pct_chart_data || []).size >= 3
          row[:pct_rpeak_cpu] = @freshest_quantity_rpeak_pct_chart_data[0][:data][idx]&.at(1)
          row[:pct_rpeak_gpu] = @freshest_quantity_rpeak_pct_chart_data[1][:data][idx]&.at(1)
          row[:pct_rpeak_union] = @freshest_quantity_rpeak_pct_chart_data[2][:data][idx]&.at(1)
          row[:pct_rmax_cpu] = @freshest_quantity_rmax_pct_chart_data[0][:data][idx]&.at(1)
          row[:pct_rmax_gpu] = @freshest_quantity_rmax_pct_chart_data[1][:data][idx]&.at(1)
          row[:pct_rmax_union] = @freshest_quantity_rmax_pct_chart_data[2][:data][idx]&.at(1)
        end
        row
      end

      # CSV lines for download (header + one row per edition)
      @freshest_comp_stats_csv_header = "Редакция,Системы с новыми CPU,Системы с новыми GPU,Системы с новыми CPU или GPU,Новых моделей CPU,Новых моделей GPU,Новых моделей CPU+GPU,Кол-во новых CPU,Кол-во новых GPU,Кол-во новых CPU+GPU,% новых CPU (все),% новых GPU (все),% новых CPU+GPU (все),% новых CPU (сист. с нов.),% новых GPU (сист. с нов.),% новых CPU+GPU (сист. с нов.),% Rpeak CPU,% Rmax CPU,% Rpeak GPU,% Rmax GPU,% Rpeak CPU или GPU,% Rmax CPU или GPU"
      @freshest_comp_stats_csv_lines = [@freshest_comp_stats_csv_header]
      @freshest_comp_stats_table.reverse.each do |r|
        list_num = r[:list_id].present? ? @num_vals.find_by(obj_id: r[:list_id]) : nil
        date_val = r[:list_id].present? ? @date_vals.find_by(obj_id: r[:list_id]) : nil
        edition_csv = list_num.present? && date_val.present? ? "#{list_num.value} (#{date_val.value})" : r[:date_label].to_s
        pct = ->(v) { v.present? ? v.to_f.round(2).to_s : "" }
        csv_row = [
          edition_csv,
          r[:systems_cpu].to_s,
          r[:systems_gpu].to_s,
          r[:systems_union].to_s,
          r[:models_cpu].to_s,
          r[:models_gpu].to_s,
          r[:models_union].to_s,
          r[:components_cpu].to_s,
          r[:components_gpu].to_s,
          r[:components_both].to_s,
          pct.call(r[:pct_all_cpu]),
          pct.call(r[:pct_all_gpu]),
          pct.call(r[:pct_all_both]),
          pct.call(r[:pct_new_cpu]),
          pct.call(r[:pct_new_gpu]),
          pct.call(r[:pct_new_both]),
          pct.call(r[:pct_rpeak_cpu]),
          pct.call(r[:pct_rmax_cpu]),
          pct.call(r[:pct_rpeak_gpu]),
          pct.call(r[:pct_rmax_gpu]),
          pct.call(r[:pct_rpeak_union]),
          pct.call(r[:pct_rmax_union])
        ]
        @freshest_comp_stats_csv_lines << csv_row.join(",")
      end

      # Exclude the first list from heatmaps (same as charts)
      @freshest_cpu_quantity_data = @freshest_cpu_quantity_data.select { |h| chart_editions.include?(h[:edition]) }
      @freshest_gpu_quantity_data = @freshest_gpu_quantity_data.select { |h| chart_editions.include?(h[:edition]) }
      @announce_to_mention_cpu_data = @announce_to_mention_cpu_data.select { |h| chart_editions.include?(h[:edition]) }
      @announce_to_mention_gpu_data = @announce_to_mention_gpu_data.select { |h| chart_editions.include?(h[:edition]) }

    elsif  @stat_section == 'list_upg'
      precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
      @prec_machines = precedes_type_id ? Top50Relation.where(type_id: precedes_type_id, is_valid: [1, 2]) : []
      @ed_num_attrid = Top50Attribute.where(name_eng: "Edition number").first&.id
      @ed_date_attrid = Top50Attribute.where(name_eng: "Edition date").first&.id

      @new_upd_data = [] # Данные для матрицы
      top50_slists = get_top50_lists_sorted
      top_50_dates = []
      
      # Получаем список дат для каждой редакции
      top50_slists.each do |top50_list|
        list_num = @num_vals.find_by(obj_id: top50_list.id)
        date_val = @date_vals.find_by(obj_id: top50_list.id)
        list_year = date_val.value.split(".")[2]
        list_month = date_val.value.split(".")[1]
        top_50_dates.push([list_year, list_month])
      end
      
      all_ratings_list_upg = []
      top_50_dates.each_with_index do |top50_date, idx|
        list_id = get_list_id_by_date(top50_date[0], top50_date[1])
        top50_machines = fetch_archive_list(list_id)
        prev_rated_pos = []
        if idx + 1 < top50_slists.size
          prev_list_id = top50_slists[idx + 1].id
          prev_rated_pos = Top50BenchmarkResult.where(benchmark_id: prev_list_id).to_a
        end
        rating_data = {
          list_id: list_id,
          date: top50_date,
          machines: top50_machines,
          prec_machines: @prec_machines.dup,
          prev_rated_pos: prev_rated_pos
        }
        all_ratings_list_upg << rating_data
      end

      all_ratings_list_upg.each_with_index do |rating_data, idx|
        top50_date = rating_data[:date]
        is_first_list = (idx == all_ratings_list_upg.size - 1)
        rating_data[:machines].each do |top50_machine|
          machine_id = top50_machine["id"]
          new_upd_status = nil
          pos_status = nil
          rank_change = nil
          rank_pos = top50_machine["result"].to_i
          unless is_first_list
            is_upg = false
            prec_machine = nil
            prev_rank_pos = rating_data[:prev_rated_pos].find { |pos| pos.machine_id == machine_id }

            if prev_rank_pos.nil?
              prec_machine = rating_data[:prec_machines].find { |prec| prec.sec_obj_id == machine_id }
              if prec_machine.present?
                prev_rank_pos = rating_data[:prev_rated_pos].find { |pos| pos.machine_id == prec_machine.prim_obj_id }
                is_upg = true if prev_rank_pos.present?
              end
            end
            if prev_rank_pos.present?
              prev_rank = prev_rank_pos.result.to_i
              if rank_pos != prev_rank
                rank_change = prev_rank - rank_pos
                pos_status = rank_change > 0 ? "moved_up" : "moved_down"
              end
              new_upd_status = "updated" if is_upg
            else
              new_upd_status = prec_machine.present? ? "updated" : "new"
            end
          end

          list_num = @num_vals.find_by(obj_id: rating_data[:list_id])&.value
          machine_name = (top50_machine["name"] || top50_machine.try(:name)).to_s.presence || (top50_machine.try(:top50_organization).try(:name)).to_s.presence || "н/д"
          @new_upd_data << {
            edition: top50_date.join('-'),
            list_id: rating_data[:list_id],
            list_num: list_num,
            rank: rank_pos,
            new_upd_status: new_upd_status,
            pos_status: pos_status,
            rank_change: rank_change,
            machine_id: machine_id,
            machine_name: machine_name
          }
        end
      end
      @new_upd_data.sort_by! do |entry|
        [-entry[:edition].split('-').join.to_i, entry[:rank]]
      end
      @new_upd_data_2d = @new_upd_data.group_by { |entry| entry[:edition] }.values
      lists_chronological = top50_slists.reverse
      @new_upd_list_ids = lists_chronological.map(&:id)
      @new_upd_list_nums = @new_upd_list_ids.map { |lid| @num_vals.find_by(obj_id: lid)&.value }.map { |v| v.presence || "—" }
      @new_upd_matrix = (1..50).map do |rank|
        @new_upd_list_ids.map do |list_id|
          @new_upd_data.find { |e| e[:rank] == rank && e[:list_id] == list_id }
        end
      end
      col_headers = (1..@new_upd_list_ids.size).to_a
      @csv_string_list_upg = col_headers.present? ? ["Место | Редакция," + col_headers.join(",")] : []
      @new_upd_matrix.each_with_index do |row, idx|
        row_str = (idx + 1).to_s
        row.each do |entry|
          cell = if entry.present?
            statuses = []
            statuses << (entry[:new_upd_status] == "updated" ? "upg" : entry[:new_upd_status]) if entry[:new_upd_status].present?
            statuses << "+#{entry[:rank_change]}" if entry[:pos_status] == "moved_up" && entry[:rank_change].present?
            statuses << "-#{entry[:rank_change].abs}" if entry[:pos_status] == "moved_down" && entry[:rank_change].present?
            statuses.present? ? statuses.join(" ") : ""
          else
            ""
          end
          cell_str = cell.to_s.include?(',') ? "\"#{cell.to_s.gsub('"', '""')}\"" : cell.to_s
          row_str += "," + cell_str
        end
        @csv_string_list_upg << row_str if @csv_string_list_upg.present?
      end
      @chart_data = @new_upd_data.map do |entry|
        {
          edition: entry[:edition],
          rank: entry[:rank],
          new_upd_status: entry[:new_upd_status],
          pos_status: entry[:pos_status],
          rank_change: entry[:rank_change],
          machine_id: entry[:machine_id],
          machine_name: entry[:machine_name]
        }
      end.to_json      
                  
    elsif  @stat_section == 'area'
      area_dict_id = Top50Dictionary.where(name_eng: 'Application areas').first.id
      @mach_x_areas = Top50DictionaryElem.all.select("top50_dictionary_elems.id area_id, top50_dictionary_elems.name area_name, top50_machines.id mach_id").
        joins("join top50_attribute_val_dicts on top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id").
        joins("join top50_machines on top50_machines.id = top50_attribute_val_dicts.obj_id").
        where("top50_dictionary_elems.dict_id = #{area_dict_id}
           AND top50_machines.id IN (?)", @mach_approved).
        map(&:attributes)
      _area = Struct.new('AppArea', :area_id, :area_name)
      @area_id_hash = Hash.new{|h, k| h[k] = []}
      @top50_areas = []
      @mach_x_areas.each do |rec|
        if @area_id_hash[rec["area_id"]].empty?
          @top50_areas << _area.new(rec["area_id"], rec["area_name"])
        end
        @area_id_hash[rec["area_id"]] << rec["mach_id"]
      end
    elsif  @stat_section == 'city'
      @mach_x_cities = Top50City.all.select("top50_cities.id, top50_cities.name, top50_machines.id mach_id").
        joins("join top50_organizations o on o.city_id = top50_cities.id").
        joins("join top50_machines on top50_machines.org_id = o.id").
        where("top50_machines.id IN (?)", @mach_approved).
        map(&:attributes)
      @city_id_hash = Hash.new{|h, k| h[k] = []}
      @top50_cities = []
      @mach_x_cities.each do |rec|
        if @city_id_hash[rec["id"]].empty?
          @top50_cities << Top50City.find_by(id: rec["id"])
        end
        @city_id_hash[rec["id"]] << rec["mach_id"]
      end

    elsif @stat_section == 'cpu_cnt' or @stat_section == 'core_cnt'
      if @stat_section == 'cpu_cnt'
        cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first.id
        c_qty_attrid = Top50Attribute.where(name_eng: "Number of CPUs").first.id
        @mach_x_ccnt = Top50Relation.select("top50_relations.prim_obj_id mach_id, sum(top50_relations.sec_obj_qty * l2r.sec_obj_qty) as c_cnt").
          joins("join top50_relations l2r on l2r.prim_obj_id = top50_relations.sec_obj_id and l2r.type_id = #{rel_contain_id}").
          joins("join top50_objects l2o on l2o.id = l2r.sec_obj_id and l2o.type_id = #{cpu_typeid}").
          where("top50_relations.type_id = #{rel_contain_id}
            AND top50_relations.prim_obj_id IN (?)", @mach_approved).
          group("top50_relations.prim_obj_id").
          map(&:attributes)
        up_bound = 8192
        low_bound = 8
      elsif @stat_section == 'core_cnt'
        core_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first.id
        c_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first.id
        @mach_x_ccnt = Top50Relation.select("top50_relations.prim_obj_id mach_id, sum(top50_relations.sec_obj_qty * l2r.sec_obj_qty * cast(encode(avd.value, 'escape') as int)) as c_cnt").
          joins("join top50_relations l2r on l2r.prim_obj_id = top50_relations.sec_obj_id and l2r.type_id = #{rel_contain_id}").
          joins("join top50_attribute_val_dbvals avd on avd.obj_id = l2r.sec_obj_id and avd.attr_id = #{core_qty_attrid}").
          where("top50_relations.type_id = #{rel_contain_id}
            AND top50_relations.prim_obj_id IN (?)", @mach_approved).
          group("top50_relations.prim_obj_id").
          map(&:attributes)
        up_bound = 65536
        low_bound = 8
      end
      attr_mach_x_ccnt = Top50AttributeValDbval.
          where(attr_id: c_qty_attrid, obj_id: @mach_approved).
          pluck(:obj_id, :value)
      @ccnt_id_hash = Hash.new{|h, k| h[k] = []}
      @top50_ccnts = []
      @top50_ccnts << "1-#{low_bound}"
      c_bound = low_bound
      while c_bound < up_bound
        @top50_ccnts << "#{c_bound + 1}-#{c_bound * 2}"
        c_bound *= 2
      end
      @top50_ccnts << "> #{up_bound}"
      @mach_approved.each do |mach|
        rec = @mach_x_ccnt.find{|x| x["mach_id"] == mach}
        c_cnt = 0
        if rec and rec["c_cnt"] > 0
          c_cnt = rec["c_cnt"]
        else
          attr_ccnt = attr_mach_x_ccnt.find{|x| x[0] == mach}
          if attr_ccnt
            c_cnt = attr_ccnt[1].to_i
          end
        end
        if c_cnt > 0
          if c_cnt > up_bound
            bucket = "> #{up_bound}"
          elsif c_cnt <= low_bound
            bucket = "1-#{low_bound}"
          else
            c_bound = up_bound
            until c_cnt > c_bound
              c_bound /= 2
            end
            bucket = "#{c_bound + 1}-#{c_bound * 2}"
          end
          @ccnt_id_hash[bucket] << mach
        end
      end
    elsif @stat_section == 'comm_net'
      cnet_dict_id = Top50Dictionary.where(name_eng: 'Net families').first.id
      @mach_x_cnets = Top50DictionaryElem.all.select("top50_dictionary_elems.id cnet_id, top50_dictionary_elems.name cnet_name, top50_machines.id mach_id").
        joins("join top50_attribute_val_dicts on top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id").
        joins("join top50_machines on top50_machines.id = top50_attribute_val_dicts.obj_id").
        where("top50_dictionary_elems.dict_id = #{cnet_dict_id}
           AND top50_machines.id IN (?)", @mach_approved).
        map(&:attributes)
        
      _cnet = Struct.new('Cnet', :cnet_id, :cnet_name)
      @cnet_id_hash = Hash.new{|h, k| h[k] = []}
      @top50_cnets = []
      @mach_x_cnets.each do |rec|
        if @cnet_id_hash[rec["cnet_id"]].empty?
          @top50_cnets << _cnet.new(rec["cnet_id"], rec["cnet_name"])
        end
        @cnet_id_hash[rec["cnet_id"]] << rec["mach_id"]
      end
    elsif @stat_section == 'comm_net_sep'
      comm_net_attrid = Top50Attribute.where(name_eng: "Communication network").first.id
      @mach_x_cnets = Top50DictionaryElem.all.select("top50_dictionary_elems.id cnet_id, top50_dictionary_elems.name cnet_name, top50_machines.id mach_id").
       joins("join top50_attribute_val_dicts on top50_attribute_val_dicts.dict_elem_id = top50_dictionary_elems.id").
       joins("join top50_machines on top50_machines.id = top50_attribute_val_dicts.obj_id").
       where("top50_attribute_val_dicts.attr_id = #{comm_net_attrid}
          AND top50_machines.id IN (?)", @mach_approved).
       map(&:attributes)
        
      _cnet = Struct.new('Cnet', :cnet_id, :cnet_name)
      @cnet_id_hash = Hash.new{|h, k| h[k] = []}
      @top50_cnets = []
      @pop_cnets = {}
      @mach_x_cnets.each do |rec|
        if @cnet_id_hash[rec["cnet_id"]].empty?
          @top50_cnets << _cnet.new(rec["cnet_id"], rec["cnet_name"])
          @pop_cnets[rec["cnet_name"]] = false
        end
        @cnet_id_hash[rec["cnet_id"]] << rec["mach_id"]
      end

      @top50_slists.each do |list|
        @top50_cnets.each do |cnet|
          c_cnt = Top50BenchmarkResult.where("benchmark_id = #{list.id} AND machine_id IN (?)", @cnet_id_hash[cnet.cnet_id]).count
          if c_cnt > 2
            @pop_cnets[cnet.cnet_name] = true
          end
        end
      end
      @pop_cnets.each do |key, value|
        if !value
          @top50_cnets.delete_if{|el| el.cnet_name == key}
        end
      end
    end
  end

  def get_avail_mtypes
    return Top50MachineType.select("top50_machine_types.id, top50_machine_types.name, count(1) cnt").joins("join top50_machines on top50_machine_types.id = top50_machines.type_id").joins("join top50_benchmark_results on top50_benchmark_results.machine_id = top50_machines.id").joins("join top50_benchmarks on top50_benchmarks.id = top50_benchmark_results.benchmark_id").joins("join top50_relations on top50_benchmarks.id = top50_relations.sec_obj_id").where("top50_relations.prim_obj_id IN (?) and top50_relations.type_id = ?", get_avail_bunches, get_rel_contain_id).group("top50_machine_types.id, top50_machine_types.name").order("cnt desc").having("count(1) > 0")
  end

  def ext_stats_common(eid)
    stats_common
    @edition_id = get_top50_lists.find(eid).id
    @top50_mtypes = get_avail_mtypes
  end

  def ext_stats
    ext_stats_common(params[:eid].to_i)
  end

  def get_ext_stats
    ext_stats_common(get_list_id_by_date(params[:year], params[:month]))
    render :ext_stats
    return
  end

  def new
    @top50_machine = Top50Machine.new
  end

  def create
    @top50_machine = Top50Machine.new(top50machine_params)
    @top50_machine[:comment] = "Added system"
    if @top50_machine.save
      redirect_to :back
    else
      render :new
    end
  end

  def edit
    @top50_machine = Top50Machine.find(params[:id])
  end

  def update
    @top50_machine = Top50Machine.find(params[:id])
    vendor_ids = params[:top50_machine][:vendor_ids]
    vendor_ids.delete("")
    vendor_ids.collect! {|x| x.to_i}
    if params[:top50_machine][:vendor_id].present?
      vendor_ids = ([params[:top50_machine][:vendor_id].to_i] + vendor_ids).uniq
    end
    @top50_machine.vendor_ids = vendor_ids
    @top50_machine.update_attributes(top50machine_params)
    if top50machine_params[:is_valid].to_i == 1
      @top50_machine.confirm
    end
    redirect_to :top50_machines
  end

  def destroy
    @top50_machine = Top50Machine.find(params[:id])
    @top50_machine.destroy
    redirect_to :top50_machines
  end
  
  def prepare_arch_attrs
    ram_size_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "RAM size (GB)"))
    @ram_size_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(ram_size_attrs)
    cpu_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "CPU model"))
    @cpu_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cpu_model_attrs)
    cpu_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "CPU Vendor"))
    @cpu_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cpu_vendor_attrs)
    gpu_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "GPU model"))
    @gpu_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(gpu_model_attrs)
    gpu_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "GPU Vendor"))
    @gpu_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(gpu_vendor_attrs)
    cop_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Coprocessor model"))
    @cop_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cop_model_attrs)
    cop_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Coprocessor Vendor"))
    @cop_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cop_vendor_attrs)
    @cop_objects = Top50Object.all.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "Coprocessor"))
    @cpu_objects = Top50Object.all.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "CPU"))
    @gpu_objects = Top50Object.all.joins(:top50_object_type).merge(Top50ObjectType.where(name_eng: "GPU"))
  end
  
  def add_component
    @comp_node_type = Top50ObjectType.where(name_eng: 'Compute node').first
    @top50_machine = Top50Machine.find(params[:id])
    @top50_object = Top50Object.find(params[:id])
    @top50_nested_object = Top50Object.new
    @top50_relation = Top50Relation.new
    @cpu_dict_id = Top50Dictionary.where(name_eng: 'CPU model').first.id
    @gpu_dict_id = Top50Dictionary.where(name_eng: 'GPU model').first.id
    @cop_dict_id = Top50Dictionary.where(name_eng: 'Coprocessor model').first.id
    
    prepare_arch_attrs
  end

  def create_component
    @rel_contain_id = get_rel_contain_id
    @comp_node_id = Top50ObjectType.where(name_eng: 'Compute node').first.id
    @cpu_typeid = Top50ObjectType.where(name_eng: 'CPU').first.id
    @gpu_type_id = Top50ObjectType.where(name_eng: 'GPU').first.id
    @cop_type_id = Top50ObjectType.where(name_eng: 'Coprocessor').first.id
    
    @top50_machine = Top50Machine.find(params[:id])
    @top50_object = Top50Object.find(params[:id])
    
    top50_relation = @top50_object.top50_relations.build(top50_node_params[:top50_node])
    top50_relation.type_id = get_rel_contain_id
    top50_nested_node = Top50Object.new
    top50_nested_node.type_id = @comp_node_id
    top50_nested_node.is_valid = top50_node_params[:top50_node][:is_valid]
    top50_relation.sec_obj_id = top50_nested_node.id
    if top50_node_params[:top50_cpu][:sec_obj_qty].present? and top50_node_params[:top50_cpu][:sec_obj_qty].to_i > 0
        top50_cpu_relation = top50_nested_node.top50_relations.build
        top50_cpu_relation.sec_obj_qty = top50_node_params[:top50_cpu][:sec_obj_qty]
        top50_cpu_relation.is_valid = top50_node_params[:top50_cpu][:is_valid]
        top50_cpu_id = Top50AttributeValDict.where(dict_elem_id: top50_node_params[:top50_cpu][:model_dict_elem_id]).first.obj_id
        top50_cpu_relation.type_id = @rel_contain_id
        top50_cpu_relation.sec_obj_id = top50_cpu_id
    end
    if top50_node_params[:top50_acc][:sec_obj_qty].present? and top50_node_params[:top50_acc][:sec_obj_qty].to_i > 0
        top50_acc_relation = top50_nested_node.top50_relations.build
        top50_acc_relation.sec_obj_qty = top50_node_params[:top50_acc][:sec_obj_qty]
        top50_acc_relation.is_valid = top50_node_params[:top50_acc][:is_valid]
        top50_acc_id = Top50AttributeValDict.where(dict_elem_id: top50_node_params[:top50_acc][:model_dict_elem_id]).first.obj_id
        top50_acc_relation.type_id = @rel_contain_id
        top50_acc_relation.sec_obj_id = top50_acc_id
    end
    
    top50_ram_attr = top50_nested_node.top50_attribute_val_dbvals.build
    @ram_size_attrid = Top50Attribute.where(name_eng: "RAM size (GB)").first.id
    top50_ram_attr.attr_id = @ram_size_attrid
    top50_ram_attr.value = top50_node_params[:top50_ram][:ram_size]
    top50_ram_attr.is_valid = top50_node_params[:top50_ram][:is_valid]
    
    redirect_to top50_machines_app_form_step2_url
  end

  helper_method :ext_url

  def ext_url(s)
    if s.downcase.start_with? "http"
      return s
    else
      return "http://" + s
    end
  end

  def default
    Top50Machine.default!
    redirect_to :top50_machines
  end
  
  helper_method :get_cur

  def get_cur(param)
    if @cur_data.present?
      return @cur_data.fetch(param, nil)
    end
  end

  helper_method :get_cur2

  def get_cur2(param, nested_param)
    if @cur_data.present?
      return @cur_data.fetch(param, {}).fetch(nested_param, nil)
    end
  end

  helper_method :is_focused

  def is_focused(k, k2)
    if @focus_fields.present?
      return @focus_fields.fetch([k, k2], false)
    end
    return false
  end

  def fetch_cur_data
    params.reject {|k,v| ["step1_data", "step2_data", "step3_data", "step4_data"].include? k}
  end

  def fetch_by_sym(data_sym)
    params.fetch(:sym, nil) == data_sym.to_s ? fetch_cur_data : params.fetch(data_sym, {})
  end

  def fetch_all_data_from_params
    @step1_data = fetch_by_sym(:step1_data)
    @step2_data = fetch_by_sym(:step2_data)
    @step3_data = fetch_by_sym(:step3_data) 
    @step4_data = fetch_by_sym(:step4_data)
  end

  def check_param(p_name, cd, data_errs)
    if cd.keys.any? {|x| params.has_key? x}
      cd.keys.each do |k|
        if cd[k].is_a? Hash
          cd[k].keys.each do |k2|
            if not params.fetch(k, {}).fetch(k2, nil).present?
              data_errs.append(cd[k][k2])
            end
          end
        else
          if not params.fetch(k, nil).present?
            data_errs.append(cd[k])
          end
        end
      end
    else
      data_errs.append(p_name)
    end  
  end

  def validate_req_params(step)
    req_params = {
      step1: {
        vendor_id: "Основной производитель системы",
        installation_date: "Год установки вычислительной системы",
        type_id: "Тип вычислительной системы",
        org_id: "Организация (место установки системы)",
        custom_suborg: {
          name: "Название подразделения",
          name_eng: "Название подразделения на английском языке",
          country: "Страна, в которой расположено подразделение",
          city: "Город расположения подразделения"
        },
        contact: {
          surname: "Фамилия контактного лица",
          name: "Имя контактного лица",
          email: "Email контактного лица"
        }
      },
      step2: {
      },
      step3: {
        app_area: {
          app_dict_elem_id: "Область применения вычислительной системы"
        },
        nets: {
          comm_net_dict_elem_id: "Основная коммуникационная (вычислительная) сеть",
          tplg_dict_elem_id: "Топология коммуникационной сети"
        }
      },
      step4: {
        top50_perf: {
          rpeak: "Rpeak",
          rmax: "Rmax",
          msize: "Размер матрицы, на котором было достигнута указанная производительность"
        }
      }
    }
    custom_req_params = {
      step1: {
        vendor_id: {
          custom_vendor: {
            name: "Название производителя",
            name_eng: "Название производителя на английском языке"
          }
        },
        type_id: {
          custom_type: {
            name: "Название типа системы",
            name_eng: "Название типа системы на английском языке"
          }
        },
        org_id: {
          custom_org: {
            name: "Название организации",
            name_eng: "Название организации на английском языке",
            country: "Страна, в которой расположена организация",
            city: "Город расположения организации"
          }
        }
      },
      step3: {
        app_area: {
          app_dict_elem_id: {
            app_area: {
              custom_app: "Область применения вычислительной системы"
            }
          }
        },
        nets: {
          comm_net_dict_elem_id: {
            nets: {
              custom_comm_net: "Основная коммуникационная (вычислительная) сеть"
            }
          },
          tplg_dict_elem_id: {
            nets: {
              custom_tplg: "Топология коммуникационной сети"
            }
          }
        }
      }
    }
    data_errs = []
    data = req_params.fetch(step, {})
    custom_data = custom_req_params.fetch(step, {})
    case step
    when :step1
      if params[:org_id].present? and params[:suborg_id].present?
        if not Top50Relation.where(type_id: get_rel_contain_id, prim_obj_id: params[:org_id].to_i).pluck(:sec_obj_id).include? params[:suborg_id].to_i
          return "Выбранное подразделение не соответствует организации"
        end
      end
      add_vendors = params.select {|k,v| k.starts_with? 'add_vendor_'}
      data.update(add_vendors.merge(add_vendors) {
        |k,v,x| {
          name: "Название участвующего производителя",
          name_eng: "Название участвующего производителя на английском языке"
        }
      })
    when :step2
      if params[:node_group_cnt].to_i == 0
        return "Не указано ни одной группы узлов вычислительной системы"
      end
      node_groups = params.select {|k,v| k.starts_with? 'top50_node_'}
      node_groups.keys.each do |node|
        data[node] = {
          node_cnt: "Количество вычислительных узлов в группе",
          ram_size: "Объем оперативной памяти"
        }
        custom_data[node] = {}
        if params[node][:cpu_model_obj_id].present? or params[node][:custom_cpu_from_node].present? or params[node][:custom_cpu_model].present?
          data[node].update({
            cpu_cnt: "Количество процессоров на одном узле"
          })
        end
        if params[node][:custom_cpu_model].present?
          data[node].update({
            custom_cpu_vendor_id: "Производитель процессора",
            custom_cpu_freq: "Тактовая частота процессора",
            custom_cpu_core_cnt: "Количество ядер процессора"
          })
          custom_data[node].update({
            custom_cpu_vendor_id: {node => {
              custom_cpu_vendor: "Производитель процессора"
            }}
          })
        end
        if params[node][:acc_model_obj_id].present? or params[node][:custom_acc_from_node].present? or params[node][:custom_acc_model].present?
          data[node].update({
            acc_cnt: "Количество ускорителей на одном узле"
          })
        end
        if params[node][:custom_acc_model].present?
          data[node].update({
            custom_acc_type_id: "Тип ускорителя",
            custom_acc_vendor_id: "Производитель ускорителя",
            custom_acc_core_cnt: "Количество ядер/мультипроцессоров/мультипроцессорных блоков"
          })
          custom_data[node].update({
            custom_acc_type_id: {node => {
              custom_acc_type: "Тип ускорителя",
            }},
            custom_acc_vendor_id: {node => {
              custom_acc_vendor_id: "Производитель ускорителя"
            }}
          })
        end
        if params[node][:acc_only].to_i == 0
          data[node].update({
            cpu_cnt: "Количество процессоров на одном узле",
          })
          if not params[node][:custom_cpu_from_node].present?
            data[node][:cpu_model_obj_id] = "Модель процессора"
            custom_data[node].update({
              cpu_model_obj_id: {node => {
                custom_cpu_model: "Модель процессора"
              }}
            })
          end
          if not params[node][:cpu_model_obj_id].present? and not params[node][:custom_cpu_from_node].present? and params[node].has_key? :custom_cpu_model
            data[node].update({
              custom_cpu_vendor_id: "Производитель процессора",
              custom_cpu_model: "Наименование модели процессора",
              custom_cpu_freq: "Тактовая частота процессора",
              custom_cpu_core_cnt: "Количество ядер процессора"
            })
            custom_data[node].update({
              custom_cpu_vendor_id: {node => {
                custom_cpu_vendor: "Производитель процессора"
              }}
            })
          end
        else
          data[node].update({
            acc_cnt: "Количество ускорителей на одном узле",
          })
          if not params[node][:custom_acc_from_node].present?
            data[node][:acc_model_obj_id] = "Модель ускорителя"
            custom_data[node].update({
              acc_model_obj_id: {node => {
                custom_acc_model: "Модель ускорителя"
              }}
            })
          end
          if not params[node][:acc_model_obj_id].present? and not params[node][:custom_acc_from_node].present? and params[node].has_key? :custom_acc_model
            data[node].update({
              custom_acc_type_id: "Тип ускорителя",
              custom_acc_vendor_id: "Производитель ускорителя",
              custom_acc_model: "Наименование модели ускорителя",
              custom_acc_core_cnt: "Количество ядер/мультипроцессоров/мультипроцессорных блоков"
            })
            custom_data[node].update({
              custom_acc_type_id: {node => {
                custom_acc_type: "Тип ускорителя",
              }},
              custom_acc_vendor_id: {node => {
                custom_acc_vendor_id: "Производитель ускорителя"
              }}
            })
          end
        end
      end
    end
    data.keys.each do |k|
      if not params.has_key? k
        next
      end
      if data[k].is_a? Hash
        data[k].keys.each do |k2|
          if not params.fetch(k, {}).fetch(k2, nil).present?
            cd = custom_data.fetch(k, {}).fetch(k2, {})
            check_param(data[k][k2], cd, data_errs)
          end
        end
      else
        if not params.fetch(k, nil).present?
          cd = custom_data.fetch(k, {})
          check_param(data[k], cd, data_errs)
        end
      end
    end
    if data_errs.empty?
      return nil
    else
      return "Не заполнены необходимые поля: " + data_errs.join(", ")
    end
  end

  def get_short_descr(machine)
    descr = ""
    if machine.name.present?
      descr += machine.name + ", "
    end
    vendor = Top50Vendor.find(machine.vendor_ids.first)
    if vendor.present?
      descr += vendor.name + ", "
    end
    org_id = machine.org_id
    parent_rel = Top50Relation.find_by(sec_obj_id: org_id, type_id: get_rel_contain_id)
    if parent_rel.present?
      org_id = parent_rel.prim_obj_id
    end
    org = Top50Organization.find(org_id)
    if org.present?
      descr += org.name
    end
    descr += " ("
    nod_cnt = Top50Relation.where(prim_obj_id: machine.id, type_id: get_rel_contain_id).sum(:sec_obj_qty)
    if nod_cnt > 0
      descr += "узлов: " + nod_cnt.to_s
    end
    rmax_benchid = Top50Benchmark.where(name_eng: "Linpack").first.id
    rmax = Top50BenchmarkResult.where(machine_id: machine.id, benchmark_id: rmax_benchid, is_valid: 1).order(result: :desc).first
    if rmax.present?
      sc = rmax.top50_benchmark.top50_measure_unit.top50_measure_scales.where("scale < ?", rmax.result).order(scale: :desc).first
      if not sc.present?
        sc = rmax.top50_benchmark.top50_measure_unit.top50_measure_scales.order(:scale).first
      end
      if nod_cnt > 0
        descr += ", " 
      end
      descr += "Rmax: " + (rmax.result / sc.scale).to_s + " " + sc.name
    end
    descr += ", ID: " + machine.id.to_s + ")"
    return descr
  end

  def app_form_new_fail(err_msg)
    flash[:error] = err_msg
    redirect_to top50_machines_app_form_new_url
    return
  end

  def app_form_new
  end

  def app_form_new_post
    flash.delete(:error)
    if not params.has_key? :app_type or not params[:app_type].present?
      app_form_new_fail("Не выбран тип заявки")
      return
    end
    if params[:app_type] == "upgrade" 
      redirect_to top50_machines_app_form_upgrade_url
      return
    else
      redirect_to top50_machines_app_form_step1_url
      return
    end
  end

  def app_form_upgrade_fail(err_msg)
    flash[:error] = err_msg
    app_form_upgrade
    render :app_form_upgrade
    return
  end

  def app_form_upgrade
    @cur_data = params
    ed_num_attrid = Top50Attribute.where(name_eng: "Edition number").first.id
    ed_date_attrid = Top50Attribute.where(name_eng: "Edition date").first.id
    @top50_slists = get_top50_lists.select("top50_benchmarks.id, 'Редакция №' || encode(an.value, 'escape') || ' (' || encode(ad.value, 'escape') || ')' as descr").
      joins("join top50_attribute_val_dbvals an on an.obj_id = top50_benchmarks.id").
      joins("join top50_attribute_val_dbvals ad on ad.obj_id = top50_benchmarks.id").
      where("an.attr_id = ? and ad.attr_id = ?", ed_num_attrid, ed_date_attrid).
      order("cast(encode(an.value, 'escape') as int) desc")
    if get_cur(:list_id).present?
      @top50_machines = []
      top50_machines_pre = Top50BenchmarkResult.select("top50_machines.*, top50_benchmark_results.result").
      joins("join top50_machines on top50_machines.id = top50_benchmark_results.machine_id").
      where("top50_benchmark_results.benchmark_id = ?", get_cur(:list_id))
      top50_machines_pre.each do |machine|
        descr = machine.result.to_i.to_s + ": " + get_short_descr(machine)
        @top50_machines.append([descr, machine.id])
      end
    end
  end

  def app_form_upgrade_post
    flash.delete(:error)
    case params[:commit]
    when "Получить список систем для выбранной редакции"
      if not params[:list_id].present?
        app_form_upgrade_fail("Не указана редакция рейтинга, в которой присутствовала система!")
        return
      end
      app_form_upgrade
      @focus_fields = {[:form, :machine_id] => true}
      render :app_form_upgrade
    when "Далее"
      if not params[:machine_id].present?
        app_form_upgrade_fail("Не указана вычислительная система, по которой обновляются данные")
        return
      end
      app_form_step1

      top50_machine = Top50Machine.find(params[:machine_id])
      @step1_data = ActionController::Parameters.new({
        sym: :step1_data,
        prev_machine_id: params[:machine_id],
        vendor_id: top50_machine.vendor_ids.first,
        vendor_ids: top50_machine.vendor_ids.drop(1).uniq,
        name: top50_machine.name,
        name_eng: top50_machine.name_eng,
        installation_date: top50_machine.installation_date.year,
        website: top50_machine.website,
        type_id: top50_machine.type_id
      })
      parent_rel = Top50Relation.find_by(sec_obj_id: top50_machine.org_id, type_id: get_rel_contain_id)
      if parent_rel.present?
        org_id = parent_rel.prim_obj_id
        @step1_data[:suborg_id] = top50_machine.org_id
      else
        org_id = top50_machine.org_id
      end
      @step1_data[:org_id] = org_id

      @step2_data = ActionController::Parameters.new({
        sym: :step2_data
      })
      comp_node_id = Top50ObjectType.where(name_eng: 'Compute node').first.id
      gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first.id
      cop_typeid = Top50ObjectType.where(name_eng: "Coprocessor").first.id
      cpu_typeid = Top50ObjectType.where(name_eng: 'CPU').first.id
      acc_typeid = Top50ObjectType.where(name_eng: "Accelerator").first.id
      acc_all_typeids = Top50ObjectType.where(parent_id: acc_typeid).pluck(:id)
      ram_size_attrid = Top50Attribute.where(name_eng: "RAM size (GB)").first.id

      i = 0
      m_rels = Top50Relation.where(is_valid: 1, prim_obj_id: top50_machine.id, type_id: get_rel_contain_id)
      m_rels.each do |rel|
        node = Top50Object.find(rel.sec_obj_id)
        if not (node.type_id == comp_node_id and node.is_valid == 1)
          next
        end
        i += 1
        node_key = format("top50_node_%d", i)
        @step2_data[node_key] = {
          fake_id: i,
          node_cnt: rel.sec_obj_qty
        }
        ram = Top50AttributeValDbval.find_by(attr_id: ram_size_attrid, obj_id: node.id, is_valid: 1)
        if ram.present?
          @step2_data[node_key][:ram_size] = ram.value
        end
        n_rels = Top50Relation.where(is_valid: 1, prim_obj_id: node.id, type_id: get_rel_contain_id)
        n_rels.each do |rel1|
          comp = Top50Object.find(rel1.sec_obj_id)
          if comp.type_id == cpu_typeid and comp.is_valid == 1
            @step2_data[node_key][:cpu_cnt] = rel1.sec_obj_qty
            @step2_data[node_key][:cpu_model_obj_id] = comp.id
          elsif acc_all_typeids.include? comp.type_id and comp.is_valid == 1
            @step2_data[node_key][:acc_cnt] = rel1.sec_obj_qty
            @step2_data[node_key][:acc_model_obj_id] = comp.id
          end
        end
      end
      @step2_data[:last_fake_id] = i

      @step3_data = ActionController::Parameters.new({
        sym: :step3_data,
        app_area: {},
        nets: {}
      })
      app_area_attrid = Top50Attribute.where(name_eng: "Application area").first.id
      comm_net_attrid = Top50Attribute.where(name_eng: "Communication network").first.id
      comm_fam_attrid = Top50Attribute.where(name_eng: "Communication network family").first.id
      tplg_attrid = Top50Attribute.where(name_eng: "Topology").first.id
      tran_net_attrid = Top50Attribute.where(name_eng: "Transport network").first.id
      serv_net_attrid = Top50Attribute.where(name_eng: "Service network").first.id
      app_area = Top50AttributeValDict.find_by(attr_id: app_area_attrid, obj_id: top50_machine.id, is_valid: 1)
      if app_area.present?
        @step3_data[:app_area][:app_dict_elem_id] = app_area.dict_elem_id
      end
      net_attrs = {
        comm_net_dict_elem_id: comm_net_attrid,
        comm_net_family_id: comm_fam_attrid,
        tplg_dict_elem_id: tplg_attrid,
        tran_net_dict_elem_id: tran_net_attrid,
        serv_net_dict_elem_id: serv_net_attrid
      }
      net_attrs.each do |k, v|
        attr_val = Top50AttributeValDict.find_by(attr_id: v, obj_id: top50_machine.id, is_valid: 1)
        if attr_val.present?
          @step3_data[:nets][k] = attr_val.dict_elem_id
        end
      end

      @step4_data = ActionController::Parameters.new({
        sym: :step4_data,
        top50_perf: {}
      })
      rmax_benchid = Top50Benchmark.where(name_eng: "Linpack").first.id
      nmax_attrid = Top50Attribute.where(name_eng: "Linpack Nmax").first.id
      linpack_out_attrid = Top50Attribute.where(name_eng: "Linpack Output").first.id
      rpeak_attrid = Top50Attribute.where(name_eng: "Rpeak (MFlop/s)").first.id
      rpeak = Top50AttributeValDbval.find_by(attr_id: rpeak_attrid, obj_id: top50_machine.id, is_valid: 1)
      if rpeak.present?
        @step4_data[:top50_perf][:rpeak] = rpeak.value.to_f / 1000000.0
      end
      rmax = Top50BenchmarkResult.find_by(benchmark_id: rmax_benchid, machine_id: top50_machine.id, is_valid: 1)
      if rmax.present?
        @step4_data[:top50_perf][:rmax] = rmax.result / 1000000.0
        nmax = Top50AttributeValDbval.find_by(attr_id: nmax_attrid, obj_id: rmax.id, is_valid: 1)
        if nmax.present?
          @step4_data[:top50_perf][:msize] = nmax.value.to_i
        end
        linpack_out = Top50AttributeValDbval.find_by(attr_id: linpack_out_attrid, obj_id: rmax.id, is_valid: 1)
        if linpack_out.present?
          @step4_data[:top50_perf][:linpack_output] = linpack_out.value
        end
      end
      @cur_data = @step1_data

      render :app_form_step1
      return
    when "Назад"
      redirect_to top50_machines_app_form_new_url
      return
    end
  end

  def app_form_step1
    @rel_contain_id = get_rel_contain_id
    fetch_all_data_from_params
    @cur_data = @step1_data
  end
 
  def app_form_step1_presave
    flash.delete(:error)
    case params[:commit]
    when "Добавить производителя"
      app_form_step1
      @cur_data[:custom_vendor] = {}
      @cur_data[:vendor_id] = nil
      @focus_fields = {[:custom_vendor, :name] => true}
      render :app_form_step1
    when "Добавить ещё одного участвующего производителя"
      app_form_step1
      @cur_data[format("add_vendor_%d", @cur_data[:add_vendors_cnt].to_i + 1)] = {}
      @focus_fields = {[format("add_vendor_%d", @cur_data[:add_vendors_cnt].to_i + 1), :name] => true}
      render :app_form_step1
    when "Добавить новый тип"
      app_form_step1
      @cur_data[:custom_type] = {}
      @cur_data[:type_id] = nil
      @focus_fields = {[:custom_type, :name] => true}
      render :app_form_step1
    when "Добавить организацию"
      app_form_step1
      @cur_data[:custom_org] = {}
      @cur_data[:org_id] = nil
      @focus_fields = {[:custom_org, :name] => true}
      render :app_form_step1
    when "Добавить новое подразделение"
      app_form_step1
      @cur_data[:custom_suborg] = {}
      @cur_data[:suborg_id] = nil
      @focus_fields = {[:custom_suborg, :name] => true}
      render :app_form_step1
    when "Указать подразделение"
      if not params[:org_id].present? and not params.has_key? :custom_org
        @focus_fields = {[:form, :org_id] => true}
        app_form_step1_fail("Для указания подазделения необходимо сначала указать организацию")
        return
      end
      app_form_step1
      @cur_data[:suborg_id] = nil
      @focus_fields = {[:form, :suborg_id] => true}
      if params.has_key? :custom_org and not params[:org_id].present?
        @cur_data[:custom_suborg] = {}
        @focus_fields = {[:custom_suborg, :name] => true}
      end
      render :app_form_step1
    when "Далее"
      x = validate_req_params(:step1)
      if x.present?
        app_form_step1_fail(x)
        return
      end
      if params[:cond_accepted].to_i != 1
        app_form_step1_fail("Для подачи заявки необходимо подтвердить согласие на обработку данных.")
        return
      end
      app_form_step2
      render :app_form_step2
    else
      app_form_step1
      @cur_data.reject! {|k,v| v.is_a? Hash and v.fetch(:commit, "").starts_with? "Убрать"}
      render :app_form_step1
    end
    return
  end

  def app_form_step1_fail(err_msg)
    flash[:error] = err_msg
    app_form_step1
    render :app_form_step1
    return
  end

  def app_form_step2
    @rel_contain_id = get_rel_contain_id
    @cpu_typeid = Top50ObjectType.where(name_eng: 'CPU').first.id
    @cpu_dict_id = Top50Dictionary.where(name_eng: 'CPU model').first.id
    @cpu_vendor_dict_id = Top50Dictionary.where(name_eng: 'CPU Vendor').first.id
    @cpu_gen_dict_id = Top50Dictionary.where(name_eng: 'CPU generations').first.id
    @cpu_family_dict_id = Top50Dictionary.where(name_eng: 'CPU families').first.id
    @gpu_dict_id = Top50Dictionary.where(name_eng: 'GPU model').first.id
    @gpu_vendor_dict_id = Top50Dictionary.where(name_eng: 'GPU Vendor').first.id
    @cop_dict_id = Top50Dictionary.where(name_eng: 'Coprocessor model').first.id
    @cop_vendor_dict_id = Top50Dictionary.where(name_eng: 'Coprocessor Vendor').first.id
    @acc_dict_id = [@gpu_dict_id, @cop_dict_id]
    @acc_vendor_dict_id = [@cop_vendor_dict_id, @gpu_vendor_dict_id]
    @acc_typeid = Top50ObjectType.where(name_eng: "Accelerator").first.id
    @acc_all_typeids = Top50ObjectType.where(parent_id: @acc_typeid).pluck(:id)

    cpu_model_attrid = Top50Attribute.where(name_eng: "CPU model").first.id
    cpu_vendor_attrid = Top50Attribute.where(name_eng: "CPU Vendor").first.id
    @cpu_objects = Top50Object.select("top50_objects.id, dv.name || ' ' || dm.name as name").
      joins("join top50_attribute_val_dicts av on av.obj_id = top50_objects.id and av.attr_id = #{cpu_vendor_attrid}").
      joins("join top50_dictionary_elems dv on dv.id = av.dict_elem_id and dv.dict_id = #{@cpu_vendor_dict_id}").
      joins("join top50_attribute_val_dicts am on am.obj_id = top50_objects.id and am.attr_id = #{cpu_model_attrid}").
      joins("join top50_dictionary_elems dm on dm.id = am.dict_elem_id and dm.dict_id = #{@cpu_dict_id}").
      where("top50_objects.type_id = ? and top50_objects.is_valid = 1", @cpu_typeid).
      order("dv.name, dm.name")
  
    gpu_model_attrid = Top50Attribute.where(name_eng: "GPU model").first.id
    gpu_vendor_attrid = Top50Attribute.where(name_eng: "GPU Vendor").first.id
    cop_model_attrid = Top50Attribute.where(name_eng: "Coprocessor model").first.id
    cop_vendor_attrid = Top50Attribute.where(name_eng: "Coprocessor Vendor").first.id
    @acc_objects = Top50Object.select("top50_objects.id, dv.name || ' ' || dm.name as name").
      joins("join top50_attribute_val_dicts av on av.obj_id = top50_objects.id").
      joins("join top50_dictionary_elems dv on dv.id = av.dict_elem_id").
      joins("join top50_attribute_val_dicts am on am.obj_id = top50_objects.id").
      joins("join top50_dictionary_elems dm on dm.id = am.dict_elem_id").
      where("top50_objects.type_id in (?) and top50_objects.is_valid = 1 and av.attr_id in (?) and dv.dict_id in (?) and am.attr_id in (?) and dm.dict_id in (?)",
        @acc_all_typeids, [gpu_vendor_attrid, cop_vendor_attrid], @acc_vendor_dict_id, [gpu_model_attrid, cop_model_attrid], @acc_dict_id).
      order("dv.name, dm.name")

    fetch_all_data_from_params
    @cur_data = @step2_data
    @custom_cpus = []
    @custom_accs = []
    @cur_data.select {|k,v| k.starts_with? 'top50_node_'}.values.each do |node|
      if node[:custom_cpu_model].present?
        if node[:custom_cpu_vendor_id].present?
          cpu_ven_str = Top50DictionaryElem.find(node[:custom_cpu_vendor_id].to_i).name
        else
          cpu_ven_str = node[:custom_cpu_vendor]
        end
        @custom_cpus.append([format("%s %s", cpu_ven_str, node[:custom_cpu_model]), node[:fake_id]])
      end
      if node[:custom_acc_model].present?
        if node[:custom_acc_vendor_id].present?
          acc_ven_str = Top50DictionaryElem.find(node[:custom_acc_vendor_id].to_i).name
        else
          acc_ven_str = node[:custom_acc_vendor]
        end
        @custom_accs.append([format("%s %s", acc_ven_str, node[:custom_acc_model]), node[:fake_id]])
      end
    end
  end
 
  def app_form_step2_presave
    flash.delete(:error)
    case params[:commit]
    when "Добавить группу узлов"
      app_form_step2
      fake_id = @cur_data[:last_fake_id].to_i + 1
      @cur_data[format("top50_node_%d", fake_id)] = {
        fake_id: fake_id
      }
      @cur_data[:last_fake_id] = fake_id
      @focus_fields = {[format("top50_node_%d", fake_id), :node_cnt] => true}
      render :app_form_step2
    when "Назад"
      app_form_step1
      render :app_form_step1
    when "Далее"
      x = validate_req_params(:step2)
      if x.present?
        app_form_step2_fail(x)
        return
      end
      app_form_step3
      render :app_form_step3
    else
      params.reject! {|k,v| v.is_a? Hash and v.fetch(:commit, "").starts_with? "Удалить"}
      app_form_step2
      @cur_data.select {|k,v| k.starts_with? 'top50_node_'}.keys.sort.each do |node|
        case @cur_data[node].fetch(:commit, nil)
        when "Добавить модель процессора"
          @cur_data[node][:custom_cpu_model] = nil
          @cur_data[node][:cpu_model_obj_id] = nil
          @focus_fields = {[node, :custom_cpu_model] => true}
        when "Добавить модель ускорителя"
          @cur_data[node][:custom_acc_model] = nil
          @cur_data[node][:acc_model_obj_id] = nil
          @focus_fields = {[node, :custom_acc_model] => true}
        end
      end
      render :app_form_step2
    end
    return
  end
 
  def app_form_step2_fail(err_msg)
    flash[:error] = err_msg
    app_form_step2
    render :app_form_step2
    return
  end

  def app_form_step3
    @app_dict_id = Top50Dictionary.where(name_eng: 'Application areas').first.id
    @net_dict_id = Top50Dictionary.where(name_eng: 'Computer networks').first.id
    @net_fam_dict_id = Top50Dictionary.where(name_eng: 'Net families').first.id
    @tplg_dict_id = Top50Dictionary.where(name_eng: 'Topologies').first.id
    @rel_contain_id = get_rel_contain_id
    fetch_all_data_from_params
    @cur_data = @step3_data
  end

  def app_form_step3_presave
    flash.delete(:error)
    case params[:commit]
    when "Назад"
      app_form_step2
      render :app_form_step2
    when "Далее"
      x = validate_req_params(:step3)
      if x.present?
        app_form_step3_fail(x)
        return
      end
      app_form_step4
      render :app_form_step4
    end
    return
  end

  def app_form_step3_fail(err_msg)
    flash[:error] = err_msg
    app_form_step3
    render :app_form_step3
    return
  end

  def app_form_step4
    fetch_all_data_from_params
    @cur_data = @step4_data
  end

  def app_form_step4_presave
    flash.delete(:error)
    case params[:commit]
    when "Назад"
      app_form_step3
      render :app_form_step3
    when "Далее"
      x = validate_req_params(:step4)
      if x.present?
        app_form_step4_fail(x)
        return
      end
      app_form_confirm
      render :app_form_confirm
    end
    return
  end

  def app_form_step4_fail(err_msg)
    flash[:error] = err_msg
    app_form_step4
    render :app_form_step4
    return
  end

  def app_form_confirm
    core_qty_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Number of cores"))
    @core_qty_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(core_qty_attrs)
    microcore_qty_attrs = Top50AttributeDbval.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "Number of micro cores"))
    @microcore_qty_attr_vals = Top50AttributeValDbval.all.joins(:top50_attribute_dbval).merge(microcore_qty_attrs)
    cpu_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "CPU model"))
    @cpu_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cpu_model_attrs)
    cpu_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where(name_eng: "CPU Vendor"))
    @cpu_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(cpu_vendor_attrs)
    comp_model_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where("name_eng LIKE '% model'"))
    @comp_model_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(comp_model_attrs)
    comp_vendor_attrs = Top50AttributeDict.all.joins(:top50_attribute).merge(Top50Attribute.where("name_eng LIKE '% Vendor'"))
    @comp_vendor_attr_vals = Top50AttributeValDict.all.joins(:top50_attribute_dict).merge(comp_vendor_attrs)

    fetch_all_data_from_params
    if @step1_data[:prev_machine_id].present?
      @prev_machine_descr = get_short_descr(Top50Machine.find(@step1_data[:prev_machine_id].to_i))
    end
  end
 
  def app_form_confirm_post
    flash.delete(:error)
    case params[:commit]
    when "Назад"
      app_form_step4
      render :app_form_step4
    when "Перейти в начало"
      app_form_step1
      render :app_form_step1
    when "Отправить заявку"
      x = validate_req_params(:confirm)
      if x.present?
        app_form_confirm_fail(x)
        return
      end
      app_form_finish 
      render :app_form_finish
    end
    return
  end
 
 def app_form_confirm_fail(err_msg)
    flash[:error] = err_msg
    app_form_confirm
    render :app_form_confirm
    return
  end

  def app_form_finish
    fetch_all_data_from_params
    if @step1_data[:vendor_id].present?
      vendor_id = @step1_data[:vendor_id].to_i
    else
      vendor_id = Top50Vendor.create(
        name: @step1_data[:custom_vendor][:name],
        name_eng: @step1_data[:custom_vendor][:name_eng],
        website: @step1_data[:custom_vendor][:website],
        is_valid: 2
      ).id
    end
    vendor_ids = @step1_data[:vendor_ids].clone
    vendor_ids.delete("")
    vendor_ids.collect! {|x| x.to_i}
    vendor_ids = ([vendor_id] + vendor_ids).uniq
    (@step1_data.select {|k,v| k.starts_with? 'add_vendor_'}).keys.each do |vendor|
      vendor_ids.append(Top50Vendor.create(
        name: @step1_data[vendor][:name],
        name_eng: @step1_data[vendor][:name_eng],
        website: @step1_data[vendor][:website],
        is_valid: 2
      ).id)
    end
    if @step1_data[:org_id].present?
      first_org_id = @step1_data[:org_id].to_i
    else
      city = Top50City.find_by(name: @step1_data[:custom_org][:city])
      if city.present?
        city_id = city.id
      else
        city_id = Top50City.create(
          name: @step1_data[:custom_org][:city],
          is_valid: 2,
          comment: @step1_data[:custom_org][:country]
        ).id
      end
      first_org_id = Top50Organization.create(
        name: @step1_data[:custom_org][:name],
        name_eng: @step1_data[:custom_org][:name_eng],
        city_id: city_id,
        is_valid: 2
      ).id
    end
    if @step1_data[:suborg_id].present?
      org_id = @step1_data[:suborg_id].to_i
    elsif @step1_data[:custom_suborg].present?
      city = Top50City.find_by(name: @step1_data[:custom_suborg][:city])
      if city.present?
        city_id = city.id
      else
         city_id = Top50City.create(
          name: @step1_data[:custom_suborg][:city],
          is_valid: 2,
          comment: @step1_data[:custom_suborg][:country]
        ).id
      end
      org_id = Top50Organization.create(
        name: @step1_data[:custom_suborg][:name],
        name_eng: @step1_data[:custom_suborg][:name_eng],
        city_id: city_id,
        is_valid: 2
      ).id
      Top50Relation.create(
        prim_obj_id: first_org_id,
        sec_obj_id: org_id,
        type_id: get_rel_contain_id,
        is_valid: 2,
        comment: format("%d is parent org for %d", first_org_id, org_id)
      )
    else
      org_id = first_org_id
    end
    if @step1_data[:type_id].present?
      type_id = @step1_data[:type_id].to_i
    else
      type_id = Top50MachineType.create(
        name: @step1_data[:custom_type][:name],
        name_eng: @step1_data[:custom_type][:name_eng],
        is_valid: 2
      ).id
    end
    contact_id = Top50Contact.create(
      name: @step1_data[:contact][:name],
      surname: @step1_data[:contact][:surname],
      patronymic: @step1_data[:contact][:patronymic],
      phone: @step1_data[:contact][:phone],
      email: @step1_data[:contact][:email],
      extra_info: @step1_data[:contact][:extra_info],
      is_valid: 2
    ).id
    @top50_machine = Top50Machine.create(
      name: @step1_data[:name],
      name_eng: @step1_data[:name_eng],
      website: @step1_data[:website],
      installation_date: Date.parse(format("%s-01-01", @step1_data[:installation_date])),
      vendor_id: vendor_id,
      vendor_ids: vendor_ids,
      org_id: org_id,
      type_id: type_id,
      contact_id: contact_id,
      is_valid: 2,
      comment: format('{"step2": "%s", "step3": "%s", "step4": "%s"}', @step2_data[:comment], @step4_data[:comment], @step4_data[:comment])
    )
    if @step1_data[:prev_machine_id].present?
      Top50Relation.create(
        prim_obj_id: @step1_data[:prev_machine_id].to_i,
        sec_obj_id: @top50_machine.id,
        type_id: get_rel_precede_id,
        is_valid: 2,
        comment: format("%s is precedent machine for %d", @step1_data[:prev_machine_id], @top50_machine.id)
      )
    end

    gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first.id
    cop_typeid = Top50ObjectType.where(name_eng: "Coprocessor").first.id
    comp_node_id = Top50ObjectType.where(name_eng: 'Compute node').first.id
    cpu_typeid = Top50ObjectType.where(name_eng: 'CPU').first.id
    acc_parent_type_id = Top50ObjectType.where(name_eng: 'Accelerator').first.id

    cpu_dict_id = Top50Dictionary.where(name_eng: 'CPU model').first.id
    cpu_vendor_dict_id = Top50Dictionary.where(name_eng: 'CPU Vendor').first.id
    cpu_gen_dict_id = Top50Dictionary.where(name_eng: 'CPU generations').first.id
    cpu_fam_dict_id = Top50Dictionary.where(name_eng: 'CPU families').first.id
    gpu_dict_id = Top50Dictionary.where(name_eng: 'GPU model').first.id
    gpu_vendor_dict_id = Top50Dictionary.where(name_eng: 'GPU Vendor').first.id
    cop_dict_id = Top50Dictionary.where(name_eng: 'Coprocessor model').first.id
    cop_vendor_dict_id = Top50Dictionary.where(name_eng: 'Coprocessor Vendor').first.id
    acc_dict_id = Top50Dictionary.where(name_eng: 'Accelerator model').first.id
    acc_vendor_dict_id = Top50Dictionary.where(name_eng: 'Accelerator Vendor').first.id

    freq_attrid = Top50Attribute.where(name_eng: "Clock frequency (MHz)").first.id
    cores_attrid = Top50Attribute.where(name_eng: "Number of cores").first.id
    microcores_attrid = Top50Attribute.where(name_eng: "Number of micro cores").first.id
    cpu_model_attrid = Top50Attribute.where(name_eng: "CPU model").first.id
    cpu_vendor_attrid = Top50Attribute.where(name_eng: "CPU Vendor").first.id
    cpu_fam_attrid = Top50Attribute.where(name_eng: "CPU family").first.id
    cpu_gen_attrid = Top50Attribute.where(name_eng: "CPU generation").first.id
    gpu_model_attrid = Top50Attribute.where(name_eng: "GPU model").first.id
    gpu_vendor_attrid = Top50Attribute.where(name_eng: "GPU Vendor").first.id
    cop_model_attrid = Top50Attribute.where(name_eng: "Coprocessor model").first.id
    cop_vendor_attrid = Top50Attribute.where(name_eng: "Coprocessor Vendor").first.id
    acc_model_attrid = Top50Attribute.where(name_eng: "Accelerator model").first.id
    acc_vendor_attrid = Top50Attribute.where(name_eng: "Accelerator Vendor").first.id
    ram_size_attrid = Top50Attribute.where(name_eng: "RAM size (GB)").first.id
    
    custom_cpu_objects = {}
    custom_acc_objects = {}
    @step2_data.select {|k,v| k.starts_with? 'top50_node_'}.values.each do |top50_node|
      node_id = Top50Object.create(
        type_id: comp_node_id,
        is_valid: 2,
        comment: format("belongs to machine %d", @top50_machine.id)
      ).id
      Top50Relation.create(
        prim_obj_id: @top50_machine.id,
        sec_obj_id: node_id,
        type_id: get_rel_contain_id,
        sec_obj_qty: top50_node[:node_cnt],
        is_valid: 2
      )
      if top50_node[:cpu_model_obj_id].present? or top50_node[:custom_cpu_from_node].present? or top50_node[:custom_cpu_model].present?
        if top50_node[:cpu_model_obj_id].present?
          cpu_obj_id = top50_node[:cpu_model_obj_id].to_i
        else
          if top50_node[:custom_cpu_from_node].present?
            cpu_src_node = @step2_data[format('top50_node_%s', top50_node[:custom_cpu_from_node])]
          else
            cpu_src_node = top50_node
          end
          if custom_cpu_objects.has_key? cpu_src_node[:fake_id]
            cpu_obj_id = custom_cpu_objects[cpu_src_node[:fake_id]]
          else
            cpu_obj_id = Top50Object.create(
              type_id: cpu_typeid,
              is_valid: 2,
              comment: format("new CPU for machine %d", @top50_machine.id)
            ).id
            custom_cpu_objects[cpu_src_node[:fake_id]] = cpu_obj_id
            if cpu_src_node[:custom_cpu_vendor_id].present? or cpu_src_node[:custom_cpu_vendor].present?
              if cpu_src_node[:custom_cpu_vendor_id].present?
                cpu_vendor_dict_elem_id = cpu_src_node[:custom_cpu_vendor_id].to_i
              else
                cpu_vendor_dict_elem_id = Top50DictionaryElem.create(
                  name: cpu_src_node[:custom_cpu_vendor], 
                  dict_id: cpu_vendor_dict_id,
                  is_valid: 2,
                  comment: format("new cpu vendor for machine %d", @top50_machine.id)
                ).id
              end
              Top50AttributeValDict.create(
                attr_id: cpu_vendor_attrid,
                obj_id: cpu_obj_id,
                dict_elem_id: cpu_vendor_dict_elem_id,
                is_valid: 2,
                comment: format("cpu vendor for machine %d", @top50_machine.id)
              )
            end
            if cpu_src_node[:custom_cpu_gen_id].present? or cpu_src_node[:custom_cpu_gen].present?
              if cpu_src_node[:custom_cpu_gen_id].present?
                cpu_gen_dict_elem_id = cpu_src_node[:custom_cpu_gen_id].to_i
              else
                cpu_gen_dict_elem_id = Top50DictionaryElem.create(
                  name: cpu_src_node[:custom_cpu_gen], 
                  dict_id: cpu_gen_dict_id,
                  is_valid: 2,
                  comment: format("new cpu generation for machine %d", @top50_machine.id)
                ).id
              end
              Top50AttributeValDict.create(
                attr_id: cpu_gen_attrid,
                obj_id: cpu_obj_id,
                dict_elem_id: cpu_gen_dict_elem_id,
                is_valid: 2,
                comment: format("cpu generation for machine %d", @top50_machine.id)
              )
            end
            if cpu_src_node[:custom_cpu_family_id].present? or cpu_src_node[:custom_cpu_family].present?
              if cpu_src_node[:custom_cpu_family_id].present?
                cpu_fam_dict_elem_id = cpu_src_node[:custom_cpu_family_id].to_i
              else
                cpu_fam_dict_elem_id = Top50DictionaryElem.create(
                  name: cpu_src_node[:custom_cpu_family],
                  dict_id: cpu_fam_dict_id,
                  is_valid: 2,
                  comment: format("new cpu family for machine %d", @top50_machine.id)
                ).id
              end
              Top50AttributeValDict.create(
                attr_id: cpu_fam_attrid,
                obj_id: cpu_obj_id,
                dict_elem_id: cpu_fam_dict_elem_id,
                is_valid: 2,
                comment: format("cpu family for machine %d", @top50_machine.id)
              )
            end
            cpu_model_dict_elem_id = Top50DictionaryElem.create(
              name: cpu_src_node[:custom_cpu_model],
              dict_id: cpu_dict_id,
              is_valid: 2,
              comment: format("new cpu model for machine %d", @top50_machine.id)
            ).id
            Top50AttributeValDict.create(
              attr_id: cpu_model_attrid,
              obj_id: cpu_obj_id,
              dict_elem_id: cpu_model_dict_elem_id,
              is_valid: 2,
              comment: format("cpu model for machine %d", @top50_machine.id)
            )
            if cpu_src_node[:custom_cpu_freq].present?
              Top50AttributeValDbval.create(
                attr_id: freq_attrid,
                obj_id: cpu_obj_id,
                value: cpu_src_node[:custom_cpu_freq],
                is_valid: 2,
                comment: format("cpu frequency for machine %d", @top50_machine.id)
              )
            end
            if cpu_src_node[:custom_cpu_core_cnt].present?
              Top50AttributeValDbval.create(
                attr_id: cores_attrid,
                obj_id: cpu_obj_id,
                value: cpu_src_node[:custom_cpu_core_cnt],
                is_valid: 2,
                comment: format("cpu cores for machine %d", @top50_machine.id)
              )
            end
          end
        end
        Top50Relation.create(
          prim_obj_id: node_id,
          sec_obj_id: cpu_obj_id,
          type_id: get_rel_contain_id,
          sec_obj_qty: top50_node[:cpu_cnt],
          is_valid: 2
        )
      end
      if top50_node[:acc_model_obj_id].present? or top50_node[:custom_acc_from_node].present? or top50_node[:custom_acc_model].present?
        if top50_node[:acc_model_obj_id].present?
          acc_obj_id = top50_node[:acc_model_obj_id].to_i
        else
          if top50_node[:custom_acc_from_node].present?
            acc_src_node = @step2_data[format('top50_node_%s', top50_node[:custom_acc_from_node])]
          else
            acc_src_node = top50_node
          end
          if custom_acc_objects.has_key? acc_src_node[:fake_id]
            acc_obj_id = custom_acc_objects[acc_src_node[:fake_id]]
          else
            if acc_src_node[:custom_acc_type_id].present?
              type_id = acc_src_node[:custom_acc_type_id].to_i
            else
              type_id = Top50ObjectType.create(
                name: acc_src_node[:custom_acc_type],
                parent_id: acc_parent_type_id,
                is_valid: 2
              ).id
            end
            acc_obj_id = Top50Object.create(
              type_id: type_id,
              is_valid: 2,
              comment: format("new acc for machine %d", @top50_machine.id)
            ).id
            custom_acc_objects[acc_src_node[:fake_id]] = acc_obj_id
            case type_id
            when gpu_typeid
              cur_acc_dict_id = gpu_dict_id
              cur_acc_vendor_dict_id = gpu_vendor_dict_id
              cur_acc_model_attrid = gpu_model_attrid
              cur_acc_vendor_attrid = gpu_vendor_attrid
            when cop_typeid
              cur_acc_dict_id = cop_dict_id
              cur_acc_vendor_dict_id = cop_vendor_dict_id
              cur_acc_model_attrid = cop_model_attrid
              cur_acc_vendor_attrid = cop_vendor_attrid
            else
              cur_acc_dict_id = acc_dict_id
              cur_acc_vendor_dict_id = acc_vendor_dict_id
              cur_acc_model_attrid = acc_model_attrid
              cur_acc_vendor_attrid = acc_vendor_attrid
            end
            if acc_src_node[:custom_acc_vendor_id].present? or acc_src_node[:custom_acc_vendor].present?
              if acc_src_node[:custom_acc_vendor_id].present?
                acc_vendor_dict_elem_id = acc_src_node[:custom_acc_vendor_id].to_i
              else
                acc_vendor_dict_elem_id = Top50DictionaryElem.create(
                  name: acc_src_node[:custom_acc_vendor],
                  dict_id: cur_acc_vendor_dict_id,
                  is_valid: 2,
                  comment: format("new acc vendor for machine %d", @top50_machine.id)
                ).id
              end
              Top50AttributeValDict.create(
                attr_id: cur_acc_vendor_attrid,
                obj_id: acc_obj_id,
                dict_elem_id: acc_vendor_dict_elem_id,
                is_valid: 2,
                comment: format("acc vendor for machine %d", @top50_machine.id)
              )
            end
            acc_model_dict_elem_id = Top50DictionaryElem.create(
              name: acc_src_node[:custom_acc_model],
              dict_id: cur_acc_dict_id,
              is_valid: 2,
              comment: format("new acc model for machine %d", @top50_machine.id)
            ).id
            Top50AttributeValDict.create(
              attr_id: cur_acc_model_attrid,
              obj_id: acc_obj_id,
              dict_elem_id: acc_model_dict_elem_id,
              is_valid: 2,
              comment: format("acc model for machine %d", @top50_machine.id)
            )
            if acc_src_node[:custom_acc_freq].present?
              Top50AttributeValDbval.create(
                attr_id: freq_attrid,
                obj_id: acc_obj_id,
                value: acc_src_node[:custom_acc_freq],
                is_valid: 2,
                comment: format("acc frequency for machine %d", @top50_machine.id)
              )
            end
            if acc_src_node[:custom_acc_core_cnt].present?
              Top50AttributeValDbval.create(
                attr_id: cores_attrid,
                obj_id: acc_obj_id,
                value: acc_src_node[:custom_acc_core_cnt],
                is_valid: 2,
                comment: format("acc cores for machine %d", @top50_machine.id)
              )
            end
            if acc_src_node[:custom_acc_microcore_cnt].present?
              Top50AttributeValDbval.create(
                attr_id: microcores_attrid,
                obj_id: acc_obj_id,
                value: acc_src_node[:custom_acc_microcore_cnt],
                is_valid: 2,
                comment: format("acc micro cores for machine %d", @top50_machine.id)
              )
            end
          end
        end
        Top50Relation.create(
          prim_obj_id: node_id,
          sec_obj_id: acc_obj_id,
          type_id: get_rel_contain_id,
          sec_obj_qty: top50_node[:acc_cnt],
          is_valid: 2
        )
      end
      Top50AttributeValDbval.create(
        attr_id: ram_size_attrid,
        obj_id: node_id,
        value: top50_node[:ram_size],
        is_valid: 2,
        comment: format("RAM size for machine %d", @top50_machine.id)
      )
    end
    app_dict_id = Top50Dictionary.where(name_eng: 'Application areas').first.id
    net_dict_id = Top50Dictionary.where(name_eng: 'Computer networks').first.id
    net_fam_dict_id = Top50Dictionary.where(name_eng: 'Net families').first.id
    tplg_dict_id = Top50Dictionary.where(name_eng: 'Topologies').first.id
    app_area_attrid = Top50Attribute.where(name_eng: "Application area").first.id
    comm_net_attrid = Top50Attribute.where(name_eng: "Communication network").first.id
    comm_fam_attrid = Top50Attribute.where(name_eng: "Communication network family").first.id
    serv_net_attrid = Top50Attribute.where(name_eng: "Service network").first.id
    tran_net_attrid = Top50Attribute.where(name_eng: "Transport network").first.id
    tplg_attrid = Top50Attribute.where(name_eng: "Topology").first.id
    if @step3_data[:app_area][:app_dict_elem_id].present?
      app_dict_elem_id = @step3_data[:app_area][:app_dict_elem_id].to_i
    else
      app_dict_elem_id = Top50DictionaryElem.create(
        name: @step3_data[:app_area][:custom_app],
        dict_id: app_dict_id,
        is_valid: 2,
        comment: format("new app area for machine %s", @top50_machine.id)
      ).id
    end
    Top50AttributeValDict.create(
      attr_id: app_area_attrid,
      obj_id: @top50_machine.id,
      dict_elem_id: app_dict_elem_id,
      is_valid: 2,
      comment: format("app area for machine %d", @top50_machine.id)
    )
    added_nets = {}
    if @step3_data[:nets][:comm_net_dict_elem_id].present?
      comm_net_dict_elem_id = @step3_data[:nets][:comm_net_dict_elem_id].to_i
    else
      comm_net_dict_elem_id = Top50DictionaryElem.create(
        name: @step3_data[:nets][:custom_comm_net],
        dict_id: net_dict_id,
        is_valid: 2,
        comment: format("new comm net for machine %d", @top50_machine.id)
      ).id
      added_nets[@step3_data[:nets][:custom_comm_net]] = comm_net_dict_elem_id
    end
    Top50AttributeValDict.create(
      attr_id: comm_net_attrid,
      obj_id: @top50_machine.id,
      dict_elem_id: comm_net_dict_elem_id,
      is_valid: 2,
      comment: format("comm net for machine %d", @top50_machine.id)
    )
    if @step3_data[:nets][:tran_net_dict_elem_id].present? or @step3_data[:nets][:custom_tran_net].present?
      if @step3_data[:nets][:tran_net_dict_elem_id].present?
        tran_net_dict_elem_id = @step3_data[:nets][:tran_net_dict_elem_id].to_i
      elsif added_nets.has_key? @step3_data[:nets][:custom_tran_net]
        tran_net_dict_elem_id = added_nets[@step3_data[:nets][:custom_tran_net]]
      else
        tran_net_dict_elem_id = Top50DictionaryElem.create(
          name: @step3_data[:nets][:custom_tran_net],
          dict_id: net_dict_id,
          is_valid: 2,
          comment: format("new tran net for machine %d", @top50_machine.id)
        ).id
        added_nets[@step3_data[:nets][:custom_tran_net]] = tran_net_dict_elem_id
      end
      Top50AttributeValDict.create(
        attr_id: tran_net_attrid,
        obj_id: @top50_machine.id,
        dict_elem_id: tran_net_dict_elem_id,
        is_valid: 2,
        comment: format("tran net for machine %d", @top50_machine.id)
      )
    end
    if @step3_data[:nets][:serv_net_dict_elem_id].present? or @step3_data[:nets][:custom_serv_net].present?
      if @step3_data[:nets][:serv_net_dict_elem_id].present?
        serv_net_dict_elem_id = @step3_data[:nets][:serv_net_dict_elem_id].to_i
      elsif added_nets.has_key? @step3_data[:nets][:custom_serv_net]
        serv_net_dict_elem_id = added_nets[@step3_data[:nets][:custom_serv_net]]
      else
        serv_net_dict_elem_id = Top50DictionaryElem.create(
          name: @step3_data[:nets][:custom_serv_net],
          dict_id: net_dict_id,
          is_valid: 2,
          comment: format("new serv net for machine %d", @top50_machine.id)
        ).id
        added_nets[@step3_data[:nets][:custom_serv_net]] = serv_net_dict_elem_id
      end
      Top50AttributeValDict.create(
        attr_id: serv_net_attrid,
        obj_id: @top50_machine.id,
        dict_elem_id: serv_net_dict_elem_id,
        is_valid: 2,
        comment: format("serv net for machine %d", @top50_machine.id)
      )
    end
    if @step3_data[:nets][:tplg_dict_elem_id].present?
      tplg_dict_elem_id = @step3_data[:nets][:tplg_dict_elem_id].to_i
    else
      tplg_dict_elem_id = Top50DictionaryElem.create(
        name: @step3_data[:nets][:custom_tplg],
        dict_id: tplg_dict_id,
        is_valid: 2,
        comment: format("new topology for machine %d", @top50_machine.id)
      ).id
    end
    Top50AttributeValDict.create(
      attr_id: tplg_attrid,
      obj_id: @top50_machine.id,
      dict_elem_id: tplg_dict_elem_id,
      is_valid: 2,
      comment: format("topology for machine %d", @top50_machine.id)
    )
    if @step3_data[:nets][:comm_net_family_id].present? or @step3_data[:nets][:custom_comm_family].present?
      if @step3_data[:nets][:comm_net_family_id].present?
        comm_fam_dict_elem_id = @step3_data[:nets][:comm_net_family_id].to_i
      else
        comm_fam_dict_elem_id = Top50DictionaryElem.create(
          name: @step3_data[:nets][:custom_comm_family],
          dict_id: net_fam_dict_id,
          is_valid: 2,
          comment: format("new comm net family for machine %d", @top50_machine.id)
        ).id
      end
      Top50AttributeValDict.create(
        attr_id: comm_fam_attrid,
        obj_id: @top50_machine.id,
        dict_elem_id: comm_fam_dict_elem_id,
        is_valid: 2,
        comment: format("comm net family for machine %d", @top50_machine.id)
      )
    end
    rmax_benchid = Top50Benchmark.where(name_eng: "Linpack").first.id
    bres_id = Top50BenchmarkResult.create(
      benchmark_id: rmax_benchid,
      machine_id: @top50_machine.id,
      result: @step4_data[:top50_perf][:rmax].to_f * 1000000,
      is_valid: 2,
      comment: format("rmax result for machine %d", @top50_machine.id)
    ).id
    nmax_attrid = Top50Attribute.where(name_eng: "Linpack Nmax").first.id
    Top50AttributeValDbval.create(
      attr_id: nmax_attrid,
      obj_id: bres_id,
      value: @step4_data[:top50_perf][:msize],
      is_valid: 2,
      comment: format("Nmax for machine %d", @top50_machine.id)
    )
    if @step4_data[:top50_perf][:linpack_output].present?
      linpack_out_attrid = Top50Attribute.where(name_eng: "Linpack Output").first.id
      Top50AttributeValDbval.create(
        attr_id: linpack_out_attrid,
        obj_id: bres_id,
        value: @step4_data[:top50_perf][:linpack_output],
        is_valid: 2,
        comment: format("Linpack output for machine %d", @top50_machine.id)
      )
    end
    rpeak_attrid = Top50Attribute.where(name_eng: "Rpeak (MFlop/s)").first.id
    Top50AttributeValDbval.create(
      attr_id: rpeak_attrid,
      obj_id: @top50_machine.id,
      value: (@step4_data[:top50_perf][:rpeak].to_f * 1000000).to_s,
      is_valid: 2,
      comment: format("Rpeak for machine %d", @top50_machine.id)
    )
    Top50Mailer.app_confirm_email({step1_data: @step1_data, step2_data: @step2_data, step3_data: @step3_data, step4_data: @step4_data, id: @top50_machine.id}).deliver!
  end

  ###delishakov### duplicated from ObjectsController

  def show_info
    @top50_object = Top50Object.find(params[:id])
    @first_appearance_date = fetch_first_appearance_date(@top50_object.id)
  end 

  ### delishakov ###
  
  def get_rel_contain_id
    Top50RelationType.find_by(name_eng: 'Contains').id
  end

  def get_name_eng_attr_id
    Top50Attribute.find_by(name_eng: "Name(eng)").id
  end

  def get_bunch_id
    Top50Object.joins("join top50_object_types on top50_object_types.id = top50_objects.type_id and top50_object_types.name_eng = 'Bunch of benchmarks'")
               .joins("join top50_attribute_val_dbvals dbv on dbv.obj_id = top50_objects.id and dbv.attr_id = #{get_name_eng_attr_id} and dbv.value = 'Top50 position'")
               .first.id
  end

  def fetch_first_appearance_date(component_id)
    machine_id = Top50Machine.where("exists(select 1 from top50_relations a join top50_relations b on
                                      b.prim_obj_id = a.sec_obj_id where b.sec_obj_id = #{component_id} and
                                      a.prim_obj_id = top50_machines.id and a.type_id = #{get_rel_contain_id} and
                                      b.type_id = #{get_rel_contain_id})").order(:created_at).first.try(:id)
    return nil unless machine_id

    benchmark = Top50Benchmark.joins("join top50_benchmark_results ed_results on ed_results.machine_id = #{machine_id} and
    ed_results.benchmark_id = top50_benchmarks.id").select('top50_benchmarks.*')
                 .joins("join top50_relations on top50_benchmarks.id = top50_relations.sec_obj_id")
                 .where("top50_relations.prim_obj_id = (?) and top50_relations.type_id = ?", get_bunch_id, get_rel_contain_id)
                 .order(:created_at).first
    benchmark.created_at if benchmark
  end

  ###delishakov### duplicated from ObjectsController

  private
  
  def top50machine_params
    params.require(:top50_machine).permit(:name, :name_eng, :website, :type_id, :org_id, :vendor_id, :vendor_ids, :contact_id, :installation_date, :start_date, :end_date, :is_valid, :comment)
  end

  def top50_benchmark_result_params
    params.require(:top50_benchmark_result).permit(:benchmark_id, :result, :is_valid)
  end
  
  def top50_node_params
    params.require(:top50_relation).permit(:top50_node => [:sec_obj_qty, :is_valid], :top50_cpu => [:model_dict_elem_id, :sec_obj_qty, :is_valid], :top50_acc => [:model_dict_elem_id, :sec_obj_qty, :is_valid], :top50_ram => [:ram_size, :is_valid])
  end
end
