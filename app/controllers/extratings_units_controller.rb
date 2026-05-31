class ExtratingsUnitsController < ApplicationController
  before_action :require_top50_superadmin
  before_action :set_extratings_unit, only: [:edit, :update, :destroy]
  before_action :load_usage_counts, only: [:edit, :destroy]

  def new
    @extratings_unit = ExtratingsUnit.new
  end

  def create
    @extratings_unit = ExtratingsUnit.new(extratings_unit_params)

    if @extratings_unit.save
      redirect_to edit_extratings_unit_path(@extratings_unit), notice: "Единица измерения успешно создана"
    else
      render :new
    end
  end

  def edit
    render :new
  end

  def update
    if @extratings_unit.update(extratings_unit_params)
      redirect_to edit_extratings_unit_path(@extratings_unit), notice: "Единица измерения успешно обновлена"
    else
      load_usage_counts
      render :new
    end
  end

  def destroy
    counts = usage_counts(@extratings_unit)
    unit_name = @extratings_unit.name_ru.presence || @extratings_unit.name_eng.presence || @extratings_unit.measure_unit

    ActiveRecord::Base.transaction do
      @extratings_unit.destroy!
    end

    redirect_to new_extratings_list_path, notice: "Единица измерения \"#{unit_name}\" удалена. Удалено связей с рейтингами: #{counts[:list_links]}, затронуто рейтингов: #{counts[:lists]}, удалено значений в системах: #{counts[:scores]}."
  rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::RecordInvalid => e
    load_usage_counts
    flash.now[:alert] = "Не удалось удалить единицу измерения: #{e.message}"
    render :new
  end

  private

  def require_top50_superadmin
    unless current_user&.may_edit_top50?
      flash[:error] = "Недостаточно полномочий для доступа к данной секции"
      redirect_to root_path
    end
  end

  def set_extratings_unit
    @extratings_unit = ExtratingsUnit.find(params[:id])
  end

  def load_usage_counts
    @unit_usage_counts = usage_counts(@extratings_unit)
  end

  def usage_counts(unit)
    list_units = unit.extratings_list_units
    {
      list_links: list_units.count,
      lists: list_units.select(:extratings_list_id).distinct.count,
      scores: ExtratingsScore.where(extratings_list_unit_id: list_units.select(:id)).count
    }
  end

  def extratings_unit_params
    params.require(:extratings_unit).permit(:name_ru, :name_eng, :measure_unit, :base_multiplier)
  end
end
  