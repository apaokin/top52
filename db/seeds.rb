# encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

ActiveRecord::Base.connection.tables.each do |table|
  next if table == 'schema_migrations'

  ActiveRecord::Base.connection.execute("TRUNCATE #{table} CASCADE")
end

Group.superadmins
Group.authorized
admin = User.create!(email: "admin@octoshell.ru", access_state: 'active',
                     password: "123456", password_confirmation: '123456')
admin.activate!
admin.groups << Group.superadmins
types = [
  {"name"=>"Машина (ЭВМ)",
  "name_eng"=>"Machine",
  "is_valid"=>1,
  "comment"=>"Added type"},
 {"name"=>"Контактное лицо",
  "name_eng"=>"Contact",
  "is_valid"=>1,
  "comment"=>"Added type"},
 {"name"=>"Производитель",
  "name_eng"=>"Vendor",
  "is_valid"=>1,
  "comment"=>"Added type"},
 {"name"=>"Организация",
  "name_eng"=>"Organization",
  "is_valid"=>1,
  "comment"=>"Added type"},
 {"name"=>"Вычислительный узел",
  "name_eng"=>"Compute node",
  "is_valid"=>1,
  "comment"=>"Added type"},
 {"name"=>"CPU", "name_eng"=>"CPU", "is_valid"=>1, "comment"=>"Added type"},
 {"name"=>"Бенчмарк",
  "name_eng"=>"Benchmark",
  "is_valid"=>1,
  "comment"=>"Added type"},
 {"name"=>"Результат бенчмарка",
  "name_eng"=>"Benchmark result",
  "is_valid"=>1,
  "comment"=>"Added type"},
 {"name"=>"Серия бенчмарков",
  "name_eng"=>"Bunch of benchmarks",
  "is_valid"=>0,
  "comment"=>"Added type"},
 {"name"=>"Ускоритель",
  "name_eng"=>"Accelerator",
  "is_valid"=>0,
  "comment"=>"Added type"},
 {"name"=>"GPU",
  "name_eng"=>"GPU",
  "is_valid"=>1,
  "comment"=>"Added type",
  "parent"=>9},
 {"name"=>"Сопроцессор",
  "name_eng"=>"Coprocessor",
  "is_valid"=>1,
  "comment"=>"Added type",
  "parent"=>9}
]

types = types.map { |a| [a, Top50ObjectType.create!(a.except('parent'))] }
types.select { |a, _o| a['parent'] }.each do |a, o|
  o.update!(parent_id: types[a['parent']].second.id)
end

