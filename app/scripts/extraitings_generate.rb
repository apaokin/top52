# # # ExtratingsEntry.delete_all
# # # ExtratingsEditions.delete_all
# # # ExtratingsList.delete_all


# # # === Шаг 1. Создание extratings_list ===
# # # list1 = ExtratingsList.create!(
# # #   name_ru: 'Top 500',
# # #   name_eng: 'Top 500',
# # #   description_ru: 'TOP500 — это международный рейтинг, оценивающий и ранжирующий 500 самых мощных суперкомпьютеров мира по их производительности при решении плотных систем линейных уравнений с помощью теста LINPACK (Rmax, измеряется в FLOPS).',
# # #   description_eng: 'TOP500 is an international rating that evaluates and ranks the 500 most powerful supercomputers in the world by their performance in solving dense systems of linear equations using the LINPACK test (Rmax, measured in FLOPS).',
# # #   url: 'https://top500.org'
# # # )

# # # list2 = ExtratingsList.create!(
# # #   name_ru: 'GRAPH 500',
# # #   name_eng: 'GRAPH500',
# # #   description_ru: 'Graph500 — это международный рейтинг суперкомпьютеров, измеряющий их производительность в обработке больших графов, таких как социальные сети или нейронные сети, с помощью теста обхода графа на основе поиска в ширину (BFS).',
# # #   description_eng: 'Graph500 is an international ranking of supercomputers that measures their performance in processing large graphs, such as social networks or neural networks, using the breadth-first search (BFS) graph traversal benchmark.',
# # #   url: 'https://graph500.org/'
# # # )

# # # list3 = ExtratingsList.create!(
# # #   name_ru: 'HPCG',
# # #   name_eng: 'HPCG',
# # #   description_ru: 'HPCG — это международный рейтинг суперкомпьютеров, оценивающий их производительность при выполнении прикладных задач, основанных на методе сопряжённых градиентов для разреженных систем линейных уравнений, что приближено к реальной работе научных и инженерных приложений.',
# # #   description_eng: 'HPCG is an international ranking of supercomputers that evaluates their performance in executing applied tasks based on the conjugate gradient method for sparse systems of linear equations, which is close to the real work of scientific and engineering applications.',
# # #   url: 'https://top500.org/lists/hpcg/'
# # # )

# # # list4 = ExtratingsList.create!(
# # #   name_ru: 'GREEN 500',
# # #   name_eng: 'GREEN 500',
# # #   description_ru: 'Green500 — это международный рейтинг суперкомпьютеров, ранжирующий их по энергоэффективности, измеряемой в MFLOPS/W (миллионы операций с плавающей запятой в секунду на ватт).',
# # #   description_eng: 'Green500 is an international ranking of supercomputers based on their energy efficiency, measured in MFLOPS/W (millions of floating-point operations per second per watt).',
# # #   url: 'https://top500.org/lists/green500/'
# # # )

# # # === Шаг 2. Создание extratings_edition ===
# green500 = ExtratingsList.find_by(name_ru: 'GREEN 500')

# edition_green500_Lomonosov2_1 = ExtratingsEditions.find(53)
# # edition_green500_Lomonosov2_1 = ExtratingsEditions.create!(
# #   extratings_list_id: green500.id,
# #   edition_number: 10,
# #   publication_date: Date.new(2017,11,01),
# #   edition_multiplier: 1
# # )

# relation2 = Top50Relation.find_by(prim_obj_id: 4220)

# entry_Lomonosov_2_4220_1 = ExtratingsEntry.find(53)
# # = ExtratingsEntry.create!(
# #   system_id: relation2.prim_obj_id,
# #   extratings_edition_id: edition_green500_Lomonosov2_1.id,
# #   position: 130
# # )

# # # 1. Создаем единицу измерения
# energy_efficiency = ExtratingsUnit.find_by(name_ru: 'Energy Efficiency')

# # 2. Привязываем ее к уже существующему рейтингу (например, TOP500)

# greeen500_unit_1 = ExtratingsListUnit.find_by(extratings_list_id: '30')
# # 3. Привязываем значение к записи (entry)
# Lomonosov2 = ExtratingsEntry.find(53)

