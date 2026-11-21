# Infraestructura del circuito DevOps

Este repositorio contiene la configuración de infraestructura del administrador de proyectos.

La etapa actual permite ejecutar MariaDB en Docker y conectar la API y la interfaz desde el equipo local.

## Componentes

| Componente | Ejecución | Dirección |
|---|---|---|
| Cliente Spring Boot | Equipo local | http://localhost:8082 |
| API Spring Boot | Equipo local | http://localhost:8081 |
| MariaDB | Docker | 127.0.0.1:3307 |
| TablePlus | Equipo local | Conexión a MariaDB por el puerto 3307 |

El puerto 3307 del equipo se conecta con el puerto 3306 del contenedor.

## Decisiones de configuración

- MariaDB utiliza una imagen fijada mediante su digest para identificar exactamente la versión desplegada.
- El puerto local 3307 permite mantener separada esta instancia de la base original del puerto 3306.
- Los datos se almacenan en un volumen administrado por Docker.
- La conexión publicada está limitada a la interfaz local 127.0.0.1.
- Las credenciales reales se definen en .env y están excluidas de Git.
- .env.example documenta las variables necesarias sin incluir credenciales reales.
- El healthcheck comprueba la conexión y la inicialización de InnoDB.

## Validaciones realizadas

- Contenedor MariaDB en estado healthy.
- Restauración de las seis tablas desde un respaldo SQL.
- Coincidencia de cantidades de registros entre las bases original y nueva.
- Consulta de proyectos mediante la API con respuesta HTTP 200.
- Acceso desde la interfaz al proyecto, su tarea y los comentarios asociados.
