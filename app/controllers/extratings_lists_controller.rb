class ExtratingsListsController < ApplicationController
    def new
        @extratings_list = ExtratingsList.new
        list_unit = @extratings_list.extratings_list_units.build
        list_unit.build_extratings_unit
        @existing_units = ExtratingsUnit.all
    end
  
    def create
        @extratings_list = ExtratingsList.new(extratings_list_params)
        
        # Валидация основных полей
        if @extratings_list.name_ru.blank?
            @extratings_list.errors.add(:name_ru, "не может быть пустым")
        end
        
        if @extratings_list.name_eng.blank?
            @extratings_list.errors.add(:name_eng, "не может быть пустым")
        end
        
        # Валидация единиц измерения только если они есть
        if @extratings_list.extratings_list_units.any?
            @extratings_list.extratings_list_units.each do |unit|
                if unit.extratings_unit_id.blank? && unit.extratings_unit.blank?
                    @extratings_list.errors.add(:base, "Для каждой единицы измерения необходимо выбрать существующую или создать новую")
                end
                
                if unit.extratings_unit.present?
                    if unit.extratings_unit.name_ru.blank?
                        @extratings_list.errors.add(:base, "Название единицы измерения (RU) не может быть пустым")
                    end
                    
                    if unit.extratings_unit.name_eng.blank?
                        @extratings_list.errors.add(:base, "Название единицы измерения (EN) не может быть пустым")
                    end
                    
                    if unit.extratings_unit.measure_unit.blank?
                        @extratings_list.errors.add(:base, "Обозначение единицы измерения не может быть пустым")
                    end
                end
            end
        end
        
        # Сохраняем только если нет ошибок
        if @extratings_list.errors.empty?
            if @extratings_list.save
                redirect_to new_extratings_entry_path, notice: "Рейтинг успешно создан"
            else
                @existing_units = ExtratingsUnit.all
                render :new
            end
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
  