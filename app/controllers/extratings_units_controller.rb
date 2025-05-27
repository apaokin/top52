class ExtratingsUnitsController < ApplicationController
    def new
      @extratings_unit = ExtratingsUnit.new
    end
  
    def create
      @extratings_unit = ExtratingsUnit.new(extratings_unit_params)
      if @extratings_unit.save
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
  