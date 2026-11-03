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
4. **UI limpia, simple e intuitiva, con el mínimo texto:**
   - **Títulos y etiquetas:** de 1 a 3 palabras. Sin subtítulos, párrafos ni banners de instrucciones; lo explicativo va en tooltips ⓘ.
   - **Acciones:** una acción principal visible por pantalla; las secundarias van en el menú ⋮ de la fila. Los botones usan verbos ("Guardar", "Desactivar").
   - **Estados vacíos y errores:** una línea más una acción.
   - **Formularios:**
     - solo los campos necesarios, con valores por defecto sensatos;
     - opciones avanzadas plegadas;
     - validación en línea de 5 palabras como máximo;
     - confirmación de una línea en las acciones destructivas.
   - **Mensajes de confirmación (toasts):** una línea, que se cierra sola.
   - **Estados:** un chip corto con color de DESIGN.md, nunca solo color.
   - **Tablas:** máximo 6 columnas visibles; el resto va en el detalle.
   - **Configuración faltante:** una línea que lleva a donde se configura.
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

## Detalle acordado por pantalla (todo lo decidido con el dueño)

**Barra superior del admin**
- Contiene: título de la pantalla, EN/ES, campana de alertas y engranaje de Ajustes.
- Sin búsqueda ni filtros globales: cada pantalla tiene los suyos.
- Sin botones de prueba (por ejemplo, "Test 10s").

**Dashboard**
- Encabezado: "Overview" y una píldora "Today" con la fecha del resort (zona horaria de Ajustes).
- 6 KPIs, cada uno con su fórmula en un ⓘ:
  - villas ocupadas = villas con estancia activa;
  - disponibles = activas − ocupadas − fuera de servicio;
  - % de ocupación = ocupadas / total activas;
  - llegadas = check-in hoy;
  - salidas = check-out hoy;
  - solicitudes abiertas = pedidos, reservas, viajes y tareas sin completar.
- Tabla "Actividad de hoy" de 3 columnas (Guest, Villa, Status), máximo 8 filas y "Ver todo" que lleva a Reservations.
- Estados de la tabla:
  - **Departure** si el check-out es hoy (prevalece si hoy también es el check-in);
  - **Arrival** si el check-in es hoy (todo el día);
  - **In-house** si ya hizo check-in;
  - **In-house con aviso rojo** si sigue después de su fecha de salida;
  - las estancias futuras, canceladas o cerradas no aparecen.
- Chips de color con tokens semánticos de DESIGN.md: In-house verde, Arrival azul, Departure gris, vencido rojo.
- Clic en una fila → detalle de la estancia.
- Sin lista de alertas en el Dashboard: viven en Notifications y en la campana.

**Reservations**
- Tabla: Guest, Villa, Llegada, Salida, Estado, Resort Host.
- Filtros: estado, villa y rango de fechas. Búsqueda por huésped.
- Detalle lateral con pestañas:
  - Resumen: link del huésped con botón copiar, Wi-Fi, Resort Host y notas internas.
  - Preferencias y alergias.
  - Traslados.
  - Folio ("Resumen de estancia": servicios adquiridos, pedidos, reservas, calificación y cargos).
- Origen de la reserva y pagos del PMS: "Sin integración PMS". Nunca se simulan.

**Guests**
- Perfil por estancia: idioma, preferencias, alergias, ocasión especial, historial de solicitudes, notas internas y chat con el Resort Host.

**Villas**
- Tabla: nombre, categoría, capacidad, estado operativo, limpieza, mantenimiento y huésped actual.
- Crear, editar y desactivar desde el detalle lateral.

**Services / Experiences / Dining / Wellness**
- Tabla del catálogo: portada, nombre, sección, tipo de uso, precio, anticipación y estado.
- Formulario por pestañas: General · Imágenes · Precio y disponibilidad · Ítems/Opciones · Formulario del huésped · Operación.
- Cada vista por sección lleva debajo la cola de solicitudes de esa sección, en tabla.

**Transportation**
- Tabla de viajes de hoy y mañana: hora, huésped, villa, tipo, vuelo, proveedor, chofer y estado.
- Pestañas: Viajes · Servicios de transporte · Proveedores.

**Tasks**
- Campos: villa, huésped, categoría, responsable, prioridad, fecha límite, estado (Pending → Assigned → In Progress → Completed) y confirmación de cumplimiento.
- Las preferencias, pedidos y viajes generan tareas.
- La condición de "vencida" se calcula al leer la lista.