Top50RelationType.create!(
  [{"name"=>"Содержит", "name_eng"=>"Contains", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Предшествует", "name_eng"=>"Precedes", "is_valid"=>1, "comment"=>"Added type"}]
)

Top50Attribute.create!(
  [{"name"=>"Название", "name_eng"=>"Name", "attr_type"=>1, "is_valid"=>1, "comment"=>"Added attribute"},
   {"name"=>"Объем ОЗУ (ГБ)", "name_eng"=>"RAM size (GB)", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Название(англ)", "name_eng"=>"Name(eng)", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Количество ядер", "name_eng"=>"Number of cores", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Приоритет узла", "name_eng"=>"Node priority", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Linpack Nmax", "name_eng"=>"Linpack Nmax", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"ОС", "name_eng"=>"OS", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Область применения", "name_eng"=>"Application area", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Коммуникационная сеть", "name_eng"=>"Communication network", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Сервисная сеть", "name_eng"=>"Service network", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Транспортная сеть", "name_eng"=>"Transport network", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Количество CPU", "name_eng"=>"Number of CPUs", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель CPU", "name_eng"=>"CPU model", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель GPU", "name_eng"=>"GPU model", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Номер редакции списка", "name_eng"=>"Edition number", "attr_type"=>1, "is_valid"=>1, "comment"=>"Added attribute"},
   {"name"=>"Дата редакции списка", "name_eng"=>"Edition date", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель CPU", "name_eng"=>"CPU Vendor", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель GPU", "name_eng"=>"GPU Vendor", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель сопроцессора", "name_eng"=>"Coprocessor model", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель сопроцессоров", "name_eng"=>"Coprocessor Vendor", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Тактовая частота (МГц)", "name_eng"=>"Clock frequency (MHz)", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Топология", "name_eng"=>"Topology", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Семейство CPU", "name_eng"=>"CPU family", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Семейство коммуникационной сети", "name_eng"=>"Communication network family", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Поколение CPU", "name_eng"=>"CPU generation", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Rpeak (МФлоп/с)", "name_eng"=>"Rpeak (MFlop/s)", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Количество микроядер", "name_eng"=>"Number of micro cores", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель ускорителя", "name_eng"=>"Accelerator model", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель ускорителей", "name_eng"=>"Accelerator Vendor", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Выдача Linpack", "name_eng"=>"Linpack Output", "attr_type"=>1, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Тип узла", "name_eng"=>"Node platform", "attr_type"=>2, "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель типа узла", "name_eng"=>"Node platform Vendor", "attr_type"=>2, "is_valid"=>1, "comment"=>nil}]
)
Top50Benchmark.create!("name"=>"Linpack", "name_eng"=>"Linpack",
                       "is_valid"=>1, "comment"=>nil,
                       top50_measure_unit: Top50MeasureUnit.create!("name"=>"МФлоп/с",
                                                                    "name_eng"=>"MFlop/s",
                                                                    "asc_order"=>0, "is_valid"=>0,
                                                                    "comment"=>"Added type"))

Top50MeasureUnit.create!("name"=>"место", "name_eng"=>"place", "asc_order"=>1,
                         "is_valid"=>0, "comment"=>"Added type")

Top50Dictionary.create!(
  [{"name"=>"Операционные системы", "name_eng"=>"Operating systems", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Области применения", "name_eng"=>"Application areas", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Компьютерные сети", "name_eng"=>"Computer networks", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель CPU", "name_eng"=>"CPU model", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель GPU", "name_eng"=>"GPU model", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель CPU", "name_eng"=>"CPU Vendor", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель GPU", "name_eng"=>"GPU Vendor", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель сопроцессора", "name_eng"=>"Coprocessor model", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель сопроцессоров", "name_eng"=>"Coprocessor Vendor", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Топологии", "name_eng"=>"Topologies", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Семейства CPU", "name_eng"=>"CPU families", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Семейства сетей", "name_eng"=>"Net families", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Поколения CPU", "name_eng"=>"CPU generations", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель ускорителей", "name_eng"=>"Accelerator Vendor", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Модель ускорителя", "name_eng"=>"Accelerator model", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Тип узла", "name_eng"=>"Node platform", "is_valid"=>1, "comment"=>nil},
   {"name"=>"Производитель типов узлов", "name_eng"=>"Node platform Vendor", "is_valid"=>1, "comment"=>nil}]
)

gid = Top50Dictionary.find_by!(name_eng: 'GPU Vendor').id

Top50DictionaryElem.create!(
  [{"name"=>"NVIDIA", "name_eng"=>"NVIDIA", "dict_id"=>gid, "is_valid"=>1, "comment"=>nil},
   {"name"=>"AMD", "name_eng"=>"AMD", "dict_id"=>gid, "is_valid"=>1, "comment"=>nil}]
)

prev = Top50Object.create!("type_id"=>Top50ObjectType.find_by_name_eng!('Bunch of benchmarks').id,
                           "is_valid"=>nil, "comment"=>nil)
publ = Top50Object.create!("type_id"=>Top50ObjectType.find_by_name_eng!('Bunch of benchmarks').id,
                           "is_valid"=>1, "comment"=>nil)


Top50AttributeValDbval.create!("attr_id"=> Top50Attribute.find_by!(name_eng: "Name(eng)").id,
                               "obj_id"=>publ.id,
                               "value"=>"Top50 position",
                               "is_valid"=>1, "comment"=>nil)
Top50AttributeValDbval.create!("attr_id"=> Top50Attribute.find_by!(name_eng: "Name(eng)").id,
                               "obj_id"=>prev.id,
                               "value"=>"Top50 preview",
                               "is_valid"=>nil, "comment"=>nil)
