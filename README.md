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

Primero validaremos con los socios los tipos de persiana, los componentes y el orden real de revisión. Después implementaremos el flujo de inspección y una primera ficha de intervención con datos de prueba.

## Desarrollo

La propuesta inicial es React + TypeScript para la interfaz y Supabase para autenticación, base de datos y almacenamiento, siempre dentro de los límites gratuitos disponibles. No se deben subir claves, contraseñas ni datos personales reales al repositorio.

## Aviso sobre el estado técnico

Los criterios de aceptación, límites de seguridad y procedimientos de reparación deben ser revisados por un técnico competente antes de usarse en operaciones reales.