**Notifications**
- Niveles: Info, Acción pendiente y Urgente.
- Sonido solo en las urgentes.
- Botón "Abrir registro" que lleva al origen.
- Eventos: nueva reserva, llegada, solicitud, cambio de vuelo o itinerario, tarea vencida, incidencia, mensaje del huésped y viaje sin confirmar.

**Terminología**
- "Resort Host" (nunca "Concierge") en el admin y en el portal. Solo cambia el texto visible; los identificadores del código se mantienen.

**Portal del huésped** (conserva su estilo de marca; tipografía mínima de 14 px; sin jerga)
- Acceso:
  - Link `?guestId` que se guarda en el teléfono; ya hecho en la fase B.
  - Si el link expiró: "Tu enlace expiró, pide uno nuevo a tu Resort Host".
  - Instalación: en Android, botón "Instalar app"; en iPhone, guía "Compartir → Agregar a pantalla de inicio".
- **Recorrido guiado y numerado** (decisión del dueño 2026-11-02; sustituye la idea anterior de quitar los números):
  - **Pasos numerados** según el momento de la estancia: Paso 1 · Antes de tu llegada, Paso 2 · Durante tu estancia, Paso 3 · Tu salida. Dentro de cada paso, tareas numeradas (1.1, 1.2…) que se llenan solas con los servicios activos del catálogo, según su campo "cuándo se ofrece".
  - **Avance visible:** "2 de 4 listos", cada tarea con ✓ hecho o pendiente.
  - **El paso actual se abre y se destaca por fecha;** los demás quedan plegados.
  - **Un botón principal "Siguiente":** lleva a la próxima tarea pendiente. Las tareas opcionales se pueden saltar con "Ahora no".
  - **Formularios largos en asistente:** el vuelo, por ejemplo, va de pocos campos por pantalla, con barra de progreso.
  - **La misma numeración en todo el recorrido:** en el Inicio y en el título de cada pantalla. Se conservan los títulos numerados.
  - **Pasos interactivos:** nada de encabezados muertos (requisito de `doc/SPECIFICATION.md` §137).
- 4 pestañas:
  - **Inicio:** el recorrido guiado de arriba, más villa, fechas y Wi-Fi.
  - **Servicios:** secciones armadas solo con el catálogo activo, con tarjetas de foto, nombre, línea corta, precio o "Incluido" y anticipación. Cada servicio se abre en una hoja con el formulario según su tipo: pedir, reservar, elegir o viaje.
  - **Mis solicitudes:** una sola lista con estados en lenguaje simple: Recibida → Confirmada → En preparación / En camino → Lista. Se puede cancelar o cambiar mientras esté en "Recibida".
  - **Resort Host:** chat y adjuntar una foto real.
- Se elimina:
  - el drawer "todas las pantallas" (duplica la navegación);
  - las pantallas yate, Included y Philosophy;
  - el teléfono hardcodeado;
  - el badge siempre encendido.
- Idioma: se detecta del navegador y se recuerda.
- Estados de carga, error y vacío en todas las pantallas.
- El mensaje de éxito solo aparece cuando el servidor confirma.

**Fase 11 — Proteger el backend** (diferida; recomendada antes del lanzamiento real)
- Firebase App Check con reCAPTCHA Enterprise, invisible, en el admin y en el portal. El backend rechaza las llamadas sin token válido. En local se usa un debug token.
- Auth anónimo de Firebase solo en el admin, en lugar de la identidad por entorno. Usa el verificador de ID token que ya existe.
- Registrar App Check en `kavacha-app` requiere la aprobación del dueño.

**Entorno local**
- Backend de Kachava en el puerto 3011, porque el 3001 lo usa otro proyecto del dueño.
- Admin en 3002 y portal en 3000.
- Emulador de Firestore y Storage con datos persistentes en `.local-data/`.

**Pendiente del cliente** (no bloquea el desarrollo)
- Textos, precios y fotos de los servicios.
- Nombres de las villas.
- Aprobación del español.
- Prueba en un teléfono real.

## Verificación por fase
- `cd backend && npm run typecheck && npm test`
- `cd admin && dart analyze && flutter test`
- `cd web && dart analyze && flutter test`
- `./run-local.sh` con el emulador, y luego `cd e2e && npx playwright test`, una vez por fase.
- Capturas a 1440 y 375 px.