# lom2_green_score_1 = ExtratingsScore.create!(
#   extratings_entry: Lomonosov2,
#   extratings_list_unit: greeen500_unit_1,
#   score: 1.948,
#   normalized_score: 1.948
# )

# # # edition2 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 73,
# # #   publication_date: Date.new(2024,06,01),
# # #   edition_multiplier: 1000
# # # )


# # # edition3 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 72,
# # #   publication_date: Date.new(2023,11,01),
# # #   edition_multiplier: 1000
# # # )

# # # edition4 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 71,
# # #   publication_date: Date.new(2023,06,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition5 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 70,
# # #   publication_date: Date.new(2022,11,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition6 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 69,
# # #   publication_date: Date.new(2022,06,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition7 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 68,
# # #   publication_date: Date.new(2021,11,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition8 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 67,
# # #   publication_date: Date.new(2021,06,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition9 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 66,
# # #   publication_date: Date.new(2020,11,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition10 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 65,
# # #   publication_date: Date.new(2020,06,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition11 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 64,
# # #   publication_date: Date.new(2019,11,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition12 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 63,
# # #   publication_date: Date.new(2019,06,01),
# # #   edition_multiplier: 1000
# # # )
# # # edition13 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 62,
# # #   publication_date: Date.new(2018,11,01),
# # #   edition_multiplier: 1
# # # )
# # # edition14 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 61,
# # #   publication_date: Date.new(2018,06,01),
# # #   edition_multiplier: 1
# # # )
# # # edition15 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 60,
# # #   publication_date: Date.new(2017,11,01),
# # #   edition_multiplier: 1
# # # )
# # # edition16 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 59,
# # #   publication_date: Date.new(2017,06,01),
# # #   edition_multiplier: 1
# # # )
# # # edition17 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 58,
# # #   publication_date: Date.new(2016,11,01),
# # #   edition_multiplier: 1
# # # )
# # # edition18 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 58,
# # #   publication_date: Date.new(2016,06,01),
# # #   edition_multiplier: 1
# # # )
# # # edition19 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 57,
# # #   publication_date: Date.new(2015,11,01),
# # #   edition_multiplier: 1
# # # )
# # # edition20 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 56,
# # #   publication_date: Date.new(2015,06,01),
# # #   edition_multiplier: 1
# # # )
# # # edition21 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 55,
# # #   publication_date: Date.new(2014,11,01),
# # #   edition_multiplier: 1
# # # )
# # # edition22 = ExtratingsEditions.create!(
# # #   extratings_list_id: list1.id,
# # #   edition_number: 54,
# # #   publication_date: Date.new(2014,06,01),
# # #   edition_multiplier: 1
# # # )
# # # === Шаг 3. Получение top50_relation с prim_obj_id = 4568 ===
# # # relation1 = Top50Relation.find_by(prim_obj_id: 521)
# # # relation2 = Top50Relation.find_by(prim_obj_id: 505)

# # # === Шаг 4. Создание extratings_entry ===
# # entry1 = ExtratingsEntry.create!(
# #   system_id: relation1.prim_obj_id,
# #   extratings_edition_id: edition1.id,
# #   position: 451
# # )

# # # entry2 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition2.id,
# # #   position: 406
# # # )
# # # entry3 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition3.id,
# # #   position: 369
# # # )

