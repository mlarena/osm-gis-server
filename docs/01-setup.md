# Шаг 1: Подготовка системы и установка ПО

Инструкция основана на Debian 12.

## 1. Установка необходимых пакетов

Обновите репозитории и установите базовый стек:


apt update
apt install -y postgresql-15 postgis postgresql-15-postgis-3 osm2pgsql osmium-tool curl wget htop iotop sudo
apt install -y postgresql postgresql-contrib postgis osm2pgsql osmium-tool wget unzip ? 


## 2. Настройка пользователя PostgreSQL

Установите пароль для системного пользователя:


sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '12345678';"


## 3. Создание базы данных

Зайдите под пользователем `postgres` и создайте базу `gis` с необходимыми расширениями:


psql -U postgres -h localhost -d postgres

CREATE DATABASE gis;
\c gis
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION hstore;


## 4. Тюнинг PostgreSQL

Выберите подходящий файл конфигурации из папки `configs/` в зависимости от вашего RAM:
- `99-osm-tuning-small.conf` (4GB)
- `99-osm-tuning-medium.conf` (16GB)
- `99-osm-tuning-large.conf` (32GB+)

Скопируйте его в директорию конфигурации PostgreSQL:


cp ./99-osm-tuning-large.conf /etc/postgresql/15/main/conf.d/99-osm-tuning.conf
systemctl restart postgresql


посмотреть расшиения на базе и примененные  настрорйки