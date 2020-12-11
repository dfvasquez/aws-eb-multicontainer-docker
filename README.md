# aws-eb-multicontainer-docker
Repositorio de apoyo para quienes desean realizar un deploy a AWS Elastic Beanstalk utilizando la configuración Multicontainer Docker, la cual permite tener más de un contenedor corriendo en el servidor. Estas configuraciones están hechas basadas en una aplicación que utiliza Ruby on Rails y React. 

Los servicios utilizados que será necesario configurar son: web (aplicación), sidekiq (worker), redis, postgres, mailcatcher y webpacker.

# Docker


## Sobre Docker

Plataforma de código abierto que se encarga de automatizar el despliegue de aplicaciones dentro de contenedores, agregando una capa de abstracción y automatizzación de aplicaciones en múltiples sistemas operativos.

### Pros al usar Docker

* Setups más rápídos
* Igual entorno para el equipo
* Gran comunidad en Docker

### Contras al usar Docker

* Documentación con lagunas
* Gran curva de aprendizaje
* Aumento de tiempo en implementación de nuevos MS
* Los recursos pueden requerir mucho espacio de disco

### Cómo comencé con Docker (recomendación)

1. Breves videos para entender qué es Docker, para qué sirve y los principales servicios que ofrece
2. Lectura rápida de la documentación para revisar más en detalle los comandos que existen
3. Revisión de otras implementaciones de `Dockerfile`, `docker-compose.yml` hecho por otros para poder adaptarlo a la necesidad

## Archivos importantes

* `./.dockerdev` [folder]: carpeta de configuración local. En esta se ubican los archivos principales para que la herramienta Docker Compose los utilice.
* `./.dockerdev/.env.docker` [file]: archivo de variables de entorno locales utilizadas por Docker.
* `./.dockerdev/Dockerfile` [file]: archivo con instrucciones para crear la imagen local de Docker y poder levantar la aplicación.
* `./Dockerfile` [file]: archivo con instrucciones para crear la imagen de producción de Docker y poder levantar la aplicación (imagen necesaria solo si se necesita correr algo adicional en producción, como por ejemplo, compilar los assets antes del deploy).
* `./docker-compose.yml` [file]: archivo que contiene los contenedores y servicios que se requieren para que la aplicación funcione en su totalidad de forma local.
* `./config/environments/development.rb` [file]: archivo que hay que modificar para conectar el servicio mailcatcher para tener una bandeja de entrada que reciba los correos que desencadena sidekiq.

## Comandos importantes

* `docker-compose build`: Comando para construir la imagen de Docker mediante un Dockerfile.
* `docker-compose up`: Comando para levantar los contenedores y servicios definidos en el docker-compose.yml
* `docker container exec -it [container name (image id)] /bin/bash`: Comando para acceder a un contenedor que está corriendo y tener acceso a los archivos que hay en él.
* `docker-compose stop`: Comando para detener los contenedores que  están corriendo. También se pueden detener con Ctrl + C.
* `docker-compose down`: Comando para detener y eliminar los contenedores y las redes creadas, si es que existen. Si deseas eliminar los volúmenes, le puedes agregar el flag -v. Por otro lado, para borrar las imágenes, puedes agregar el flag --rmi seguido de la imagen que quieres eliminar o all en caso de ser todas las relacionadas a los contenedores de este entorno.
* **NOTA**: Para nuestro caso particular, se recomienda hacer el build la primera vez y levantar el contenedor, es decir, correr el comando `docker-compose up --build`. Esto se debe a que tenemos dos configuraciones para construir la imagen, pero nuestro archivo docker-compose.yml está asociada a la imagen local.


## Links

