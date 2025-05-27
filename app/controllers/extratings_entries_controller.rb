class ExtratingsEntriesController < Top50BaseController
  def new
    @extratings_entry = ExtratingsEntry.new
    @systems = Top50Relation.joins("JOIN top50_machines ON top50_relations.prim_obj_id = top50_machines.id")
      .select(
        "top50_relations.id AS relation_id, 
        top50_machines.id AS machine_id,
        CASE 
          WHEN top50_machines.name IS NOT NULL AND top50_machines.name <> '' THEN top50_machines.name
          WHEN top50_machines.name_eng IS NOT NULL AND top50_machines.name_eng <> '' THEN top50_machines.name_eng
          ELSE NULL
        END AS display_name"
      )
      .where("top50_machines.name IS NOT NULL AND top50_machines.name <> '' OR top50_machines.name_eng IS NOT NULL AND top50_machines.name_eng <> ''")
      .order("display_name")

    @extratings_lists = ExtratingsList.order(:name_eng)
  end

  def create
    ActiveRecord::Base.transaction do
      # Создаём редакцию рейтинга с датой публикации
      edition = ExtratingsEditions.find_or_create_by!(
        extratings_list_id: params[:extratings_list_id],
        edition_number: params[:edition_number],
        edition_multiplier: 1
      ) do |e|
        e.publication_date = params[:publication_date]
      end
  
      # Остальной код остаётся без изменений
      relation = Top50Relation.find(params[:extratings_entry][:system_id])
      machine_id = relation.prim_obj_id

      @extratings_entry = ExtratingsEntry.new(
        system_id: machine_id,  # Используем machine_id вместо relation_id
        extratings_edition: edition,
        position: params[:extratings_entry][:position]
      )
      @extratings_entry.save!

      # Создаём оценки
      scores_params = params[:scores] || {}
      scores_params.each do |list_unit_id, score_value|
        next if score_value.blank?

        ExtratingsScore.create!(
          extratings_entry: @extratings_entry,
          extratings_list_unit_id: list_unit_id,
          score: score_value.to_i
        )
      end
    end

    redirect_to @extratings_entry, notice: "Запись рейтинга и оценки успешно созданы."
      rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Ошибка создания записи: #{e.message}"
    new
    render :new
  end

  def list_units
    list = ExtratingsList.find(params[:list_id])
    
    # Группируем по extratings_unit_id и выбираем запись с наивысшим приоритетом
    units = list.extratings_list_units
                .joins(:extratings_unit)
                .group(:extratings_unit_id)
                .select('
                  MAX(extratings_list_units.id) as id,
                  extratings_unit_id,
                  MAX(extratings_list_units.priority) as priority,
                  MAX(extratings_units.name_eng) as name_eng,
                  MAX(extratings_units.measure_unit) as measure_unit
                ')
                .order('MAX(extratings_list_units.priority)')
    
    render json: units.map { |unit|
      {
        id: unit.id,
        priority: unit.priority,
        unit_name: unit.name_eng,
        measure_unit: unit.measure_unit
      }
    }
  end
  
end
