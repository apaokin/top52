class ExtratingsUnitsController < ApplicationController
    def new
      @extratings_unit = ExtratingsUnit.new
    end
  
    def create
      @extratings_unit = ExtratingsUnit.new(extratings_unit_params)
      
      # Дополнительная валидация
      if @extratings_unit.name_ru.blank?
        @extratings_unit.errors.add(:name_ru, "не может быть пустым")
      end
      
      if @extratings_unit.name_eng.blank?
        @extratings_unit.errors.add(:name_eng, "не может быть пустым")
      end
      
      if @extratings_unit.measure_unit.blank?
        @extratings_unit.errors.add(:measure_unit, "не может быть пустым")
      end
      
      if @extratings_unit.base_multiplier.blank? || @extratings_unit.base_multiplier <= 0
        @extratings_unit.errors.add(:base_multiplier, "должен быть больше 0")
      end
      
      if @extratings_unit.errors.empty? && @extratings_unit.save
        redirect_to new_extratings_list_path, notice: "Единица измерения успешно создана"
      else
        render :new
      end
    end
  
    private
  
    def extratings_unit_params
      params.require(:extratings_unit).permit(:name_ru, :name_eng, :measure_unit, :base_multiplier)
    end
  end
  