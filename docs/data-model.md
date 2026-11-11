# Modelo de datos inicial

Modelo conceptual; se ajustará antes de crear migraciones.

- **organizations**: empresa propietaria de los datos.
- **profiles**: usuario, identidad y preferencias.
- **organization_members**: relación usuario/empresa y rol.
- **customers**: datos mínimos de contacto del cliente.
- **sites**: direcciones y ubicaciones de servicio.
- **shutters**: persiana individual, ubicación, tipo, material, dimensiones y accionamiento.
- **work_orders**: intervención, estado, asignación, fechas y motivo.
- **inspection_templates**: versión del protocolo según tipo de persiana.
- **inspection_sections**: módulos y orden de inspección.
- **inspection_items**: instrucciones, criterios y obligatoriedad.
- **inspection_results**: resultado, observaciones, técnico y fecha.
- **evidence_files**: archivo privado asociado a un resultado o intervención.
- **diagnoses**: hallazgos, hipótesis y recomendaciones.
- **quotes** y **quote_lines**: presupuesto, partidas, impuestos y versiones.
- **approvals**: aceptación/rechazo, persona autorizante, alcance y fecha.
- **work_logs**: tareas, tiempos y materiales utilizados.
- **quality_checks**: pruebas finales y resultados.
- **signatures**: registro de conformidad y referencia al documento firmado.
- **audit_events**: historial de cambios relevantes.

## Reglas

- Las tablas operativas deben incluir organization_id.
- Aplicar Row Level Security en todas las tablas expuestas.
- No confiar en organization_id enviado por el navegador: validarlo con la identidad y membresía autenticadas.
- Los archivos deben ser privados y tener permisos equivalentes a su expediente.
- Guardar versiones de plantillas para saber qué protocolo se utilizó en cada inspección.
- No sobrescribir resultados cerrados: registrar rectificaciones auditables.
