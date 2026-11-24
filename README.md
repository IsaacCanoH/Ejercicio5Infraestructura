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

Con los tres repositorios ubicados al mismo nivel y el archivo
`.env` configurado, ejecutar desde infraestructura:

```powershell
docker compose --env-file .env config --quiet
docker compose --env-file .env up -d --build
```

Cuando PostgreSQL inicia con un almacenamiento vacío, ejecuta
automáticamente el archivo de la API:
`Ejercicio5MyAPIGestor/src/test/resources/schema-ci.sql`.

Este archivo crea las cinco tablas, la secuencia de identificadores
y los dos índices. No es necesario crear las tablas con TablePlus.

La API valida que la estructura sea compatible al arrancar.

La inicialización automática se ejecuta únicamente cuando el
almacenamiento está vacío. En una instalación existente se
conservan los datos y el esquema no se vuelve a ejecutar.

Comprobar el estado de los servicios:

```powershell
docker compose --env-file .env ps
```

Accesos de la instalación normal:

- Cliente: http://localhost:8082/login
- Estado de la API: http://localhost:8081/actuator/health
- Estado del cliente: http://localhost:8082/actuator/health

En una instalación nueva, registrar un usuario desde
http://localhost:8082/register antes de iniciar sesión.

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

Prometheus y Grafana se ejecutan localmente con Docker.
Prometheus consulta las métricas de la API y del cliente publicados
en Render cada 30 segundos.

En `.env`, configurar:

- MONITORING_USERNAME: monitor.
- MONITORING_PASSWORD: misma contraseña de monitoreo configurada
  en ambos servicios de Render.
- GRAFANA_ADMIN_PASSWORD: contraseña del usuario admin de Grafana.

Iniciar el monitoreo:

```powershell
docker compose --env-file .env up -d prometheus grafana
```

Accesos:

- [Destinos de Prometheus](http://localhost:9090/targets)
- [Alertas de Prometheus](http://localhost:9090/alerts)
- [Grafana](http://localhost:3000)

Grafana carga automáticamente la conexión y el tablero desde
los archivos de la carpeta `monitoreo`.

El tablero “Monitoreo Gestor - API y Cliente” permite elegir
el servicio mediante el selector Servicio. Los seis paneles muestran
estado, CPU, memoria heap, solicitudes, tiempo promedio de respuesta
y errores HTTP 5xx del servicio seleccionado.

Las alertas MetricasAPINoDisponibles y MetricasClienteNoDisponibles
se activan si la consulta de métricas del servicio correspondiente
falla durante dos minutos. Sus estados se consultan en Prometheus.

La recolección requiere que el equipo y Docker permanezcan encendidos.

## Pruebas de rendimiento

Se utiliza k6 2.4.0 mediante Docker para medir dos operaciones:

- API: POST /buscarProyectos.
- Cliente: GET /login.

Cada usuario virtual realiza ambas peticiones y espera un segundo
antes de repetirlas. Se mide la respuesta HTTP de esos endpoints.

Antes de ejecutar las pruebas, comprobar que ambos servicios
aparezcan en estado UP en Prometheus.

Ejecutar desde la carpeta infraestructura.

### Prueba base: un usuario durante 30 segundos

```powershell
docker run --rm -v "${PWD}/rendimiento:/pruebas" grafana/k6:2.4.0 run -e PERFIL=base --summary-mode=full --summary-export=/pruebas/resultado-base.json /pruebas/prueba-carga.js 2>&1 | Tee-Object -FilePath .\rendimiento\resultado-base.txt
```

### Prueba de carga: hasta cinco usuarios durante 90 segundos

```powershell
docker run --rm -v "${PWD}/rendimiento:/pruebas" grafana/k6:2.4.0 run -e PERFIL=carga --summary-mode=full --summary-export=/pruebas/resultado-carga.json /pruebas/prueba-carga.js 2>&1 | Tee-Object -FilePath .\rendimiento\resultado-carga.txt
```

Los objetivos del ensayo son un p95 inferior a 2000 ms y una tasa
de errores inferior al 1 % para cada servicio.

Los reportes originales se guardan en la carpeta `rendimiento`,
en formatos JSON y TXT.

El workflow incluye la validación de ambos escenarios mediante
k6 inspect. Las pruebas de carga se ejecutan manualmente sobre
los servicios del proyecto.

## Infraestructura en Render

El archivo render.yaml define el cliente, la API y PostgreSQL
mediante Render Blueprints.

Las aplicaciones usan Docker, la rama main y el plan gratuito.
La API obtiene el usuario y la contraseña de PostgreSQL
mediante referencias a la base de datos.

Las siguientes variables se proporcionan desde Render:
- API_BASE_URL: dirección pública HTTPS de la API.
- DB_URL: dirección JDBC de PostgreSQL.
- MONITORING_PASSWORD: contraseña de monitoreo de cada aplicación.

Estas variables están marcadas con sync: false.
Al incorporar los servicios existentes, se conservan sus valores.

Antes de aplicar el Blueprint, se debe comprobar que Render
vincule los tres recursos existentes y mantenga sus planes.