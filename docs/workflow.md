# Flujo end-to-end de una intervención

1. **Solicitud** — registrar contacto, ubicación, síntoma y canal de entrada.
2. **Planificación** — asignar técnico, fecha y franja horaria.
3. **Llegada** — confirmar presencia, alcance y autorización para inspeccionar.
4. **Identificación** — crear/seleccionar cliente, ubicación y ficha de cada persiana.
5. **Inspección** — ejecutar el protocolo adaptativo y adjuntar evidencias.
6. **Diagnóstico** — separar hechos observados de hipótesis.
7. **Presupuesto** — detallar materiales, mano de obra, impuestos y condiciones.
8. **Aprobación** — registrar aceptación, rechazo o solicitud de cambios.
9. **Ejecución** — registrar tareas y materiales realmente utilizados.
10. **Control de calidad** — repetir pruebas pertinentes y documentar resultados.
11. **Entrega** — explicar el resultado, entregar documentación y registrar conformidad.
12. **Seguimiento** — gestionar garantía, incidencias y valoración.

## Estados sugeridos

Nueva → Pendiente de visita → En inspección → Diagnóstico pendiente → Presupuesto enviado → Pendiente de aprobación → Aprobada → En ejecución → Control de calidad → Completada.

Estados alternativos: Cancelada, Reprogramada, En espera de material y Bloqueada por seguridad.

## Reglas de negocio

- No ejecutar partidas adicionales sin aprobación registrada.
- Mantener historial de presupuestos y cambios.
- Diferenciar presupuesto, importe aprobado e importe final.
- No borrar evidencias de expedientes cerrados; las correcciones deben quedar auditadas.
- Permitir pausar una intervención y reanudarla sin perder avances.