* [Para copiar una base de datos a un contenedor de Docker](https://simkimsia.com/how-to-restore-database-dumps-for-postgres-in-docker-container/)
* [Para copiar archivos locales a un contenedor](https://stackoverflow.com/questions/22907231/how-to-copy-files-from-host-to-docker-container)


# AWS


## Sobre AWS

Plataforma que ofrece más de 175 servicios en la nube que permiten a empresas reducir sus costos y aumentar su agilidad de forma más rápida. A continuación se presentan los servicios configurados por mí y en lo que por consecuencia tengo conocimiento.

### Elastic Beanstalk

Elastic Beanstalk provisiona capacidad, equilibro de carga, escalamiento automático y monitorización de estado de la aplicación, teniendo un control total de los recursos. En términos de costos, solo incluye el precio de los recursos a utilizar para almacenar y ejecutar las aplicaciones.

### Elastic Container Registry

Elastic Container Registry (ECR) permite la creación de repositorios para almacenar, administrar e implementar imágenes de contenedores de Docker. ECR permite tener una arquitectura escalable y de alta cdisponibilidad para las imágenes, por lo que su uso es fundamental para mantener actualizadas las imágenes y disponibles en cada deploy de la aplicación.

### ElastiCache

ElastiCache permite ejecutar y escalar de manera sencilla el almacenamiento de datos en memoria en la nube. Ofrece Redis y Memcached con total control de administración. Es una buena opción para el almacenamiento en caché, análisis en tiempo real y servicios de colas, entre otros. Este último caso de uso es el que se necesita en KeyClouding, debido a que en la solución actual se usa un plug-in de Redis en Heroku que maneja trabajos asíncronos, como el envío de emails.

### Multicontainer environment

Para ejecutar más de un contenedor de Docker en Elastic Beanstalk, es decir, si es que en local usas Docker Compose, es necesario utilizar la plataforma Multicontainer Docker, en donde es necesario crear el archivo Dockerrun.aws.json para definir el conjunto de contenedores.


## Archivos importantes

* `Dockerrunaws.json` [file]: este archivo es como el docker-compose.yml de Elastic Beanstalk, aquí se hace la definición de los contenedores a levantar en producción. Para el caso de producción, solo se incluye sidekiq y web. Además, es necesario agregar nginx como servicio para que mapee el flujo de la aplicación al puerto 80. Existe una herramienta para transformar de docker-compose.yml a Dockerrunaws.json, el link de cómo hacerlo se encuentra en la sección de Links.
* `.ebextensions/0002_sidekiq.config:` [file]: script para levantar al worker sidekiq en Elastic Beanstalk, el link de dónde saqué este script que además me permitió realizar la configuración se encuentra en la sección Links.
* `proxy/conf.d/default.conf` [file]: archivo de configuración de nginx que indica el mapeo entre puertos.
* `.github/worflows/cdecr.yml:` [file]: archivo de configuración de continuous deployment con GitHub Action. Existe una serie de pasos antes para hacer del despliegue de una aplicación: configurar las credenciales de AWS, iniciar sesión en Amazon ECR, construir la imagen de Docker y subirla al repositorio de ECR, compilar la aplicación en un archivo .zip y hacer el despliegue de la nueva versión de la aplicación. Estos pasos ocurrirán cada vez que se haga un push en la rama indicada de GitHub. El detalle de cómo realizar esta configuración se encuentra en la sección Links.

## Tips

- Fijarse bien en la sintaxis del Dockerrunaws.json, puede llegar a tener errores y no lo indica explícitamente.
- Preocuparse de que la suma de la memoria reservada para cada contenedor en el Dockerrunaws.json sea consistente con la capacidad de la máquina de EC2.
- Siempre hacer commits para que al probar el entorno localmente reconozca los cambios.
- Una vez en la consola de EC2, debuggear dentro de la consola revisando los logs o hacer curl a la dirección siempre es una buena opción
- Ir ajustando las máquinas según el uso que se le da, utilizar compute optimizer para obtener las estadísticas y sugerencias de cambio.

## Links

* [Para setear sidekiq y redis en una aplicación de Rails en AWS Elastic Beanstalk](https://medium.com/hackernoon/how-to-setup-and-deploy-a-rails-5-app-on-aws-beanstalk-with-postgresql-redis-and-more-88a38355f1ea)
* [Cómo hacer un deploy con GitHub Action a Elastic Beanstalk](https://medium.com/javascript-in-plain-english/deploy-using-github-actions-on-aws-elastic-beanstalk-c23ecd35776d )
* [Cómo subir un entorno Multicontainer a Elastic Beanstalk (incluye cómo obtener el Dockerrunaws.json)](https://medium.com/analytics-vidhya/deploying-a-multi-container-web-application-aws-elastic-beanstalk-c5f95d266842)
* [Cómo subir las variables de entorno a Elastic Beanstalk a partir de un archivo local](https://stackoverflow.com/questions/39414973/upload-env-environment-variables-to-elastic-beanstalk)
