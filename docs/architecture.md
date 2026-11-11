# Arquitectura propuesta

## MVP

- Frontend: React + TypeScript + Vite.
- Estilos: Tailwind CSS y componentes accesibles.
- Backend: Supabase (Postgres, Auth y Storage).
- Validación de formularios: esquema tipado y validación tanto en cliente como en servidor.
- Informes: generación PDF desde datos estructurados.
- Repositorio: GitHub.

## Módulos

- Dashboard y agenda.
- Clientes y ubicaciones.
- Activos: persianas individuales.
- Órdenes de trabajo.
- Motor de inspección configurable.
- Evidencias y archivos.
- Diagnósticos y presupuestos.
- Ejecución y control de calidad.
- Informes y auditoría.

## Requisitos no funcionales

- Diseño mobile-first y accesible.
- Guardado incremental y recuperación de borradores.
- Manejo de conectividad intermitente; definir explícitamente qué datos quedan en cola local.
- Validación de permisos en servidor, no solo ocultando botones.
- Políticas RLS para separar datos por empresa y rol.
- Almacenamiento privado de fotografías con URLs temporales.
- Registro de eventos relevantes y marcas temporales.
- Copias de seguridad y política de retención según el plan y necesidades.

## Seguridad y privacidad

No almacenar secretos en el frontend ni en GitHub. Usar variables de entorno y secretos del proveedor de despliegue. Minimizar datos personales, restringir accesos, definir conservación y borrado, y preparar información de privacidad conforme a RGPD antes de producción.

## Decisiones pendientes

- Tipos de persiana y catálogo de componentes.
- Roles definitivos.
- Si el cliente tendrá portal.
- Requisitos de firma y validez documental.
- Necesidad real de funcionamiento offline.
- Países, impuestos y formatos de presupuesto.
