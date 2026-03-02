class ExtratingsEntriesController < Top50BaseController
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  
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

    errors = []
    
    if params[:extratings_list_id].blank?
      errors << "Не выбран лист рейтинга"
    end
    
    if params[:edition_number].blank?
      errors << "Не указан номер редакции"
    end
    
    if params[:publication_date].blank?
      errors << "Не указана дата публикации"
    end
    
    if params[:extratings_entry].blank? || params[:extratings_entry][:position].blank?
      errors << "Не указана позиция"
    end
    
    if params[:extratings_entry].blank? || params[:extratings_entry][:system_id].blank?
      errors << "Не выбрана система"
    end
    
    scores_params = params[:scores] || {}
    selected_units = params[:selected_units] || {}
    
    if scores_params.empty?
      errors << "Не указаны показатели производительности"
    else
      scores_params.each do |key, score_value|
        if score_value.blank?
          errors << "Не указано значение для показателя '#{key}'"
        end
        
        unit_id = selected_units[key]
        if unit_id.blank?
          errors << "Не выбрана единица измерения для показателя '#{key}'"
        end
      end
    end
    
    if errors.any?
      flash.now[:alert] = "Ошибки валидации: #{errors.join(', ')}"
      new
      respond_to do |format|
        format.html { render :new }
        format.js { render :new }
      end
      return
    end

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
      scores_params.each do |key, score_value|
        next if score_value.blank?

        unit_id_str = selected_units[key]
        next if unit_id_str.blank?

        unit_id = unit_id_str.to_i
        next if unit_id.zero?

        unit = ExtratingsListUnit.find_by(id: unit_id)
        next unless unit

        ExtratingsScore.create!(
          extratings_entry: @extratings_entry,
          extratings_list_unit_id: unit_id,
          score: score_value.to_f
        )
      end
    end

    respond_to do |format|
      format.html { redirect_to top50_machines_show_path(@extratings_entry.system_id), notice: "Запись рейтинга и оценки успешно созданы." }
      format.js { redirect_to top50_machines_show_path(@extratings_entry.system_id), notice: "Запись рейтинга и оценки успешно созданы." }
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Ошибка создания записи: #{e.message}"
    new
    respond_to do |format|
      format.html { render :new }
      format.js { render :new }
    end
  rescue => e
    flash.now[:alert] = "Ошибка создания записи: #{e.message}"
    Rails.logger.error "Error in extratings_entries#create: #{e.message}\n#{e.backtrace.join("\n")}"
    new
    respond_to do |format|
      format.html { render :new }
      format.js { render :new }
    end
  end

  def show
    @extratings_entry = ExtratingsEntry.includes(:system, :extratings_edition, :extratings_scores).find(params[:id])
    redirect_to top50_machines_show_path(@extratings_entry.system_id)
  end

  def destroy
    @extratings_entry = ExtratingsEntry.find(params[:id])
    system_id = @extratings_entry.system_id
    
    begin
      ActiveRecord::Base.transaction do
      
        @extratings_entry.extratings_scores.destroy_all
        
        @extratings_entry.destroy!
      end
      
      respond_to do |format|
        format.js { render 'destroy' }
        format.html { redirect_to top50_machines_show_path(system_id), notice: 'Запись успешно удалена' }
      end
    rescue => e
      Rails.logger.error "Ошибка при удалении записи #{@extratings_entry.id}: #{e.message}"
      respond_to do |format|
        format.js { render 'destroy', locals: { error: 'Ошибка при удалении записи: ' + e.message } }
        format.html { redirect_to top50_machines_show_path(system_id), alert: 'Ошибка при удалении записи: ' + e.message }
      end
    end
  end

  def edit
    @extratings_entry = ExtratingsEntry.find(params[:id])
    @extratings_lists = ExtratingsList.order(:name_eng)
    
  
    @current_scores = {}
    @extratings_entry.extratings_scores.includes(:extratings_list_unit).each do |score|
      unit_name = score.extratings_list_unit.extratings_unit.name_eng
      @current_scores[unit_name] = {
        value: score.score,
        unit_id: score.extratings_list_unit_id
      }
    end
  end

  def update
    @extratings_entry = ExtratingsEntry.find(params[:id])
    
    ActiveRecord::Base.transaction do
    
      edition = ExtratingsEditions.find_or_create_by!(
        extratings_list_id: params[:extratings_list_id],
        edition_number: params[:edition_number],
        edition_multiplier: 1
      ) do |e|
        e.publication_date = params[:publication_date]
      end
      
      # Обновляем дату публикации если редакция уже существовала
      if edition.persisted? && edition.publication_date != params[:publication_date]
        edition.update!(publication_date: params[:publication_date])
      end
      
      @extratings_entry.update!(
        position: params[:extratings_entry][:position],
        extratings_edition: edition
      )
      
      @extratings_entry.extratings_scores.destroy_all
      
      scores_params = params[:scores] || {}
      selected_units = params[:selected_units] || {}

      scores_params.each do |key, score_value|
        next if score_value.blank?

        unit_id_str = selected_units[key]
        if unit_id_str.blank?
          Rails.logger.warn "No selected unit for score key=#{key}, params:selected_units=#{selected_units.inspect}"
          next
        end

        unit_id = unit_id_str.to_i
        if unit_id.zero?
          Rails.logger.warn "Invalid unit id (0) for key=#{key}, raw=#{unit_id_str.inspect}"
          next
        end

        unit = ExtratingsListUnit.find_by(id: unit_id)
        unless unit
          Rails.logger.warn "ExtratingsListUnit not found for id=#{unit_id} (key=#{key})"
          next
        end

        ExtratingsScore.create!(
          extratings_entry: @extratings_entry,
          extratings_list_unit_id: unit_id,
          score: score_value.to_f
        )
      end
    end

    respond_to do |format|
      format.js { render 'update' }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.js { render 'update', locals: { error: e.message } }
    end
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
