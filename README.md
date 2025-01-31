
## Install Top50 inside  docker container (NOT for production)
Requires: Docker and Docker Composer
### Installation

1. copy repo `git clone https://github.com/apaokin/top52.git`
1. execute `cd top52/docker`
1. build and run containers `docker-compose up`. Add `-d` flag for detached mode: run containers in background. Now your containers are launched, you can press  ctrl + c to turn them off.
1. check status of containers `docker-compose ps`
1. install database and run seeds.rb while your containers are running: `docker-compose exec top bundle exec rake db:setup`
1. visit `http://localhost:4000/` (login: `admin@octoshell.ru`, password: `123456`)
### Usage

Here Top50 is run inside isolated container. This introduces difficulties, espcially for inexperienced developers, and can overwhelm advantages of fast and easy installation compared to direct installation. When you run rails server in development environment, you expect some code changes to take effect after next request is sent (F5 driven development). It works here too, thanks to bind mounts: octoshell-v2 directory on the host machine is mounted into a container. Postgres database is saved inside volume, so you can stop and start containers as much as you like without data loss.

But still sometimes you have to run commands inside container. These commands have to be started with `docker-compose exec top` or you can run bash
`docker-compose exec top bash` when the containers are running. But it can not help when you have to bundle and the app container is turned off. Just write `bundle install` in `docker/entrypoints/docker-entrypoint.sh` instead of `bin/rails server` command.

- Start the containers: `docker-compose up`
- Stop the containers: `docker-compose down`
- Read stdout of containers, when in detached mode: `docker-compose logs`
- Reinstall container: `docker-compose build` (you might need to remove volumes sometimes using the special extra commands)


## Установка и запуск без докера
### Окружение development.
В большинстве случаев этого окружения достаточно для студентов. Докер контейнеры (cм выше) ставятся быстрее и в автоматическом режиме. Установить приложение с помощью этой инструкции может быть полезно для лучшего понимания зависимостей проекта.
1. `git clone <репозиторий>`
1.  `cd top52`
2. `sudo apt-get install git curl wget build-essential libssl-dev libreadline-dev zlib1g-dev libpq-dev nodejs`
3. `sudo apt-get install postgresql` (найти текущую версию Postgres из `sudo apt-cache search postgresql`)
4. Поставить rbenv: `curl https://raw.githubusercontent.com/rbenv/rbenv-installer/master/bin/rbenv-installer | bash`
1. Добавить эти строки  ~/.bashrc для автоматической загрузки rbenv и перезапустить терминал:
    ```
      export PATH=~/.rbenv/bin:$PATH
      eval "$(rbenv init -)"
    ```
5. rbenv  install 2.4.5
5. Установить bundler в папке с проектом: `gem install bundler -v $(cat Gemfile.lock | grep -A1 "BUNDLED WITH" | tail -n 1 | xargs)`
5. rbenv rehash
6. `bundle install`.
7. `sudo -u postgres psql`<br />
postgres=# `create user dbuser_dev;`<br />
postgres=# `\password dbuser_dev`  # Password: `pass`<br />
postgres=# `alter user dbuser_dev CREATEDB;`
8. Убедиться, что postgres разрешает подсоединяться Вашему пользователю к базам данных проекта. Для этого надо в pg_hba.conf изменить/добавить строку формата `local all all <something>` на `local all all md5`. После этого перезапустить СУБД:  `sudo systemctl restart postgresql`
8. `rake db:setup`
9. Если хотите генерировать сертификаты, подтверждающие положение системы в рейтинге и которые, скорее всего, Вам не понадобится: `sudo apt-get install php7.2 inkscape ghostscript`

### Production
1. Повторить шаги для окружения development.
9. Аналогично создать пользователя БД postgres для production
10. Установить плагин rbenv-vars для rbenv
11. В папке с проектом создать и заполнить файл .rbenv-vars:<br />
SECRET_KEY_BASE={секретный ключ, который можно сгенерировать командой rake secret}<br />
APP_DB_USER={пользователь БД, созданный для production на шаге 9}<br />
APP_DB_PASSWORD={пароль пользователя БД, созданного для production, заданный на шаге 9}<br />
12. `rake db:setup RAILS_ENV=production`
13. `rake assets:precompile`
14. Для запуска приложения после настройки, выполнить: `bundle exec puma`
<br /><br />Для разворачивания сервиса наружу:
15. Установить Nginx (`sudo apt-get install nginx`)
16. Использовать конфиг Nginx из ./shared/top52 (поместить его в /etc/nginx/sites-available и в /etc/nginx/sites-enabled)
17. Перезапустить nginx (`sudo service nginx restart`)
