# Plan — Kachava Lux Command Center (v2, 2026-11-02)

Fuente de verdad única. Reemplaza la versión anterior. Fuentes:
- `DESIGN.md`: UI/UX y colores del admin.
- `doc/improvements/spec.md`: funcionalidad.
- `doc/kachava-command-center/ux-patterns.md`: patrones de listas y pantallas.
- `doc/improvements/*.jpeg`: solo estructura y orden del menú y del Dashboard.

## Reglas obligatorias (aplican a todo)
1. **Aplicación de producción.** No hay borradores, datos precargados, seeds, mockups, valores hardcodeados ni modo en memoria en runtime. La base arranca vacía y el cliente crea y configura todo desde el admin. En local se usa el emulador de Firestore, con datos persistentes entre reinicios. Nunca se toca la base real `kavacha-db` sin aprobación explícita.
2. **Colores, tipografía y radios** salen solo de `DESIGN.md`. Las imágenes del cliente solo definen orden y opciones.
3. **Todas las listas** tienen búsqueda, filtros, orden y paginación (25 por página; 10/25/50), según `ux-patterns.md`. No hay scroll infinito de tarjetas. Al tocar una fila se abre el detalle lateral; en móvil, a pantalla completa.
4. **UI limpia:** poco texto y explicaciones en tooltips ⓘ. Si falta configuración, una línea que lleva a donde se configura.
5. **Sin login visible** en el admin. La identidad técnica del admin viene de la configuración del entorno, no de la base de datos.
6. **EN/ES** en todo lo visible. Nunca se traduce automáticamente.
7. **Sin despliegues sin aprobación.** Pruebas primero en local.
8. **Cierre de cada fase:** pruebas unitarias, de widgets y E2E en verde, más capturas para el dueño. No se avanza sin su visto bueno.

## Menú del admin
- Dashboard
- GUEST OPERATIONS: Reservations, Guests, Villas. Folio es una pestaña dentro del detalle.
- HOSPITALITY: Services, Experiences, Dining, Transportation, Wellness
- OPERATIONS: Tasks, Notifications
- Ajustes: ícono de engranaje en la barra superior
- TEAM queda fuera por ahora.

## Modelo de servicio (catálogo único; las secciones son vistas filtradas)
Un **servicio** tiene **ítems u opciones** (carta, menú, productos, opciones de preferencia, vehículos). Cada ítem tiene foto y precio propios.

**Todo servicio tiene:**
- **General:** nombre EN/ES, descripción corta EN/ES, descripción completa EN/ES, sección, etiquetas, orden y destacado.
- **Imágenes:** portada obligatoria y galería de hasta 8, con alt EN/ES. Se suben desde el admin a Cloud Storage con validación de formato y tamaño, y casilla de "derechos de uso".
- **Uso del huésped:** Pedido, Reserva, Preferencia o Viaje.
- **Precio:**
  - Modalidad: incluido, fijo, por persona, por unidad, por hora o a consultar.
  - Moneda USD, si se carga o no al Folio, y nota de precio.
- **Disponibilidad:** días de la semana, franjas horarias, fechas bloqueadas, anticipación mínima, plazo de cancelación, personas mín/máx, duración y momento de la estancia en que se ofrece (antes, durante o ambos).
- **Info al huésped:** qué incluye y qué no, qué llevar, lugar o punto de encuentro, restricciones y política de cancelación.
- **Formulario del huésped configurable:** fecha, hora, personas, notas, dieta/alergias y preguntas de salud.
- **Operación (solo staff):** proveedor externo o responsable interno, si requiere confirmación, instrucciones internas.
- **Estado:** Activo o Desactivado. No se puede activar sin portada y textos EN/ES. Auditoría de quién creó o modificó y cuándo.

**Específico por tipo:**

| Tipo | Campos propios |
|---|---|
| **Lux bar** (Dining) | Carta de ítems (foto, precio, categoría), horario, lugar, confirmación de mayoría de edad para alcohol, pedido con cantidades que se carga al Folio |
| **Desayuno** (Dining) | Platos con foto, etiquetas dietéticas y alérgenos; franjas horarias, lugar y anticipación; el staff ve la dieta y las alergias del huésped |
| **Menús especiales** (Dining) | Cursos, maridaje opcional, mínimo de personas, horarios |
| **Abastecimiento de villa** | Productos (foto, origen, unidad, precio, almacenamiento, etiquetas, disponible), máximo por producto, fecha límite X horas antes del check-in |
| **Experiences** | Duración, itinerario paso a paso, punto de encuentro, participantes, edad mínima, idiomas, guía o proveedor, precio por persona o grupo |
| **Wellness** | Duración, terapeuta o proveedor, lugar (villa o spa), franjas horarias, preguntas de salud y contraindicaciones |
| **Preferencias** (almohadas, aroma) | Opciones con foto, selección única o múltiple, cambio hasta X horas antes; la elección genera una tarea de preparación |
| **Transporte** | Aeropuertos desde Ajustes, vehículos (foto, pasajeros, maletas), precio por trayecto o vehículo, proveedor, anticipación, datos de vuelo obligatorios |

