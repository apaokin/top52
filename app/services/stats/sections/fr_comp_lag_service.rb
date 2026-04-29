module Stats
  module Sections
    class FrCompLagService < BaseSectionService

      def call
        run_in_context do
          @cpu_typeid = Top50ObjectType.find_by(name_eng: "CPU")&.id
          @gpu_typeid = Top50ObjectType.find_by(name_eng: "GPU")&.id
          @rel_contain_id = get_rel_contain_id
          @cpu_model_attrid_lag = Top50Attribute.find_by(name_eng: "CPU model")&.id
          @gpu_model_attrid_lag = Top50Attribute.find_by(name_eng: "GPU model")&.id
          @cpu_vendor_attrid_lag = Top50Attribute.find_by(name_eng: "CPU Vendor")&.id
          @gpu_vendor_attrid_lag = Top50Attribute.find_by(name_eng: "GPU Vendor")&.id
          @all_ratings_data = []
          top50_slists = get_top50_lists_sorted
          top_50_dates = Stats::EditionTimeline.from_lists(top50_slists: top50_slists, date_vals: @date_vals)

          precedes_map_lineage = precedes_child_to_parent_map_for_lineage

          all_list_ids_lag = top_50_dates.map { |y, m| get_list_id_by_date(y, m) }.compact
          max_rank_limit = @max_rank || self.class::TOP50_MAX_RANK
          machine_ids_by_list = all_list_ids_lag.each_with_object({}) do |list_id, h|
            h[list_id] = ranked_machine_ids_for_list(list_id, max_rank_limit)
          end
          all_machine_ids_lag = machine_ids_by_list.values.flatten.uniq
          machine_display_names_lag = machine_display_name_map_for_ids(all_machine_ids_lag)
          graph = preload_machine_component_graph(all_machine_ids_lag, rel_contain_id: @rel_contain_id)
          node_rels_by_machine = graph[:node_rels_by_machine]
          comp_rels_by_node = graph[:comp_rels_by_node]
          component_type_by_id = graph[:component_type_by_id]
          component_info_by_id = graph[:component_info_by_id]

          top_50_dates.each do |top50_date|
            list_id = get_list_id_by_date(top50_date[0], top50_date[1])
            list_date = @date_vals.find_by(obj_id: list_id)&.value
            rating_data = {
              date: top50_date,
              list_date: list_date,
              machine_ids: machine_ids_by_list[list_id] || []
            }
            @all_ratings_data << rating_data
          end

          @cpu_data = []
          @gpu_data = []
          @combined_data = []
          @edition_dates_lag = Array.new(@all_ratings_data.size)

          value_cache = Stats::AttributeValueCache.new
          dict_attr_ids = [@cpu_model_attrid_lag, @gpu_model_attrid_lag, @cpu_vendor_attrid_lag, @gpu_vendor_attrid_lag].compact
          value_cache.warm_dict(obj_ids: component_type_by_id.keys, attr_ids: dict_attr_ids) if dict_attr_ids.any?

          @all_ratings_data.each_with_index do |rating_data, reverse_edition_index|
            edition = @all_ratings_data.size - reverse_edition_index
            machine_ids = rating_data[:machine_ids] || []
            list_date = rating_data[:list_date]
            if list_date.present?
              @edition_dates_lag[edition - 1] = Stats::EditionLabel.from_list_date(list_date)
            end
            next unless list_date.present?

            list_date_parsed = Date.parse(list_date)
            machine_ids.each_with_index do |machine_id, rank_index|
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

              node_rels_by_machine[machine_id].each do |node_rel|
                comp_rels_by_node[node_rel.sec_obj_id].each do |component_rel|
                  component_id = component_rel.sec_obj_id
                  component_type = component_type_by_id[component_id]
                  next unless component_type == @cpu_typeid || component_type == @gpu_typeid

                  component_info = component_info_by_id[component_id]
                  next unless component_info&.date_announced && component_info&.date_mentioned

                  da = component_info.date_announced.to_date
                  dm = component_info.date_mentioned.to_date
                  diff = (list_date_parsed - da).to_i
                  component_qty = component_rel.sec_obj_qty

                  if component_type == @cpu_typeid
                    if diff < newest_cpu_diff
                      newest_cpu_diff = diff
                      freshest_cpu_count = component_qty
                      cpu_announced_after_mention = (da > dm)
                      cpu_component_name = value_cache.dict_name_for(component_id, @cpu_model_attrid_lag) if @cpu_model_attrid_lag.present?
                      cpu_vendor_name = value_cache.dict_name_for(component_id, @cpu_vendor_attrid_lag) if @cpu_vendor_attrid_lag.present?
                    elsif diff == newest_cpu_diff
                      freshest_cpu_count += component_qty
                    end
                  elsif component_type == @gpu_typeid
                    if diff < newest_gpu_diff
                      newest_gpu_diff = diff
                      freshest_gpu_count = component_qty
                      gpu_announced_after_mention = (da > dm)
                      gpu_component_name = value_cache.dict_name_for(component_id, @gpu_model_attrid_lag) if @gpu_model_attrid_lag.present?
                      gpu_vendor_name = value_cache.dict_name_for(component_id, @gpu_vendor_attrid_lag) if @gpu_vendor_attrid_lag.present?
                    elsif diff == newest_gpu_diff
                      freshest_gpu_count += component_qty
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

              machine_name = machine_display_names_lag[machine_id] || "н/д"
              machine_key = Stats::Lineage.branch_key_machine_id(machine_id, precedes_map_lineage)
              @cpu_data << { edition: edition, rank: rank_index + 1, lag: newest_cpu_diff, freshest_count: freshest_cpu_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: cpu_component_name, vendor_name: cpu_vendor_name, show_before_announce_contour: show_cpu_contour_lag }
              @gpu_data << { edition: edition, rank: rank_index + 1, lag: newest_gpu_diff, freshest_count: freshest_gpu_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: gpu_component_name, vendor_name: gpu_vendor_name, show_before_announce_contour: show_gpu_contour_lag }
              @combined_data << { edition: edition, rank: rank_index + 1, lag: combined_diff, freshest_count: freshest_combined_count, machine_id: machine_id, machine_name: machine_name, machine_key: machine_key, component_name: combined_component_name, vendor_name: combined_vendor_name, show_before_announce_contour: show_combined_contour_lag }
            end
          end

          merge_application_area_into_many_heatmap_rows!(@cpu_data, @gpu_data, @combined_data)
        end
      end

      private
    end
  end
end
