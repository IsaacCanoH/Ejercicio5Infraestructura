# Infraestructura del circuito DevOps

Este repositorio contiene la configuración Docker Compose del administrador de proyectos.

Actualmente se ejecutan tres servicios: cliente Spring Boot, API Spring Boot y base de datos MariaDB.

## Componentes

| Componente | Servicio Compose | Acceso desde el equipo |
|---|---|---|
| Cliente Spring Boot | cliente | http://localhost:8082 |
| API Spring Boot | api | http://localhost:8081 |
| MariaDB | db | 127.0.0.1:3307 |

TablePlus se conecta a MariaDB mediante el puerto 3307.

## Comunicación entre servicios

El navegador accede al cliente por el puerto 8082.

El cliente consulta la API mediante `http://api:8081`, utilizando la variable `API_BASE_URL`.

La API se conecta a MariaDB mediante `jdbc:mariadb://db:3306/dbgestor`.

Los nombres `api` y `db` corresponden a los servicios dentro de la red de Compose.

## Organización

Los tres repositorios deben estar al mismo nivel:

- Ejercicio5Cliente
- Ejercicio5MyAPIGestor
- infraestructura

Compose utiliza los Dockerfile de los repositorios del cliente y de la API.

## Configuración

Las credenciales se definen en el archivo local `.env`:

- DB_USERNAME
- DB_PASSWORD
- DB_ROOT_PASSWORD

El archivo `.env.example` documenta estas variables. Las credenciales reales están excluidas de Git.

MariaDB utiliza una imagen fijada mediante su digest y almacena sus datos en el volumen `mariadb_data`.

Los puertos publicados están limitados a `127.0.0.1`.

## Ejecución

Desde la carpeta `infraestructura`, construir e iniciar los servicios:

```powershell
docker compose --env-file .env up -d --build
```

Consultar su estado:

```powershell
docker compose --env-file .env ps
```

Consultar los logs del cliente y de la API:

```powershell
docker compose --env-file .env logs --tail 50 cliente api
```

Detener los servicios conservando los datos:

```powershell
docker compose --env-file .env stop
```

## Validaciones realizadas

- MariaDB en estado healthy.
- Restauración inicial de las seis tablas mediante un respaldo SQL.
- Coincidencia de cantidades de registros entre la base original y la restaurada.
- Consulta de proyectos mediante la API con respuesta HTTP 200.
- Cliente iniciado en Docker en el puerto 8082.
- Carga del proyecto, su tarea y sus comentarios desde el navegador.
- Comunicación comprobada entre cliente, API y MariaDB.