**Pedidos y reservas** guardan una copia (snapshot) del nombre, el precio y los ítems al momento de pedir.

**Servicios que Kachava creará desde el admin:** abastecimiento de villa, Lux bar, desayuno, aromaterapia, menú de almohadas, traslado aeropuerto Cancún/Tulum, transporte local privado, parrillada y experiencia sensorial mexicana. No se precargan.

## Transporte
- **Proveedores externos configurables:** nombre, teléfono, email, activo.
- **Viajes:**
  - Tipos: llegada, salida o local. Los crea el huésped o el staff.
  - Estados: Solicitado → Enviado al proveedor → Confirmado (con chofer, teléfono y vehículo) → En camino → Completado, más Cancelado.
  - La hora de recogida de salida se calcula con el margen del aeropuerto definido en Ajustes.
  - Alerta urgente si un viaje cercano sigue sin confirmar; la anticipación se configura en Ajustes.

## Ajustes (configurables, sin valores fijos en el código)
Horas de check-in y check-out, zona horaria, aeropuertos con sus márgenes y anticipación de las alertas. Si algo no está configurado, una línea que lleva a Ajustes.

## Estado
Ya hecho, con commit en `feature/kachava-command-center`:
- **A.** Link del huésped confiable, sin datos falsos en el portal.
- **B.** Web app instalable que recuerda el link (falta probar en teléfono).
- **D.** Tema según DESIGN.md y menú por secciones, sin login.
- Patrones de UX en `ux-patterns.md`.

## Fases
| # | Fase | Agentes |
|---|---|---|
| 1 | **Base de producción (backend):** emulador local persistente; eliminar todo seed, demo y modo memoria; identidad del admin por entorno; API con paginación, búsqueda, filtros y orden; Ajustes; Villas; proveedores de transporte; modelo completo de servicio e ítems; subida de imágenes a Storage | `architect-engineer` → `code-implementer` → `critic` |
| 2 | **Base de listas del admin:** `ListQuery`, `AdminListScreen`, tabla paginada, detalle lateral y vista móvil; limpieza de la barra superior; vocabulario de estados; quitar todo seed y fixture del runtime | `ui-ux-designer` → `flutter-implementer` → `flutter-reviewer` |
| 3 | **Ajustes y Villas** en el admin, de punta a punta con el backend | `flutter-implementer` |
| 4 | **Services:** catálogo con formulario por pestañas, ítems, imágenes y validación para activar; vistas Experiences, Dining y Wellness con sus colas de solicitudes | `ui-ux-designer` → `code-implementer` + `flutter-implementer` |
| 5 | **Transportation:** proveedores, viajes y alertas | `code-implementer` + `flutter-implementer` |
| 6 | **Dashboard:** 6 KPIs y "Actividad de hoy" en 3 columnas, con datos reales | `flutter-implementer` |
| 7 | **Reservations y Guests:** tablas, detalle con link, Wi-Fi, preferencias y pestaña Folio | `code-implementer` + `flutter-implementer` |
| 8 | **Tasks y Notifications** | `code-implementer` + `flutter-implementer` |
| 9 | **Portal del huésped simple:** 4 pestañas; catálogo activo con imágenes; pedir, reservar, elegir y solicitar viaje | `ui-ux-designer` → `flutter-implementer` |
| 10 | **Verificación final:** E2E completo, teléfono real, estrés y cumplimiento; build de release | `qa-tester`, `e2e-blackbox-tester`, `challenger`, `flutter-reviewer`, `compliance-verifier`, `flutter-release-engineer` |
| 11 | **Proteger el backend:** App Check + Auth anónimo en el admin. Diferida, pero recomendada antes del lanzamiento | `code-implementer` + `flutter-implementer` |

## Verificación por fase
- `cd backend && npm run typecheck && npm test`
- `cd admin && dart analyze && flutter test`
- `cd web && dart analyze && flutter test`
- `./run-local.sh` con el emulador, y luego `cd e2e && npx playwright test`, una vez por fase.
- Capturas a 1440 y 375 px.
