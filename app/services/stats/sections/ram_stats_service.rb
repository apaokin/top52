module Stats
  module Sections
    class RamStatsService < BaseSectionService

      def call
        run_in_context do
          @ram_per_core_data = []
          @ram_per_cpu_data = []
          @ram_per_node_data = []

          calc_machine_attrs
          @ram_size_attrid = Top50Attribute.where(name_eng: "RAM size (GB)").first&.id
          @core_qty_attrid = Top50Attribute.where(name_eng: "Number of cores").first&.id
          @cpu_qty_attrid_ram = Top50Attribute.where(name_eng: "Number of CPUs").first&.id
          @cpu_typeid = Top50ObjectType.where(name_eng: "CPU").first&.id
          @gpu_typeid = Top50ObjectType.where(name_eng: "GPU").first&.id
          @rel_contain_id = get_rel_contain_id

          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)

          precedes_map_lineage_ram = Stats::Lineage.precedes_child_to_parent_map
          all_list_ids_ram = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
          all_machine_ids_ram = all_list_ids_ram.any? ? Top50BenchmarkResult.where(benchmark_id: all_list_ids_ram).pluck(:machine_id).uniq : []
          machine_names_ram = machine_display_name_map_for_ids(all_machine_ids_ram)

          node_rels_by_machine = Hash.new do |h, machine_id|
            h[machine_id] = Top50Relation.where(prim_obj_id: machine_id, type_id: @rel_contain_id).to_a
          end
          comp_rels_by_node = Hash.new do |h, node_id|
            h[node_id] = Top50Relation.where(prim_obj_id: node_id, type_id: @rel_contain_id).to_a
          end
          object_type_by_id = {}
          value_cache = Stats::AttributeValueCache.new

          max_rank_limit = @max_rank || self.class::TOP50_MAX_RANK
          @edition_dates_ram = Array.new(top_50_dates.size)
          top_50_dates.each_with_index do |top50_date, reverse_edition_index|
            list_id = get_list_id_by_date(top50_date[0], top50_date[1])
            list_date = @date_vals.find_by(obj_id: list_id)&.value
            edition = top_50_dates.size - reverse_edition_index
            if list_date.present?
              @edition_dates_ram[edition - 1] = Stats::EditionLabel.from_list_date(list_date)
            end

            ranked_machine_ids_for_list(list_id, max_rank_limit).each_with_index do |machine_id, rank_index|
              rank = rank_index + 1
              total_ram = 0.0
              total_cores = 0
              total_cpus = 0
              total_nodes = 0
              has_gpu = false

              node_rels_by_machine[machine_id].each do |node_rel|
                node_id = node_rel.sec_obj_id
                node_qty = node_rel.sec_obj_qty
                total_nodes += node_qty

                ram_val = value_cache.dbval_for(node_id, @ram_size_attrid)
                if ram_val&.value.present?
                  ram_per_node = ram_val.value.to_f
                  total_ram += node_qty * ram_per_node if ram_per_node > 0
                end

                comp_rels_by_node[node_id].each do |cpu_rel|
                  cpu_id = cpu_rel.sec_obj_id
                  component_type = object_type_by_id[cpu_id]
                  if component_type.nil?
                    obj = Top50Object.find_by(id: cpu_id)
                    component_type = obj&.type_id
                    object_type_by_id[cpu_id] = component_type
                  end

                  if component_type == @cpu_typeid
                    cpu_qty = cpu_rel.sec_obj_qty * node_qty
                    total_cpus += cpu_qty
                    cores_val = value_cache.dbval_for(cpu_id, @core_qty_attrid)
                    if cores_val&.value.present?
                      cores_per_cpu = cores_val.value.to_i
                      total_cores += cpu_qty * cores_per_cpu if cores_per_cpu > 0
                    end
                  elsif component_type == @gpu_typeid
                    has_gpu = true
                  end
                end
              end

              if total_ram == 0 && @ram_size_attrid.present?
                ram_val = value_cache.dbval_for(machine_id, @ram_size_attrid)
                total_ram = ram_val.value.to_f if ram_val&.value.present?
              end
              if total_cpus == 0 && @cpu_qty_attrid_ram.present?
                cpu_qty_val = value_cache.dbval_for(machine_id, @cpu_qty_attrid_ram)
                total_cpus = cpu_qty_val.value.to_i if cpu_qty_val.present?
              end
              if total_cores == 0 && @core_qty_attrid.present?
                core_qty_val = value_cache.dbval_for(machine_id, @core_qty_attrid)
                total_cores = core_qty_val.value.to_i if core_qty_val.present?
              end

              ram_per_core = (total_cores > 0 && total_ram > 0) ? (total_ram / total_cores) : nil
              ram_per_cpu = (total_cpus > 0 && total_ram > 0) ? (total_ram / total_cpus) : nil
              ram_per_node_val = (total_nodes > 0 && total_ram > 0) ? (total_ram / total_nodes) : nil

              machine_name_ram = machine_names_ram[machine_id] || "н/д"
              machine_key_ram = Stats::Lineage.branch_key_machine_id(machine_id, precedes_map_lineage_ram)
              @ram_per_core_data << { edition: edition, rank: rank, lag: ram_per_core, has_gpu: has_gpu, machine_id: machine_id, machine_name: machine_name_ram, machine_key: machine_key_ram }
              @ram_per_cpu_data << { edition: edition, rank: rank, lag: ram_per_cpu, has_gpu: has_gpu, machine_id: machine_id, machine_name: machine_name_ram, machine_key: machine_key_ram }
              @ram_per_node_data << { edition: edition, rank: rank, lag: ram_per_node_val, has_gpu: has_gpu, machine_id: machine_id, machine_name: machine_name_ram, machine_key: machine_key_ram }
            end
          end

          merge_application_area_into_heatmap_rows!(@ram_per_core_data)
          merge_application_area_into_heatmap_rows!(@ram_per_cpu_data)
          merge_application_area_into_heatmap_rows!(@ram_per_node_data)
        end
      end

      private
    end
  end
end
