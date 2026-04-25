module Stats
  module Sections
    class FrCompLagService < BaseSectionService

      def call
        run_in_context do
          calc_machine_attrs
          @cpu_model_attrid_lag = Top50Attribute.where(name_eng: "CPU model").first&.id
          @gpu_model_attrid_lag = Top50Attribute.where(name_eng: "GPU model").first&.id
          @cpu_vendor_attrid_lag = Top50Attribute.where(name_eng: "CPU Vendor").first&.id
          @gpu_vendor_attrid_lag = Top50Attribute.where(name_eng: "GPU Vendor").first&.id
          @all_ratings_data = []
          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)

          precedes_map_lineage = Stats::Lineage.precedes_child_to_parent_map

          all_list_ids_lag = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
          all_machine_ids_lag = all_list_ids_lag.any? ? Top50BenchmarkResult.where(benchmark_id: all_list_ids_lag).pluck(:machine_id).uniq : []
          machine_display_names_lag = machine_display_name_map_for_ids(all_machine_ids_lag)

          top_50_dates.each do |top50_date|
            list_id = get_list_id_by_date(top50_date[0], top50_date[1])
            prepare_archive(list_id)
            top50_machines = fetch_archive_list(list_id).order("ed_results.result asc")
            list_date = @date_vals.find_by(obj_id: list_id)&.value
            safe_mach_l1 = @mach_l1_hash || Hash.new { |h, k| h[k] = [] }
            safe_l1_l2 = @l1_l2_hash || Hash.new { |h, k| h[k] = [] }
            rating_data = {
              date: top50_date,
              list_date: list_date,
              machines: top50_machines,
              mach_l1_hash: safe_mach_l1.dup.tap { |h| h.default_proc = safe_mach_l1.default_proc },
              l1_l2_hash: safe_l1_l2.dup.tap { |h| h.default_proc = safe_l1_l2.default_proc }
            }
            @all_ratings_data << rating_data
          end

          @cpu_data = []
          @gpu_data = []
          @combined_data = []
          @edition_dates_lag = Array.new(@all_ratings_data.size)

          component_info_cache = {}
          value_cache = Stats::AttributeValueCache.new

          @all_ratings_data.each_with_index do |rating_data, reverse_edition_index|
            edition = @all_ratings_data.size - reverse_edition_index
            machines = rating_data[:machines]
            list_date = rating_data[:list_date]
            if list_date.present?
              @edition_dates_lag[edition - 1] = Stats::EditionLabel.from_list_date(list_date)
            end
            next unless list_date.present?

            list_date_parsed = Date.parse(list_date)
            machines.each_with_index do |machine, rank_index|
              newest_cpu_diff = Float::INFINITY
              newest_gpu_diff = Float::INFINITY
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
                l2_objs = rating_data[:l1_l2_hash][node.id] || []
                cpus = l2_objs.select { |x| x.type_id == @cpu_typeid }
                gpus = l2_objs.select { |x| x.type_id == @gpu_typeid }

                cpus.each do |cpu|
                  component_info = component_info_cache[cpu.id]
                  if component_info.nil?
                    component_info = ComponentInfo.find_by(component_id: cpu.id)
                    component_info_cache[cpu.id] = component_info
                  end
                  if component_info&.date_announced && component_info&.date_mentioned
                    da = component_info.date_announced.to_date
                    dm = component_info.date_mentioned.to_date
                    diff = (list_date_parsed - da).to_i
                    if diff < newest_cpu_diff
                      newest_cpu_diff = diff
                      freshest_cpu_count = cpu.cnt
                      cpu_announced_after_mention = (da > dm)
                      cpu_component_name = value_cache.dict_name_for(cpu.id, @cpu_model_attrid_lag) if @cpu_model_attrid_lag.present?
                      cpu_vendor_name = value_cache.dict_name_for(cpu.id, @cpu_vendor_attrid_lag) if @cpu_vendor_attrid_lag.present?
                    elsif diff == newest_cpu_diff
                      freshest_cpu_count += cpu.cnt
                    end
                  end
                end

                gpus.each do |gpu|
                  component_info = component_info_cache[gpu.id]
                  if component_info.nil?
                    component_info = ComponentInfo.find_by(component_id: gpu.id)
                    component_info_cache[gpu.id] = component_info
                  end
                  if component_info&.date_announced && component_info&.date_mentioned
                    da = component_info.date_announced.to_date
                    dm = component_info.date_mentioned.to_date
                    diff = (list_date_parsed - da).to_i
                    if diff < newest_gpu_diff
                      newest_gpu_diff = diff
                      freshest_gpu_count = gpu.cnt
                      gpu_announced_after_mention = (da > dm)
                      gpu_component_name = value_cache.dict_name_for(gpu.id, @gpu_model_attrid_lag) if @gpu_model_attrid_lag.present?
                      gpu_vendor_name = value_cache.dict_name_for(gpu.id, @gpu_vendor_attrid_lag) if @gpu_vendor_attrid_lag.present?
                    elsif diff == newest_gpu_diff
                      freshest_gpu_count += gpu.cnt
                    end
                  end
                end
              end

              newest_cpu_diff = nil if newest_cpu_diff == Float::INFINITY
              newest_gpu_diff = nil if newest_gpu_diff == Float::INFINITY
              freshest_cpu_count = nil if newest_cpu_diff.nil?
              freshest_gpu_count = nil if newest_gpu_diff.nil?

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

              show_cpu_contour_lag = cpu_announced_after_mention && newest_cpu_diff.present? && newest_cpu_diff < 0
              show_gpu_contour_lag = gpu_announced_after_mention && newest_gpu_diff.present? && newest_gpu_diff < 0
              show_combined_contour_lag = combined_announced_after_mention && combined_diff.present? && combined_diff < 0

              machine_id = machine["id"]
              machine_name = machine_display_names_lag[machine_id] || "н/д"
              machine_key = Stats::Lineage.branch_key_machine_id(machine_id, precedes_map_lineage)
              @cpu_data << { edition: edition, rank: rank_index + 1, lag: newest_cpu_diff, freshest_count: freshest_cpu_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: cpu_component_name, vendor_name: cpu_vendor_name, show_before_announce_contour: show_cpu_contour_lag }
              @gpu_data << { edition: edition, rank: rank_index + 1, lag: newest_gpu_diff, freshest_count: freshest_gpu_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: gpu_component_name, vendor_name: gpu_vendor_name, show_before_announce_contour: show_gpu_contour_lag }
              @combined_data << { edition: edition, rank: rank_index + 1, lag: combined_diff, freshest_count: freshest_combined_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: combined_component_name, vendor_name: combined_vendor_name, show_before_announce_contour: show_combined_contour_lag }
            end
          end

          merge_application_area_into_heatmap_rows!(@cpu_data)
          merge_application_area_into_heatmap_rows!(@gpu_data)
          merge_application_area_into_heatmap_rows!(@combined_data)
        end
      end

      private
    end
  end
end