# # # entry4 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition4.id,
# # #   position: 329
# # # )
# # # entry5 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition5.id,
# # #   position: 290
# # # )
# # # entry6 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition6.id,
# # #   position: 262
# # # )
# # # entry7 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition7.id,
# # #   position: 241
# # # )
# # # entry8 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition8.id,
# # #   position: 199
# # # )
# # # entry9 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition9.id,
# # #   position: 156
# # # )
# # # entry10 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition10.id,
# # #   position: 130
# # # )
# # # entry11 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition11.id,
# # #   position: 107
# # # )
# # # entry12 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition12.id,
# # #   position: 93
# # # )
# # # entry13 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition13.id,
# # #   position: 79
# # # )
# # # entry14 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition14.id,
# # #   position: 72
# # # )
# # # entry15 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition15.id,
# # #   position: 64
# # # )
# # # entry16 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition16.id,
# # #   position: 60
# # # )
# # # entry17 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition17.id,
# # #   position: 53
# # # )
# # # entry18 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition18.id,
# # #   position: 42
# # # )
# # # entry19 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition19.id,
# # #   position: 36
# # # )
# # # entry20 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition20.id,
# # #   position: 31
# # # )
# # # entry21 = ExtratingsEntry.create!(
# # #   system_id: relation1.prim_obj_id,
# # #   extratings_edition_id: edition21.id,
# # #   position: 23
# # # )
# # entry22 = ExtratingsEntry.create!(
# #   system_id: relation2.prim_obj_id,
# #   extratings_edition_id: edition22.id,
# #   position: 130
# # )


# # # 1. Создаем единицу измерения
# Rmax = ExtratingsUnit.create!(
#   name_ru: "Rmax",
#   name_eng: "Rmax",
#   measure_unit: 'TFLOP/S', # кодовое обозначение
#   base_multiplier: 1.0
# )
# Rpeak = ExtratingsUnit.create!(
#   name_ru: "Rpeak",
#   name_eng: "Rpeak",
#   measure_unit: 'TFLOP/S', # кодовое обозначение
#   base_multiplier: 1.0
# )

# # 2. Привязываем ее к уже существующему рейтингу (например, TOP500)

#  list_unit_1 = ExtratingsListUnit.find(31)
#  ExtratingsListUnit.create!(
#   extratings_list: top500,
#   extratings_unit: Rmax,
#   priority: 1
# )
#  list_unit_2 = ExtratingsListUnit.find(32)
#ExtratingsListUnit.create!(
#   extratings_list: top500,
#   extratings_unit: Rpeak,
#   priority: 2
# )
# 3. Привязываем значение к записи (entry)
# Lomonosov2 = ExtratingsEntry.find(25)

# lom2_451_RMAX = ExtratingsScore.create!(
#   extratings_entry: Lomonosov2,
#   extratings_list_unit: list_unit_1,
#   score: 2478.00,
#   normalized_score: 2478.00
# )
# lom2_451_RPEAK = ExtratingsScore.create!(
#   extratings_entry: Lomonosov2,
#   extratings_list_unit: list_unit_2,
#   score: 4946.79,
#   normalized_score: 4946.79
# )
# TOP500 = ExtratingsList.find(27)
# relation1 = Top50Relation.find_by(prim_obj_id: 6374)

# edition11 = ExtratingsEditions.create!(
#   extratings_list_id: TOP500,
#   edition_number: 68,
#   publication_date: Date.new(2021,11,01),
#   edition_multiplier: 1
# )

# entry22 = ExtratingsEntry.create!(
#   system_id: relation1.prim_obj_id,
#   extratings_edition_id: edition11.id,
#   position: 44
# )

# # # 1. Создаем единицу измерения
# list_unit_1 = ExtratingsListUnit.find(31)
# list_unit_2 = ExtratingsListUnit.find(32)

# lom2_hpcg = ExtratingsScore.create!(
#   extratings_entry: entry22,
#   extratings_list_unit: list_unit_1,
#   score: 31.50,
#   normalized_score: 31.50
# )
#############################################################
# TOP500 = ExtratingsList.find(27);



# # 1. Создаем единицу измерения
#  Rmax = ExtratingsUnit.find(59)
#  Rpeak = ExtratingsUnit.find(60)

# # Rpeak = ExtratingsUnit.create!(
# #   name_ru: "Rpeak",
# #   name_eng: "Rpeak",
# #   measure_unit: 'PFLOP/S', # кодовое обозначение
# #   base_multiplier: 1.0
# # )

#  list_unit_1 =  ExtratingsListUnit.create!(
#   extratings_list: TOP500,
#   extratings_unit: Rmax,
#   priority: 1
# )
#  list_unit_2 = ExtratingsListUnit.create!(
#   extratings_list: TOP500,
#   extratings_unit: Rpeak,
#   priority: 2
# )

