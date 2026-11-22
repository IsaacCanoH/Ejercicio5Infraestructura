# Infraestructura del circuito DevOps

Configuración Docker Compose del administrador de proyectos:
cliente Spring Boot, API Spring Boot y PostgreSQL 18.

## Componentes

| Componente | Servicio Compose | Acceso desde el equipo |
|---|---|---|
| Cliente | cliente | http://localhost:8082 |
| API | api | http://localhost:8081 |
| PostgreSQL | postgres | 127.0.0.1:5433 |

La base de datos se llama `dbgestor`.

## Organización

Los repositorios deben estar al mismo nivel:

- Ejercicio5Cliente
- Ejercicio5MyAPIGestor
- infraestructura

Compose construye las imágenes usando los Dockerfile del cliente y la API.

## Configuración

Crear un archivo `.env` tomando `.env.example` como referencia y definir:

- DB_USERNAME
- DB_PASSWORD
- MONITORING_USERNAME
- MONITORING_PASSWORD
- GRAFANA_ADMIN_PASSWORD

Las credenciales reales quedan excluidas de Git.

PostgreSQL conserva sus datos en el volumen `postgres_data`.
Los puertos publicados están limitados a `127.0.0.1`.

## Primera instalación

Desde infraestructura, iniciar PostgreSQL:

```powershell
docker compose --env-file .env up -d postgres
```

Cuando esté healthy, conectar TablePlus usando PostgreSQL,
host `127.0.0.1`, puerto `5433`, base `dbgestor` y las credenciales
del `.env`.

Crear la estructura ejecutando el esquema PostgreSQL de la API:
`Ejercicio5MyAPIGestor/src/test/resources/schema-ci.sql`.

Si se necesitan datos existentes, importar después un respaldo
convertido a PostgreSQL. Un respaldo de MariaDB requiere conversión.

Construir e iniciar todos los servicios:

```powershell
docker compose --env-file .env up -d --build
```

La API valida la estructura existente; no crea las tablas automáticamente.

## Comunicación

El navegador accede al cliente por el puerto 8082.

El cliente consulta la API usando `API_BASE_URL=http://api:8081`.

La API utiliza `jdbc:postgresql://postgres:5432/dbgestor`.

## Operación

Consultar estado:

```powershell
docker compose --env-file .env ps
```

Consultar logs:

```powershell
docker compose --env-file .env logs --tail 50 postgres api cliente
```

Detener los servicios conservando los datos:

```powershell
docker compose --env-file .env stop
```

## Validación

- Datos importados desde MariaDB conservando sus identificadores.
- 156 pruebas de la API aprobadas con PostgreSQL.
- CI de la API aprobado con PostgreSQL.
- Consulta de proyectos, tareas y comentarios comprobada.
- Comunicación cliente → API → PostgreSQL comprobada en Docker.

El CI de infraestructura valida la configuración de Compose.

## Monitoreo

Prometheus y Grafana se ejecutan localmente con Docker y consultan
las métricas de la API publicada en Render.

En `.env`, las variables MONITORING_USERNAME y MONITORING_PASSWORD
deben coincidir con las configuradas en la API de Render.
GRAFANA_ADMIN_PASSWORD define la contraseña del usuario admin de Grafana.

Iniciar el monitoreo:

```powershell
docker compose --env-file .env up -d prometheus grafana
```

Accesos:

- [Destinos de Prometheus](http://localhost:9090/targets)
- [Alertas de Prometheus](http://localhost:9090/alerts)
- [Grafana](http://localhost:3000)

Grafana carga automáticamente la conexión y el tablero desde los
archivos de la carpeta `monitoreo`.

El tablero muestra estado, CPU, memoria heap, solicitudes,
tiempo promedio de respuesta y errores HTTP 5xx.

La alerta MetricasAPINoDisponibles se activa cuando la consulta
de métricas falla durante dos minutos. Su estado se consulta
en la página de alertas de Prometheus.

La recolección de métricas requiere que el equipo y Docker
permanezcan encendidos.