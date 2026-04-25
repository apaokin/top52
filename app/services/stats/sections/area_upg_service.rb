module Stats
  module Sections
    class AreaUpgService
      def initialize(context:)
        @context = context
      end

      def call
        controller_class = context.class
        context.instance_eval do
          @area_upg_lag_by_edition = []
          @area_upg_new_qty_by_edition = []
          @area_upg_systems_with_new_by_edition = []
          @area_upg_new_upgraded_by_edition = []
          @area_upg_edition_labels = []

          calc_machine_attrs
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

          editions_total = top_50_dates.size
          per_edition_area = Hash.new do |h, k|
            h[k] = Hash.new do |hh, kk|
              hh[kk] = {
                lag_sum: 0.0, lag_count: 0, fresh_total: 0,
                systems_total: 0, systems_with_new: 0, new_systems: 0, upgraded_systems: 0, total_new_upgraded: 0
              }
            end
          end
          all_area_names = Set.new
          fallback_area_name = "Не указано/Прочие"
          palette = controller_class::D3_SCHEME_PAIRED
          target_areas = controller_class::HEATMAP_TARGET_APP_AREAS
          max_rank_limit = @max_rank || controller_class::TOP50_MAX_RANK
          fallback_area_color = palette[target_areas.size % palette.size]
          area_colors = {}
          precedes_type_id = Top50RelationType.find_by(name_eng: "Precedes")&.id
          precedes_map = if precedes_type_id
            Top50Relation.where(type_id: precedes_type_id, is_valid: [1, 2]).order(:id).each_with_object({}) { |r, h| h[r.sec_obj_id] ||= r.prim_obj_id }
          else
            {}
          end

          node_rels_by_machine = Hash.new do |h, machine_id|
            h[machine_id] = Top50Relation.where(prim_obj_id: machine_id, type_id: @rel_contain_id).to_a
          end
          comp_rels_by_node = Hash.new do |h, node_id|
            h[node_id] = Top50Relation.where(prim_obj_id: node_id, type_id: @rel_contain_id).to_a
          end
          component_type_by_id = {}
          component_info_by_id = {}

          top_50_dates.each_with_index do |top50_date, reverse_edition_index|
            list_year, list_month = top50_date[0], top50_date[1]
            list_id = get_list_id_by_date(list_year, list_month)
            list_date = @date_vals.find_by(obj_id: list_id)&.value
            edition = editions_total - reverse_edition_index
            if list_date.present?
              parts = list_date.split(".")
              @area_upg_edition_labels[edition - 1] = parts.size >= 3 ? "#{parts[1]}.#{parts[2][-2..-1]}" : list_date
            else
              @area_upg_edition_labels[edition - 1] = "#{list_month}.#{list_year.to_s[-2..-1]}"
            end

            next unless list_date.present?

            begin
              list_date_parsed = Date.strptime(list_date, "%d.%m.%Y")
            rescue ArgumentError
              next
            end

            machine_ids = ranked_machine_ids_for_list(list_id, max_rank_limit)
            prev_machine_ids_set = nil
            if reverse_edition_index + 1 < top_50_dates.size
              prev_year, prev_month = top_50_dates[reverse_edition_index + 1]
              prev_list_id = get_list_id_by_date(prev_year, prev_month)
              prev_machine_ids_set = ranked_machine_ids_for_list(prev_list_id, max_rank_limit).to_set if prev_list_id.present?
            end
            area_meta = application_area_color_by_machine_id(machine_ids)

            machine_ids.each do |machine_id|
              min_cpu_lag = nil
              min_gpu_lag = nil
              freshest_cpu_count = 0
              freshest_gpu_count = 0

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
                  ci = component_info_by_id[component_id]
                  if ci.nil?
                    ci = ComponentInfo.find_by(component_id: component_id)
                    component_info_by_id[component_id] = ci
                  end
                  next unless ci

                  da = ci.date_announced.respond_to?(:to_date) ? ci.date_announced.to_date : (ci.date_announced.is_a?(Date) ? ci.date_announced : nil)
                  dm = ci.date_mentioned.respond_to?(:to_date) ? ci.date_mentioned.to_date : (ci.date_mentioned.is_a?(Date) ? ci.date_mentioned : nil)

                  if da.present?
                    lag_days = (list_date_parsed - da).to_i
                    if component_type == @cpu_typeid
                      min_cpu_lag = lag_days if min_cpu_lag.nil? || lag_days < min_cpu_lag
                    elsif component_type == @gpu_typeid
                      min_gpu_lag = lag_days if min_gpu_lag.nil? || lag_days < min_gpu_lag
                    end
                  end

                  is_freshest = (dm.present? && dm == list_date_parsed) || (da.present? && da >= list_date_parsed)
                  next unless is_freshest

                  if component_type == @cpu_typeid
                    freshest_cpu_count += component_qty
                  elsif component_type == @gpu_typeid
                    freshest_gpu_count += component_qty
                  end
                end
              end

              combined_lag = if min_cpu_lag.present? && min_gpu_lag.present?
                               [min_cpu_lag, min_gpu_lag].min
                             elsif min_cpu_lag.present?
                               min_cpu_lag
                             elsif min_gpu_lag.present?
                               min_gpu_lag
                             end
              fresh_total = freshest_cpu_count + freshest_gpu_count

              area_name = area_meta.dig(machine_id, :area_name).presence || fallback_area_name
              area_colors[area_name] ||= area_meta.dig(machine_id, :area_color)
              all_area_names.add(area_name)
              bucket = per_edition_area[edition][area_name]
              bucket[:systems_total] += 1
              if combined_lag.present?
                bucket[:lag_sum] += combined_lag
                bucket[:lag_count] += 1
              end
              bucket[:fresh_total] += fresh_total
              bucket[:systems_with_new] += 1 if fresh_total > 0

              if prev_machine_ids_set.present? && !prev_machine_ids_set.include?(machine_id)
                prev_mid = precedes_map[machine_id]
                if prev_mid.present?
                  bucket[:upgraded_systems] += 1
                else
                  bucket[:new_systems] += 1
                end
              end
              bucket[:total_new_upgraded] = bucket[:new_systems] + bucket[:upgraded_systems]
            end
          end

          ordered_areas = []
          preferred_order = target_areas + [fallback_area_name]
          present_areas = all_area_names.to_a.uniq
          preferred_order.each { |n| ordered_areas << n if present_areas.include?(n) }
          remaining = present_areas - ordered_areas
          ordered_areas += remaining.sort

          (1..editions_total).each do |edition|
            date_label = @area_upg_edition_labels[edition - 1] || edition.to_s
            lag_points = ordered_areas.map do |area_name|
              rec = per_edition_area.dig(edition, area_name) || { lag_sum: 0.0, lag_count: 0, fresh_total: 0 }
              avg_lag = rec[:lag_count] > 0 ? (rec[:lag_sum].to_f / rec[:lag_count]) : 0.0
              { area: area_name, value: avg_lag.round(2), color: (area_colors[area_name] || fallback_area_color) }
            end
            qty_points = ordered_areas.map do |area_name|
              rec = per_edition_area.dig(edition, area_name) || { lag_sum: 0.0, lag_count: 0, fresh_total: 0, systems_total: 0, systems_with_new: 0, new_systems: 0, upgraded_systems: 0, total_new_upgraded: 0 }
              value = rec[:fresh_total].to_i
              { area: area_name, value: value, color: (area_colors[area_name] || fallback_area_color) }
            end
            systems_with_new_points = ordered_areas.map do |area_name|
              rec = per_edition_area.dig(edition, area_name) || { lag_sum: 0.0, lag_count: 0, fresh_total: 0, systems_total: 0, systems_with_new: 0, new_systems: 0, upgraded_systems: 0, total_new_upgraded: 0 }
              total_systems = rec[:systems_total].to_i
              value = rec[:systems_with_new].to_i
              share_pct = total_systems > 0 ? Stats::Percent.of(value, total_systems) : nil
              { area: area_name, value: value, total_systems: total_systems, share_pct: share_pct, color: (area_colors[area_name] || fallback_area_color) }
            end
            new_upgraded_points = ordered_areas.map do |area_name|
              rec = per_edition_area.dig(edition, area_name) || { lag_sum: 0.0, lag_count: 0, fresh_total: 0, systems_total: 0, systems_with_new: 0, new_systems: 0, upgraded_systems: 0, total_new_upgraded: 0 }
              total_systems = rec[:systems_total].to_i
              new_value = rec[:new_systems].to_i
              upg_value = rec[:upgraded_systems].to_i
              new_share_pct = total_systems > 0 ? Stats::Percent.of(new_value, total_systems) : nil
              upg_share_pct = total_systems > 0 ? Stats::Percent.of(upg_value, total_systems) : nil
              {
                area: area_name,
                total_systems: total_systems,
                new_systems: new_value,
                upgraded_systems: upg_value,
                new_share_pct: new_share_pct,
                upgraded_share_pct: upg_share_pct,
                total_new_upgraded: rec[:total_new_upgraded].to_i
              }
            end
            @area_upg_lag_by_edition << { edition: edition, date_label: date_label, data: lag_points }
            @area_upg_new_qty_by_edition << { edition: edition, date_label: date_label, data: qty_points }
            @area_upg_systems_with_new_by_edition << { edition: edition, date_label: date_label, data: systems_with_new_points }
            @area_upg_new_upgraded_by_edition << { edition: edition, date_label: date_label, data: new_upgraded_points }
          end
        end
      end

      private

      attr_reader :context
    end
  end
end
