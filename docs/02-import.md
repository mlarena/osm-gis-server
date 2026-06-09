# Шаг 2: Импорт данных OSM

Для импорта используется утилита `osm2pgsql`. Рекомендуется использовать режим `--slim` для экономии оперативной памяти и `--hstore` для поддержки дополнительных тегов.

## 1. Подготовка данных

Поместите ваши `.osm.pbf` файлы в директорию `/osmpbf/`.

## 2. Первичный импорт (создание базы)

Первый файл импортируется с флагом `--create`. Это создаст структуру таблиц.


export PGPASSWORD='12345678'

osm2pgsql --create --slim \
    --database gis \
    --username postgres \
    --host localhost \
    --port 5432 \
    --style /usr/share/osm2pgsql/default.style \
    --cache 8192 \
    --number-processes 4 \
    --hstore \
    /osmpbf/monaco-260605.osm.pbf

## 3. Добавление дополнительных регионов

# Все последующие файлы должны импортироваться с флагом `--append`.

# Добавление Крыма
osm2pgsql --append --slim \
    --database gis \
    --username postgres \
    --host localhost \
    --port 5432 \
    --style /usr/share/osm2pgsql/default.style \
    --cache 8192 \
    --number-processes 4 \
    --hstore \
    /osmpbf/crimean-fed-district-latest.osm.pbf

# Добавление Дальнего Востока
osm2pgsql --append --slim \
    --database gis \
    --username postgres \
    --host localhost \
    --port 5432 \
    --style /usr/share/osm2pgsql/default.style \
    --cache 8192 \
    --number-processes 4 \
    --hstore \
    /osmpbf/far-eastern-fed-district-latest.osm.pbf


## 4. Параметры команды

- `--slim`: хранит временные данные в базе (обязательно для больших регионов).
- `--cache`: объем RAM в МБ для кэширования узлов (рекомендуется 1/4 от общего объема RAM).
- `--number-processes`: количество ядер CPU.
- `--hstore`: позволяет хранить теги, не вошедшие в стандартную схему, в отдельном поле.
