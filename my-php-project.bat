@echo off
::%~n0это имя файла
set PROJECT_NAME=%~n0

mkdir %PROJECT_NAME%\app\public, %PROJECT_NAME%\app\src, %PROJECT_NAME%\app\config
mkdir %PROJECT_NAME%\docker, %PROJECT_NAME%\docker\nginx, %PROJECT_NAME%\docker\php, %PROJECT_NAME%\docker\mysql

::type nul > %PROJECT_NAME%\docker\nginx\Dockerfile
(echo FROM nginx:alpine
echo COPY default.conf /etc/nginx/conf.d/default.conf
) > %PROJECT_NAME%\docker\nginx\Dockerfile

:: конфиг Nginx для php-fpm
(echo server {
echo     listen 80;
echo     root /var/www/html;
echo     index index.php index.html;
echo. 
echo     location / {
echo         try_files $uri $uri/ /index.php$query_string;
echo     }
echo. 
echo     location ~ \.php$ {
echo         fastcgi_pass php:9000;  # Указываем сервис PHP
echo         fastcgi_index index.php;
echo         include fastcgi_params;
echo         fastcgi_param SCRIPT_FILENAME
echo         $document_root$fastcgi_script_name;
echo     }
echo }
) > %PROJECT_NAME%\docker\nginx\default.conf

::Пример для PHP 8.2 FPM с расширениями:
(echo FROM php:8.2-fpm-alpine
echo # "Установка расширений"
echo RUN docker-php-ext-install pdo pdo_mysql mysqli
echo # "Копируем кастомный php.ini (если есть)"
echo COPY php.ini /usr/local/etc/php/
echo # "Устанавливаем Composer (опционально)"
echo #COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
) > %PROJECT_NAME%\docker\php\Dockerfile

type nul > %PROJECT_NAME%\docker\php\php.ini
type nul > %PROJECT_NAME%\docker\mysql\Dockerfile
type nul > %PROJECT_NAME%\docker\mysql\init

mkdir %PROJECT_NAME%\logs\nginx, %PROJECT_NAME%\logs\php
mkdir %PROJECT_NAME%\database

(
echo services:
echo   nginx:
echo     build: ./docker/nginx
echo     ports:
echo       - "80:80"
echo     volumes:
echo       - ./app/public:/var/www/html
echo       - ./logs/nginx:/var/log/nginx
echo     depends_on:
echo       - php
echo. 
echo. 
echo   php:
echo     build: ./docker/php
echo     volumes:
echo       - ./app/public:/var/www/html
echo       - ./docker/php/php/ini:/usr/local/etc/php/conf.d/custom.ini
echo. 
echo. 
echo   mysql:
echo     image: mysql:8.0
echo     environment:
echo       MYSQL_DATABASE: myapp
echo       MYSQL_USER: appuser
echo       MYSQL_PASSWORD: appadmin
echo     volumes:
echo       - ./database:/var/lib/mysql
echo       - ./dockermysql/init:/docker-entrypoint-initdb.d
) > %PROJECT_NAME%\docker-compose.yml

echo "<?php echo 'Hello from %PROJECT_NAME%'?>" > %PROJECT_NAME%\app\public\index.php
pause