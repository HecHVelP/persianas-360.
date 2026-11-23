# Persianas 360

Sistema profesional para gestionar inspecciones, diagnósticos, reparaciones, instalaciones y seguimiento de persianas.

> Estado: fase de definición y MVP. Este repositorio contiene documentación inicial; todavía no es una aplicación desplegada ni debe utilizarse como sustituto de procedimientos técnicos, eléctricos o de seguridad aprobados.

## Objetivo

Guiar al técnico durante una intervención mediante un protocolo secuencial y adaptable. Cada comprobación debe registrar el criterio evaluado, resultado, observaciones y evidencias asociadas.

## Alcance del MVP

1. Clientes y ubicaciones.
2. Expedientes de intervención.
3. Identificación individual de cada persiana.
4. Inspección técnica por componentes y tipo de accionamiento.
5. Evidencias fotográficas vinculadas a cada comprobación.
6. Diagnóstico y propuesta de trabajo.
7. Presupuesto y aprobación del cliente.
8. Registro de ejecución, control de calidad y cierre.
9. Informe técnico exportable.

## Principios de diseño

- Mobile-first: utilizable desde el teléfono durante una visita.
- Trazabilidad: usuario, fecha y hora para cada cambio relevante.
- Evidencia: no basta con marcar un componente como correcto.
- Seguridad: las comprobaciones eléctricas y trabajos de riesgo deben seguir procedimientos y personal cualificado.
- Privacidad: acceso mínimo necesario, consentimiento y retención controlada de datos.
- Transparencia: no realizar trabajos adicionales sin autorización documentada.

## Estructura

- `docs/inspection-protocol.md`: protocolo inicial de inspección.
- `docs/workflow.md`: recorrido end-to-end de una intervención.
- `docs/architecture.md`: arquitectura técnica propuesta.
- `docs/data-model.md`: entidades y relaciones iniciales.
- `docs/product-decisions.md`: decisiones pendientes y supuestos.

## Estado y próximos pasos

La rama `feature/crm-automation-v1` incorpora el diseño e implementación inicial del CRM y automatización: migraciones SQL, workflows, contrato del agente WhatsApp, API y checklist de configuración. La app conectada y los servicios externos aún no están desplegados.

## CRM y automatización v1

- `docs/crm-automation-v1.md`: arquitectura, ciclo de vida del lead y reglas.
- `docs/workflows-v1.md`: workflows WF-01 a WF-10.
- `docs/whatsapp-agent-v1.json`: contrato y prompt del agente.
- `docs/api-contract-v1.md`: endpoints y contratos.
- `docs/setup-v1.md`: setup y pruebas de aceptación.
- `supabase/migrations/202611230001_crm_automation_v1.sql`: esquema CRM y RLS.
- `supabase/migrations/202611230002_dashboard_views_v1.sql`: vistas KPI.

**Importante:** las migraciones están preparadas, pero aún no se han aplicado. El proyecto Lovable existente tiene la base de datos desactivada y el workspace está sin créditos; por eso no se ha modificado ni desplegado la app en producción.

## Desarrollo

React + TypeScript para la interfaz y Supabase para Auth, PostgreSQL y Storage, dentro de límites gratuitos verificados antes de provisionar. No subir claves, contraseñas ni datos personales reales al repositorio.

## Aviso sobre el estado técnico

Los criterios de aceptación, límites de seguridad y procedimientos de reparación deben ser revisados por un técnico competente antes de usarse en operaciones reales.