#Cоздание системы с новым Score

# TOP500 = ExtratingsList.find(27)
# relation1 = Top50Relation.find_by(prim_obj_id: 6374)

# edition11 = ExtratingsEditions.create!(
#   extratings_list_id: TOP500.id,
#   edition_number: 68,
#   publication_date: Date.new(2021,11,01),
#   edition_multiplier: 1
# )

# entry22 = ExtratingsEntry.create!(
#   system_id: relation1.prim_obj_id,
#   extratings_edition_id: edition11.id,
#   position: 19
# )

# # # 1. Создаем единицу измерения
# list_unit_1 = ExtratingsListUnit.find(41)
# list_unit_2 = ExtratingsListUnit.find(42)

# Cherv_Rmax = ExtratingsScore.create!(
#   extratings_entry: entry22,
#   extratings_list_unit: list_unit_1,
#   score: 21.53,
#   normalized_score: 21.53
# )

# Cherv_Rpeak = ExtratingsScore.create!(
#   extratings_entry: entry22,
#   extratings_list_unit: list_unit_2,
#   score: 29.42,
#   normalized_score: 29.42
# )

#Cоздание системы и привязка к существующему Score
##################################################################     TOP 500   ######################################################################   

# Green500 = ExtratingsList.find(27)
# relation1 = Top50Relation.find_by(prim_obj_id: 485)

# edition11 = ExtratingsEditions.create!(
#   extratings_list_id: Green500.id,
#   edition_number: 48,
#   publication_date: Date.new(2016,11,01),
#   edition_multiplier: 1
# )

# entry22 = ExtratingsEntry.create!(
#   system_id: relation1.prim_obj_id,
#   extratings_edition_id: edition11.id,
#   position: 460
# )

# # # # 1. Создаем единицу измерения
# list_unit_1 = ExtratingsListUnit.find(31)
# list_unit_2 = ExtratingsListUnit.find(32)

# Cherv_Rmax = ExtratingsScore.create!(
#   extratings_entry: entry22,
#   extratings_list_unit: list_unit_1,
#   score: 375.70,
#   normalized_score: 375.70
# )

# Cherv_Rpeak = ExtratingsScore.create!(
#   extratings_entry: entry22,
#   extratings_list_unit: list_unit_2,
#   score: 523.85,
#   normalized_score: 523.83
# )

##################################################################     GREEN 500   ######################################################################   

# Green500 = ExtratingsList.find(30)
# relation1 = Top50Relation.find_by(prim_obj_id: 523)

# edition11 = ExtratingsEditions.create!(
#   extratings_list_id: Green500.id,
#   edition_number: 8,
#   publication_date: Date.new(2016,11,01),
#   edition_multiplier: 1
# )

# entry22 = ExtratingsEntry.create!(
#   system_id: relation1.prim_obj_id,
#   extratings_edition_id: edition11.id,
#   position: 419
# )

# # # # 1. Создаем единицу измерения
# list_unit_1 = ExtratingsListUnit.find(43)

# GAL_GREEN500 = ExtratingsScore.create!(
#   extratings_entry: entry22,
#   extratings_list_unit: list_unit_1,
#   score: 897.00,
#   normalized_score: 897.00
# )

Green500 = ExtratingsList.find(28)

TotalPower = ExtratingsUnit.create(
  name_ru: "GTEPS",
  name_eng: "GTEPS",
  measure_unit: '10^9 дуг/c', # кодовое обозначение
  base_multiplier: 1.0
)

 power_unit_1 =  ExtratingsListUnit.create!(
  extratings_list: Green500,
  extratings_unit: TotalPower,
  priority: 1
)





# entry22 = ExtratingsEntry.find(212)

# list_unit_1 = ExtratingsListUnit.find(43)
# GAL_GREEN500 = ExtratingsScore.create!(
#   extratings_entry: entry22,
#   extratings_list_unit: list_unit_1,
#   score: 320.000,
#   normalized_score: 320.000
# )



