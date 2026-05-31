class ExtratingsListsController < ApplicationController
  before_action :require_top50_superadmin
  before_action :set_extratings_list, only: [:edit, :update, :destroy, :destroy_unit]
  before_action :load_existing_units, only: [:new, :create, :edit, :update]
  before_action :load_usage_counts, only: [:edit]

  def new
    @extratings_list = ExtratingsList.new
    build_list_unit_if_needed
  end

  def create
    @extratings_list = ExtratingsList.new(extratings_list_params)

    if @extratings_list.save
      redirect_to edit_extratings_list_path(@extratings_list), notice: "Рейтинг успешно создан"
    else
      build_list_unit_if_needed
      render :new
    end
  end

  def edit
    build_list_unit_if_needed
    render :new
  end

  def update
    if @extratings_list.update(extratings_list_params)
      redirect_to edit_extratings_list_path(@extratings_list), notice: "Рейтинг успешно обновлен"
    else
      build_list_unit_if_needed
      load_usage_counts
      render :new
    end
  end

  def destroy
    counts = rating_usage_counts(@extratings_list)
    list_name = @extratings_list.name_ru.presence || @extratings_list.name_eng.presence || "без названия"

    ActiveRecord::Base.transaction do
      @extratings_list.destroy!
    end

    redirect_to new_extratings_entry_path, notice: "Рейтинг \"#{list_name}\" удален. Удалено редакций: #{counts[:editions]}, вхождений: #{counts[:entries]}, значений: #{counts[:scores]}."
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    load_existing_units
    load_usage_counts
    flash.now[:alert] = "Не удалось удалить рейтинг: #{e.message}"
    render :new
  end

  def destroy_unit
    list_unit = @extratings_list.extratings_list_units.includes(:extratings_unit, :extratings_scores).find(params[:unit_link_id])
    unit_name = list_unit.extratings_unit&.name_ru.presence || list_unit.extratings_unit&.name_eng.presence || "без названия"
    deleted_scores = list_unit.extratings_scores.count

    list_unit.destroy!

    redirect_to edit_extratings_list_path(@extratings_list), notice: "Единица измерения \"#{unit_name}\" удалена из рейтинга. Удалено значений в системах: #{deleted_scores}."
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_extratings_list_path(@extratings_list), alert: "Единица измерения для этого рейтинга не найдена."
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    redirect_to edit_extratings_list_path(@extratings_list), alert: "Не удалось удалить единицу измерения: #{e.message}"
  end

  private

  def require_top50_superadmin
    unless current_user&.may_edit_top50?
      flash[:error] = "Недостаточно полномочий для доступа к данной секции"
      redirect_to root_path
    end
  end

  def set_extratings_list
    @extratings_list = ExtratingsList.find(params[:id])
  end

  def load_existing_units
    @existing_units = ExtratingsUnit.order(:name_ru, :name_eng)
  end

  def load_usage_counts
    @rating_usage_counts = rating_usage_counts(@extratings_list)
    @scores_count_by_list_unit_id = @extratings_list.extratings_list_units
      .joins('LEFT JOIN extratings_scores ON extratings_scores.extratings_list_unit_id = extratings_list_units.id')
      .group('extratings_list_units.id')
      .count('extratings_scores.id')
  end

  def rating_usage_counts(list)
    editions = list.extratings_editions
    entries = ExtratingsEntry.where(extratings_edition_id: editions.select(:id))
    {
      editions: editions.count,
      entries: entries.count,
      scores: ExtratingsScore.where(extratings_entry_id: entries.select(:id)).count
    }
  end

  def build_list_unit_if_needed
    @extratings_list.extratings_list_units.build if @extratings_list.extratings_list_units.empty?
  end

  def extratings_list_params
    params.require(:extratings_list).permit(
      :name_ru, :name_eng, :description_ru, :description_eng, :url,
      extratings_list_units_attributes: [
        :priority,
        :extratings_unit_id,
        extratings_unit_attributes: [:name_ru, :name_eng, :measure_unit, :base_multiplier]
      ]
    )
  end
end
  