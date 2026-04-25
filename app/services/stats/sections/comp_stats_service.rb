module Stats
  module Sections
    class CompStatsService < BaseSectionService

      def call
        run_in_context do
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

          calc_machine_attrs
          @cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first&.id
          @gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first&.id
          @core_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first&.id
          @microcore_qty_attrid = Top50Attribute.where(name_eng: "Number of micro cores").first&.id
          @cpu_qty_attrid_comp = Top50Attribute.where(name_eng: "Number of CPUs").first&.id
          @gpu_qty_attrid_comp = Top50Attribute.where(name_eng: "Number of GPUs").first&.id
          @rel_contain_id = get_rel_contain_id

          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)

          precedes_map_lineage_comp = Stats::Lineage.precedes_child_to_parent_map
          all_list_ids_comp = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
          comp_machine_ids = all_list_ids_comp.any? ? Top50BenchmarkResult.where(benchmark_id: all_list_ids_comp).pluck(:machine_id).uniq : []
          machine_names_comp = machine_display_name_map_for_ids(comp_machine_ids)

          node_rels_by_machine = Hash.new do |h, machine_id|
            h[machine_id] = Top50Relation.where(prim_obj_id: machine_id, type_id: @rel_contain_id).to_a
          end
          comp_rels_by_node = Hash.new do |h, node_id|
            h[node_id] = Top50Relation.where(prim_obj_id: node_id, type_id: @rel_contain_id).to_a
          end
          component_type_by_id = {}
          component_info_by_id = {}
          value_cache = Stats::AttributeValueCache.new

          max_rank_limit = @max_rank || self.class::TOP50_MAX_RANK
          @edition_dates_component = Array.new(top_50_dates.size)
          top_50_dates.each_with_index do |top50_date, reverse_edition_index|
            list_id = get_list_id_by_date(top50_date[0], top50_date[1])
            list_date = @date_vals.find_by(obj_id: list_id)&.value
            edition = top_50_dates.size - reverse_edition_index
            if list_date.present?
              @edition_dates_component[edition - 1] = Stats::EditionLabel.from_list_date(list_date)
            end

            ranked_machine_ids_for_list(list_id, max_rank_limit).each_with_index do |machine_id, rank_index|
              rank = rank_index + 1
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

              node_rels_by_machine[machine_id].each do |node_rel|
                node_id = node_rel.sec_obj_id
                node_qty = node_rel.sec_obj_qty
                total_nodes += node_qty

                comp_rels_by_node[node_id].each do |component_rel|
                  component_id = component_rel.sec_obj_id
                  component_type = component_type_by_id[component_id]
                  if component_type.nil?
                    component_obj = Top50Object.find_by(id: component_id)
                    component_type = component_obj&.type_id
                    component_type_by_id[component_id] = component_type
                  end
                  next unless component_type

                  component_qty = component_rel.sec_obj_qty * node_qty

                  if component_type == @cpu_typeid
                    total_cpus += component_qty
                    cores_val = value_cache.dbval_for(component_id, @core_qty_attrid)
                    if cores_val&.value.present?
                      cores_per_cpu = cores_val.value.to_i
                      total_cores += component_qty * cores_per_cpu if cores_per_cpu > 0
                    end

                    component_info = component_info_by_id[component_id]
                    if component_info.nil?
                      component_info = ComponentInfo.find_by(component_id: component_id)
                      component_info_by_id[component_id] = component_info
                    end
                    if component_info&.date_announced && component_info&.date_mentioned && list_date.present?
                      used_date = component_info.date_mentioned < component_info.date_announced ? component_info.date_mentioned : component_info.date_announced
                      diff = (Date.parse(list_date) - used_date).to_i
                      if diff < min_lag
                        min_lag = diff
                        freshest_count = component_qty
                      elsif diff == min_lag
                        freshest_count += component_qty
                      end

                      if diff < min_lag_cpu_only
                        min_lag_cpu_only = diff
                        freshest_cpu_only_count = component_qty
                      elsif diff == min_lag_cpu_only
                        freshest_cpu_only_count += component_qty
                      end
                    end
                  elsif component_type == @gpu_typeid
                    total_gpus += component_qty
                    if @core_qty_attrid.present?
                      cores_val = value_cache.dbval_for(component_id, @core_qty_attrid)
                      if cores_val&.value.present?
                        c = cores_val.value.to_i
                        total_gpu_cores += component_qty * c if c > 0
                      end
                    end
                    if @microcore_qty_attrid.present?
                      microcores_val = value_cache.dbval_for(component_id, @microcore_qty_attrid)
                      if microcores_val&.value.present?
                        mc = microcores_val.value.to_i
                        total_gpu_microcores_only += component_qty * mc if mc > 0
                      end
                    end

                    component_info = component_info_by_id[component_id]
                    if component_info.nil?
                      component_info = ComponentInfo.find_by(component_id: component_id)
                      component_info_by_id[component_id] = component_info
                    end
                    if component_info&.date_announced && component_info&.date_mentioned && list_date.present?
                      used_date = component_info.date_mentioned < component_info.date_announced ? component_info.date_mentioned : component_info.date_announced
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

              if total_cpus == 0 && @cpu_qty_attrid_comp.present?
                cpu_qty_val = value_cache.dbval_for(machine_id, @cpu_qty_attrid_comp)
                total_cpus = cpu_qty_val.value.to_i if cpu_qty_val.present?
              end
              if total_gpus == 0 && @gpu_qty_attrid_comp.present?
                gpu_qty_val = value_cache.dbval_for(machine_id, @gpu_qty_attrid_comp)
                total_gpus = gpu_qty_val.value.to_i if gpu_qty_val.present?
              end
              if total_cores == 0 && @core_qty_attrid.present?
                core_qty_val = value_cache.dbval_for(machine_id, @core_qty_attrid)
                total_cores = core_qty_val.value.to_i if core_qty_val.present?
              end

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
              machine_key_comp = Stats::Lineage.branch_key_machine_id(machine_id, precedes_map_lineage_comp)
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

          merge_application_area_into_heatmap_rows!(@cpu_total_data)
          merge_application_area_into_heatmap_rows!(@cpu_per_node_data)
          merge_application_area_into_heatmap_rows!(@gpu_total_data)
          merge_application_area_into_heatmap_rows!(@gpu_per_node_data)
          merge_application_area_into_heatmap_rows!(@freshest_total_data)
          merge_application_area_into_heatmap_rows!(@freshest_per_node_data)
          merge_application_area_into_heatmap_rows!(@freshest_total_data_cpu_only)
          merge_application_area_into_heatmap_rows!(@freshest_per_node_data_cpu_only)
          merge_application_area_into_heatmap_rows!(@cores_total_data)
          merge_application_area_into_heatmap_rows!(@cores_per_node_data)
          merge_application_area_into_heatmap_rows!(@gpu_cores_total_data)
          merge_application_area_into_heatmap_rows!(@gpu_cores_per_node_data)
          merge_application_area_into_heatmap_rows!(@gpu_microcores_only_total_data)
          merge_application_area_into_heatmap_rows!(@gpu_microcores_only_per_node_data)
        end
      end

      private
    end
  end
end
