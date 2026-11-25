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

## Trazas distribuidas locales

La API y el cliente incluyen el agente OpenTelemetry Java 2.34.0.
Docker Compose lo activa y configura el envío de trazas a Jaeger 2.23.0.

Las trazas permiten seguir una petición desde el cliente hacia la API
y sus operaciones en PostgreSQL. Esta configuración corresponde
a las aplicaciones locales de Docker.

### Iniciar y comprobar

Desde la carpeta infraestructura, ejecutar:

```powershell
docker compose --env-file .env config --quiet
docker compose --env-file .env up -d --build jaeger api cliente
```

1. Abrir http://localhost:8082/login.
2. Iniciar sesión con un usuario local y abrir un proyecto.
3. Esperar unos diez segundos.
4. Abrir http://localhost:16686/search.
5. Seleccionar gestor-cliente y pulsar Find Traces.
6. Abrir una traza y comprobar las operaciones de gestor-cliente,
   gestor-api y PostgreSQL.

En una instalación nueva, registrar primero un usuario desde
http://localhost:8082/register.

### Resultado comprobado

El archivo `trazas/resultado-trazas.json` conserva la exportación
original de una ejecución: 11 trazas, 55 spans y siete trazas
con operaciones del cliente, la API y PostgreSQL conectadas.
Ningún span de esa exportación está marcado como error.

Jaeger utiliza almacenamiento en memoria. Las trazas se pierden
al reiniciar su contenedor; los resultados pueden exportarse
mediante Download Results.

## Trazas distribuidas en Render

La API y el cliente publicados en Render utilizan OpenTelemetry
Java Agent 2.34.0 y envían sus trazas a Grafana Cloud mediante OTLP
sobre HTTPS.

Los servicios se identifican como:

- gestor-cliente-render
- gestor-api-render

### Configuración

El archivo render.yaml define la activación del agente,
los nombres de servicio, el receptor y la exportación de trazas.

En Grafana Cloud se necesita una política con permiso traces:write
y un token asociado. El asistente de OpenTelemetry genera el valor
de OTEL_EXPORTER_OTLP_HEADERS usando ese token.

Ese valor se proporciona de forma privada en Environment Variables
de ambos servicios de Render. En el Blueprint se declara mediante
sync: false.

### Comprobar el recorrido

1. Iniciar sesión en el cliente publicado y abrir un proyecto.
2. En Grafana Cloud, abrir Explore y seleccionar la fuente Tempo.
3. Ejecutar esta consulta en modo TraceQL:

```traceql
{ resource.service.name = "gestor-cliente-render" }
```

4. Abrir una traza y comprobar las operaciones conectadas del cliente,
   la API y PostgreSQL.

### Resultado comprobado

El archivo trazas/resultado-trazas-render.json conserva una traza
original de POST /actualizarProyecto con siete spans: dos del cliente
y cinco de la API, incluida una consulta a PostgreSQL.

La petición duró 701,84 ms, sus operaciones HTTP respondieron 200
y ningún span quedó marcado como error.

Las trazas pueden conservarse mediante Export as JSON en Grafana Cloud.