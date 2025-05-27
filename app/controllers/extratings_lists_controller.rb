class ExtratingsListsController < ApplicationController
    def new
        @extratings_list = ExtratingsList.new
        list_unit = @extratings_list.extratings_list_units.build
        list_unit.build_extratings_unit
        @existing_units = ExtratingsUnit.all
    end
  
    def create
        @extratings_list = ExtratingsList.new(extratings_list_params)
        
        if @extratings_list.save
            redirect_to new_extratings_entry_path, notice: "Рейтинг успешно создан"
        else
            @existing_units = ExtratingsUnit.all
            render :new
        end
    end
  
    private

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
  