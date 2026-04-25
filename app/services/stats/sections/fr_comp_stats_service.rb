module Stats
  module Sections
    class FrCompStatsService < BaseSectionService

      def call
        run_in_context do
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
          @cpu_qty_attrid = Top50Attribute.where(name_eng: "Number of CPUs").first&.id
          @gpu_qty_attrid = Top50Attribute.where(name_eng: "Number of GPUs").first&.id
          @cpu_model_attrid_fq = Top50Attribute.where(name_eng: "CPU model").first&.id
          @gpu_model_attrid_fq = Top50Attribute.where(name_eng: "GPU model").first&.id
          @cpu_vendor_attrid_fq = Top50Attribute.where(name_eng: "CPU Vendor").first&.id
          @gpu_vendor_attrid_fq = Top50Attribute.where(name_eng: "GPU Vendor").first&.id

          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)

          precedes_map_lineage_fq = Stats::Lineage.precedes_child_to_parent_map
          all_list_ids_fq = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
          all_machine_ids_fq = all_list_ids_fq.any? ? Top50BenchmarkResult.where(benchmark_id: all_list_ids_fq).pluck(:machine_id).uniq : []
          machine_names_fq = machine_display_name_map_for_ids(all_machine_ids_fq)

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
          @edition_dates_freshest_quantity = Array.new(top_50_dates.size)
          top_50_dates.each_with_index do |top50_date, reverse_edition_index|
            list_year, list_month = top50_date[0], top50_date[1]
            list_id = get_list_id_by_date(list_year, list_month)
            list_date = @date_vals.find_by(obj_id: list_id)&.value
            edition = top_50_dates.size - reverse_edition_index
            if list_date.present?
              @edition_dates_freshest_quantity[edition - 1] = Stats::EditionLabel.from_list_date(list_date)
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
            ranked_machine_ids_for_list(list_id, max_rank_limit).each_with_index do |machine_id, rank_index|
              rank = rank_index + 1
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

              node_rels_by_machine[machine_id].each do |node_rel|
                node_id = node_rel.sec_obj_id
                node_qty = node_rel.sec_obj_qty

                comp_rels_by_node[node_id].each do |component_rel|
                  component_id = component_rel.sec_obj_id
                  component_type = component_type_by_id[component_id]
                  if component_type.nil?
                    component_type = Top50Object.find_by(id: component_id)&.type_id
                    component_type_by_id[component_id] = component_type
                  end
                  next unless component_type

                  component_qty = component_rel.sec_obj_qty * node_qty
                  total_cpu_count += component_qty if component_type == @cpu_typeid
                  total_gpu_count += component_qty if component_type == @gpu_typeid

                  ci = component_info_by_id[component_id]
                  if ci.nil?
                    ci = ComponentInfo.find_by(component_id: component_id)
                    component_info_by_id[component_id] = ci
                  end
                  next unless ci

                  comp_model_name = nil
                  comp_vendor_name = nil
                  if component_type == @cpu_typeid && @cpu_model_attrid_fq.present?
                    comp_model_name = value_cache.dict_name_for(component_id, @cpu_model_attrid_fq)
                    comp_vendor_name = value_cache.dict_name_for(component_id, @cpu_vendor_attrid_fq) if @cpu_vendor_attrid_fq.present?
                  elsif component_type == @gpu_typeid && @gpu_model_attrid_fq.present?
                    comp_model_name = value_cache.dict_name_for(component_id, @gpu_model_attrid_fq)
                    comp_vendor_name = value_cache.dict_name_for(component_id, @gpu_vendor_attrid_fq) if @gpu_vendor_attrid_fq.present?
                  end

                  dm = ci.date_mentioned
                  da = ci.date_announced
                  dm_date = dm.respond_to?(:to_date) ? dm.to_date : (dm.is_a?(Date) ? dm : nil)
                  da_date = da.respond_to?(:to_date) ? da.to_date : (da.is_a?(Date) ? da : nil)

                  if dm_date.present? && da_date.present?
                    diff_days = (dm_date - da_date).to_i
                    if component_type == @cpu_typeid
                      if min_cpu_announce_to_mention_days.nil? || diff_days < min_cpu_announce_to_mention_days
                        min_cpu_announce_to_mention_days = diff_days
                        cpu_contour_date_announced = da_date if diff_days < 0
                        cpu_component_name = comp_model_name.presence
                        cpu_vendor_name = comp_vendor_name.presence
                      end
                    elsif component_type == @gpu_typeid
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
                    if component_type == @cpu_typeid
                      freshest_cpu_count += component_qty
                      @freshest_cpu_model_ids_by_edition[edition].add(component_id)
                      cpu_new_component_name ||= comp_model_name.presence
                      cpu_new_vendor_name ||= comp_vendor_name.presence
                    elsif component_type == @gpu_typeid
                      freshest_gpu_count += component_qty
                      @freshest_gpu_model_ids_by_edition[edition].add(component_id)
                      gpu_new_component_name ||= comp_model_name.presence
                      gpu_new_vendor_name ||= comp_vendor_name.presence
                    end
                  end
                end
              end

              if total_cpu_count == 0 && @cpu_qty_attrid.present?
                cpu_qty_val = value_cache.dbval_for(machine_id, @cpu_qty_attrid)
                total_cpu_count = cpu_qty_val.value.to_i if cpu_qty_val.present?
              end
              if total_gpu_count == 0 && @gpu_qty_attrid.present?
                gpu_qty_val = value_cache.dbval_for(machine_id, @gpu_qty_attrid)
                total_gpu_count = gpu_qty_val.value.to_i if gpu_qty_val.present?
              end

              machine_name_fq = machine_names_fq[machine_id] || "н/д"
              machine_key_fq = Stats::Lineage.branch_key_machine_id(machine_id, precedes_map_lineage_fq)
              @freshest_cpu_quantity_data << { edition: edition, rank: rank, lag: (freshest_cpu_count > 0 ? freshest_cpu_count : nil), total_cpu: total_cpu_count, total_gpu: total_gpu_count, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, component_name: cpu_new_component_name, vendor_name: cpu_new_vendor_name }
              @freshest_gpu_quantity_data << { edition: edition, rank: rank, lag: (freshest_gpu_count > 0 ? freshest_gpu_count : nil), total_cpu: total_cpu_count, total_gpu: total_gpu_count, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, component_name: gpu_new_component_name, vendor_name: gpu_new_vendor_name }
              show_cpu_contour = min_cpu_announce_to_mention_days.present? && min_cpu_announce_to_mention_days < 0 && cpu_contour_date_announced.present? && list_date_parsed < cpu_contour_date_announced
              show_gpu_contour = min_gpu_announce_to_mention_days.present? && min_gpu_announce_to_mention_days < 0 && gpu_contour_date_announced.present? && list_date_parsed < gpu_contour_date_announced
              @announce_to_mention_cpu_data << { edition: edition, rank: rank, lag: min_cpu_announce_to_mention_days, freshest_count: 1, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, is_new: (freshest_cpu_count > 0), show_before_announce_contour: show_cpu_contour, component_name: cpu_component_name, vendor_name: cpu_vendor_name }
              @announce_to_mention_gpu_data << { edition: edition, rank: rank, lag: min_gpu_announce_to_mention_days, freshest_count: 1, machine_id: machine_id, machine_name: machine_name_fq, machine_key: machine_key_fq, is_new: (freshest_gpu_count > 0), show_before_announce_contour: show_gpu_contour, component_name: gpu_component_name, vendor_name: gpu_vendor_name }
            end
          end

          merge_application_area_into_heatmap_rows!(@freshest_cpu_quantity_data)
          merge_application_area_into_heatmap_rows!(@freshest_gpu_quantity_data)
          merge_application_area_into_heatmap_rows!(@announce_to_mention_cpu_data)
          merge_application_area_into_heatmap_rows!(@announce_to_mention_gpu_data)

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

          @freshest_quantity_models_summary = chart_editions.map do |ed|
            cpu_ids = @freshest_cpu_model_ids_by_edition[ed] || Set.new
            gpu_ids = @freshest_gpu_model_ids_by_edition[ed] || Set.new
            {
              edition: ed,
              date_label: @freshest_quantity_chart_dates[ed],
              models_fresh_cpu: cpu_ids.size,
              models_fresh_gpu: gpu_ids.size,
              models_fresh_union: (cpu_ids | gpu_ids).size
            }
          end
          @freshest_quantity_models_chart_data = [
            { name: "Новые модели CPU", data: @freshest_quantity_models_summary.map { |s| [s[:date_label], s[:models_fresh_cpu]] }, color: "#2ca02c" },
            { name: "Новые модели GPU", data: @freshest_quantity_models_summary.map { |s| [s[:date_label], s[:models_fresh_gpu]] }, color: "#ff7f0e" },
            { name: "Новые модели CPU + GPU", data: @freshest_quantity_models_summary.map { |s| [s[:date_label], s[:models_fresh_union]] }, color: "#0000FF" }
          ]

          @freshest_quantity_components_summary = chart_editions.map do |ed|
            cpu_entries = cpu_by_edition[ed] || []
            gpu_entries = gpu_by_edition[ed] || []
            components_fresh_cpu = cpu_entries.sum { |h| h[:lag].to_i }
            components_fresh_gpu = gpu_entries.sum { |h| h[:lag].to_i }
            {
              edition: ed,
              date_label: @freshest_quantity_chart_dates[ed],
              components_fresh_cpu: components_fresh_cpu,
              components_fresh_gpu: components_fresh_gpu,
              components_fresh_both: components_fresh_cpu + components_fresh_gpu
            }
          end
          @freshest_quantity_components_chart_data = [
            { name: "Новые CPU", data: @freshest_quantity_components_summary.map { |s| [s[:date_label], s[:components_fresh_cpu]] }, color: "#2ca02c" },
            { name: "Новые GPU", data: @freshest_quantity_components_summary.map { |s| [s[:date_label], s[:components_fresh_gpu]] }, color: "#ff7f0e" },
            { name: "Новые CPU + GPU", data: @freshest_quantity_components_summary.map { |s| [s[:date_label], s[:components_fresh_both]] }, color: "#0000FF" }
          ]

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

            pct_cpu_all = Stats::Percent.of(components_fresh_cpu, total_cpu_all)
            pct_gpu_all = Stats::Percent.of(components_fresh_gpu, total_gpu_all)
            pct_both_all = Stats::Percent.of(components_fresh_both, total_components_all)
            pct_cpu_new = Stats::Percent.of(components_fresh_cpu, total_cpu_new_systems)
            pct_gpu_new = Stats::Percent.of(components_fresh_gpu, total_gpu_new_systems)
            pct_both_new = Stats::Percent.of(components_fresh_both, total_components_new_systems)
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

          if @rpeak_attrid.present? && @rmax_benchid.present?
            indexes = Stats::RpeakRmaxIndex.build(rpeak_attrid: @rpeak_attrid, rmax_benchid: @rmax_benchid)
            rmax_by_machine = indexes[:rmax_by_machine]
            rpeak_by_machine = indexes[:rpeak_by_machine]

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

              rank_to_machine = ranked_machine_ids_for_list(list_id, max_rank_limit).each_with_index.map { |mid, i| [i + 1, mid] }.to_h
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

              rpeak_pct_cpu << [date_label, Stats::Percent.of(sum_rpeak_cpu, sum_rpeak_total)]
              rpeak_pct_gpu << [date_label, Stats::Percent.of(sum_rpeak_gpu, sum_rpeak_total)]
              rpeak_pct_union << [date_label, Stats::Percent.of(sum_rpeak_union, sum_rpeak_total)]
              rmax_pct_cpu << [date_label, Stats::Percent.of(sum_rmax_cpu, sum_rmax_total)]
              rmax_pct_gpu << [date_label, Stats::Percent.of(sum_rmax_gpu, sum_rmax_total)]
              rmax_pct_union << [date_label, Stats::Percent.of(sum_rmax_union, sum_rmax_total)]
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

          summary_by_edition = (@freshest_quantity_summary || []).index_by { |s| s[:edition] }
          model_summary_by_edition = (@freshest_quantity_models_summary || []).index_by { |s| s[:edition] }
          component_summary_by_edition = (@freshest_quantity_components_summary || []).index_by { |s| s[:edition] }
          @fr_comp_stats_table = chart_editions.each_with_index.map do |ed, idx|
            sum = summary_by_edition[ed] || {}
            mod = model_summary_by_edition[ed] || {}
            comp = component_summary_by_edition[ed] || {}
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

          @fr_comp_stats_csv_header = "Редакция,Системы с новыми CPU,Системы с новыми GPU,Системы с новыми CPU или GPU,Новых моделей CPU,Новых моделей GPU,Новых моделей CPU+GPU,Кол-во новых CPU,Кол-во новых GPU,Кол-во новых CPU+GPU,% новых CPU (все),% новых GPU (все),% новых CPU+GPU (все),% новых CPU (сист. с нов.),% новых GPU (сист. с нов.),% новых CPU+GPU (сист. с нов.),% Rpeak CPU,% Rmax CPU,% Rpeak GPU,% Rmax GPU,% Rpeak CPU или GPU,% Rmax CPU или GPU"
          @fr_comp_stats_csv_lines = [@fr_comp_stats_csv_header]
          @fr_comp_stats_table.reverse.each do |r|
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
            @fr_comp_stats_csv_lines << csv_row.join(",")
          end

          @freshest_cpu_quantity_data = @freshest_cpu_quantity_data.select { |h| chart_editions.include?(h[:edition]) }
          @freshest_gpu_quantity_data = @freshest_gpu_quantity_data.select { |h| chart_editions.include?(h[:edition]) }
          @announce_to_mention_cpu_data = @announce_to_mention_cpu_data.select { |h| chart_editions.include?(h[:edition]) }
          @announce_to_mention_gpu_data = @announce_to_mention_gpu_data.select { |h| chart_editions.include?(h[:edition]) }
        end
      end

      private
    end
  end
end
