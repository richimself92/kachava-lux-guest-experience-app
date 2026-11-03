# Plan — Kachava Lux: link confiable, app instalable, portal del huésped simple y Command Center

## Contexto
- **DESIGN.md** (raíz) define solo cómo se ve el admin (UI/UX).
- **`doc/improvements/spec.md`** define qué hace el admin.
- Además, el dueño reporta tres problemas en producción:
  1. El link del huésped a veces no funciona o muestra datos de otro huésped.
  2. La web app instalada pierde el link al cerrarse.
  3. El portal del huésped es confuso.

**Decisiones ya tomadas (2026-11-02)**
- Alcance: todo lo que pide spec.md.
- El nombre es "Villas". Folio se queda, pero dentro del detalle de Guests/Reservations, no en el menú. TEAM queda fuera de este plan.
- "Resort Host" reemplaza a "Concierge" en el admin y en el portal del huésped.
- Huésped que sigue en la villa después de su fecha de salida: In-house con aviso rojo.
- Los módulos que aún no estén construidos se ocultan del menú.
- Todo servicio o preferencia es configurable desde el admin: crear, editar, desactivar, elegir tipo y opciones.
- Los servicios viejos se borran: yate, buceo, safari, golf, chef, masaje, tour, Included Privileges y los productos de minibar de prueba.
- Los 9 servicios confirmados por Kachava se precargan como borrador.
- Transporte: proveedor externo; el traslado lo pueden pedir el huésped y el staff.

## Referencias visuales del cliente (`doc/improvements/*.jpeg`) — SOLO estructura, orden y opciones
Las imágenes definen qué hay y en qué orden (menú, tarjetas, columnas). **Los colores, radios y tipografía salen siempre de DESIGN.md**, no de las imágenes.
**Menú** (`WhatsApp Image … 16.52.54.jpeg`)
- Encabezado "KACHAVA LUX" con una píldora gris "COMMAND CENTER" a la derecha y una línea divisoria.
- Dashboard tiene ícono de cuadrícula. Seleccionado = tratamiento marrón sobrio según DESIGN.md (fondo marrón tenue `#EEE9E5` + texto marrón `#6D4627` en negrita).
- Etiquetas de sección pequeñas, en mayúsculas y gris: GUEST OPERATIONS, HOSPITALITY, OPERATIONS.
- Ítems sin ícono, texto regular y un chevron ">" gris a la derecha. Mucho espacio vertical.
- Cuando el menú no cabe, aparece un botón circular ↓ abajo.
- Menú final:
  - GUEST OPERATIONS: Reservations, Guests, **Villas** (la imagen dice Residences; el cliente eligió Villas).
  - HOSPITALITY: Services, Experiences, Dining, Transportation, Wellness.
  - OPERATIONS: Tasks, Notifications.
  - **Sin Folio** en el menú: se ve como pestaña "Resumen de estancia" dentro del detalle de Guests/Reservations.
  - **TEAM no entra en este plan**.

**Dashboard** (`WhatsApp Image … 16.53.48.jpeg`)
- Título "Kachava Lux · Overview" con una píldora "Today" a la derecha.
- Grid de 3×2 tarjetas en superficie gris `#F3F3F1`, radio ≤ 12 px (DESIGN.md), número grande (~40 px) y etiqueta gris debajo: Occupied villas, Available villas, Occupancy, Arrivals, Departures, Open requests.
- Debajo, "Today's guest activity": tabla de **3 columnas** (Guest, Villa, Status) con separadores finos, sin bordes de tarjeta.
  - Al tocar una fila se abre el detalle con Resort Host, notas y la pestaña de resumen de estancia (Folio).
- Chips de estado: In-house = fondo verde claro y texto verde; Arrival = fondo azul claro y texto azul (ajustado por contraste); Departure = fondo gris y texto oscuro. El aviso de huésped pasado de su fecha de salida = chip rojo.
- **Sin alertas en el Dashboard**: viven en Notifications.

## Principio de diseño transversal: UI limpia, poco texto (admin y portal del huésped)
- **Que nada se sienta abrumador.** Cada pantalla tiene un objetivo principal y una acción principal visible; lo secundario va en menús o pantallas de detalle.
- **Mínimo texto en pantalla:** títulos cortos y etiquetas de 1–3 palabras. Sin párrafos explicativos, banners de instrucciones, subtítulos decorativos ni "eyebrows" (por ejemplo "SANCTUARY COMMAND CENTER · FR-14").
- **Las explicaciones van en tooltips:** un ícono ⓘ junto al dato (por ejemplo la fórmula de % de ocupación o qué significa un estado). En escritorio se abre al pasar el mouse o con el foco del teclado; en móvil, al tocar el ícono (no hay hover). El texto se lee con lector de pantalla mediante `Tooltip`/`Semantics`.
- **Espacio en blanco generoso**, pocas tarjetas, sin bordes ni colores de más. Íconos con etiqueta, nunca decorativos.
- **Los estados vacíos son una línea más una acción** (por ejemplo "Aún no hay solicitudes · Explorar servicios"), no bloques de texto.
- **Mensajes de confirmación de una línea** que se cierran solos.
- Se implementa con un componente reutilizable `InfoTooltip` en el admin y el portal. En las revisiones de cada fase se pregunta "¿sobra algún texto?" antes de aprobar las capturas.

Orden: primero lo que está roto en producción (fases A y B), después el rediseño. Cada fase es un PR independiente con sus pruebas. **Nada se despliega a producción sin tu aprobación explícita.**

---

## Fase A — Arreglar el link del huésped (urgente)
Causas confirmadas en el código y su arreglo:

1. **El backend guarda los datos en memoria y no comparte cambios entre servidores** (`backend/src/infrastructure/repositories/firestore-stay.repository.ts:41-78`).
   - Hoy: cada servidor de Cloud Run (hasta 2) carga los datos de Firestore una sola vez y después responde desde su memoria. Una estancia creada en un servidor no existe para el otro, así que el link "a veces no funciona". Además, las escrituras a Firestore se lanzan sin esperar (`void work().catch(()=>{})`) con la CPU limitada, y `persistAllStays` sobrescribe datos nuevos con datos viejos.
   - Arreglo: Firestore pasa a ser la única fuente de verdad.
     - Cada petición busca la estancia por `guestTokenUuid`, con índice.
     - Se espera a que cada escritura termine y los errores se reportan.
     - Se escribe solo el documento que cambió.
     - "Reset" actúa sobre Firestore, no sobre la memoria.
     - La caché de 60 s de `guest-token.guard.ts` se elimina o se deja solo por petición.
   - Mientras se termina el arreglo, se puede limitar Cloud Run a `maxScale=1` (`deploy/cloudrun-service.yaml:14`). Requiere tu aprobación.
2. **El portal arranca con datos de un huésped ficticio** ("Alex & Sarah Miller", Villa 102).
   - Hoy: `web/lib/application/sanctuary_controller.dart:24-26` carga datos de prueba al iniciar, y `sanctuary_wire_mapper.dart` completa con esos datos todo lo que el servidor no envía: tarjeta, pareja, Wi-Fi, solicitudes y checklist.
   - Arreglo: pantalla de carga hasta la primera respuesta del servidor, y la pantalla se arma solo con datos reales. Los datos de prueba solo se usan en los tests.
3. **Las estancias nuevas se copian de la plantilla de la Villa 102.**
   - Hoy: `backend/src/modules/admin/admin.service.ts:87-95` copia esa plantilla, con fechas, avatar, chofer y contactos de los Miller.
   - Arreglo: un generador de estancias vacío, sin plantilla.
4. **Un UUID de demostración abre la estancia de los Miller.**
   - Hoy: `SECONDARY_SPEC_GUEST_UUID` (`backend/src/infrastructure/seed/sanctuary-seed.data.ts:14`) es el mismo que usan los datos de prueba del admin para "Chen-Rossi" (`admin/lib/data/admin_seed_fixtures.dart:181`).
   - Arreglo: quitar ese alias y no usar datos de prueba en producción.
5. **El admin inventa links cuando falla la red.**
   - Hoy: si crear una estancia o rotar su token falla, `api_admin_operations_repository.dart:125-134` inventa un UUID local, y `seeded_admin_repository.dart:111,224` muestra "creado" con un link que no sirve.
   - Arreglo: mostrar el error. Además, el build falla si no se configura la URL del portal (`admin/lib/core/app_config.dart:15-23`).
6. **El límite de peticiones se agota.**
   - Hoy: el límite es de 120 peticiones por minuto por IP (`backend/src/app.module.ts:22-27`). El admin hace unas 270 por minuto y cada huésped unas 90, y una respuesta 429 termina mostrando "Acceso restringido".
   - Arreglo: `trust proxy` y contar las peticiones por token. Consultas al servidor menos frecuentes: el huésped cada 10 s, y el admin en una sola llamada `/admin/sync` cada 5 s.
7. **Cualquier error temporal muestra "Acceso restringido".**
   - Hoy: `api_sanctuary_repository.dart:55,69` trata cualquier fallo como "link no encontrado".
   - Arreglo:
     - Solo una respuesta 401/404 significa link inválido.
     - Ante 5xx, 429 o tiempo agotado se mantienen los últimos datos y se muestra un aviso de "reconectando".
     - No se lanza una consulta nueva si la anterior sigue en curso.
     - El mensaje de éxito solo aparece cuando el servidor confirma (`sanctuary_controller.dart:299,436,491,516,550,616`).

**Pruebas:**
- Jest:
  - Dos instancias del repositorio sobre el mismo Firestore falso: lo que se crea en una se lee en la otra.
  - Un fallo de escritura se reporta como error.
  - Una estancia nueva no contiene nada de la plantilla Miller.
  - El guard no tiene caché obsoleta.
- Flutter:
  - Al arrancar se ve la pantalla de carga, no los datos Miller.
  - Una respuesta 503 conserva los datos.
  - Una respuesta 404 muestra el acceso restringido.
  - Si el envío falla, no aparece mensaje de éxito.
- E2E: crear una estancia en el admin, abrir el link y ver los datos correctos, durante 5 minutos de consultas continuas.

## Fase B — Web app instalable y link permanente
Causa: `web/web/manifest.json:4` tiene `start_url: "."`, que abre la app sin `?guestId`, y el guestId no se guarda en ningún lado. Además faltan íconos PNG, así que Android puede no ofrecer la instalación e iOS ignora el SVG.

1. **Íconos:** PNG de 192, 512 y 512 maskable, más un `apple-touch-icon` de 180, generados desde `Kachava Lux - Brand Assets/`.
2. **Manifest:**
   - Agregar `id`, `scope: "/"` y `display: standalone`, y unificar el `theme_color`.
   - En `web/web/index.html`, antes de cargar Flutter, un script lee el `guestId` de la URL o del almacenamiento del navegador y genera un manifest dinámico con `start_url` absoluto `/?guestId=<uuid>`. Así Android e iOS guardan el link del huésped al instalar.
   - Agregar las metas de Apple (`apple-mobile-web-app-capable`, título, status bar).
3. **Guardar el link en el teléfono:** un `GuestIdStore` (interfaz + versión web con `localStorage` + versión vacía para tests). Sigue el mismo patrón de import condicional de `admin/lib/core/alert_chime_port.dart`.
   - Si la URL trae un guestId válido, se guarda. Un link nuevo reemplaza al anterior.
   - Si la URL no lo trae, se usa el guardado y se escribe en la URL con `history.replaceState`.
   - Si el servidor responde 401/404, se borra y se muestra "Tu enlace expiró, pide uno nuevo a tu Resort Host".
4. **Service worker mínimo** (`sw.js`, solo para que sea instalable, sin caché de datos). Hay que ajustar el script de `index.html:17-36` para que no lo desregistre.
5. **Aviso de instalación:**
   - **Android:** se captura `beforeinstallprompt` y se muestra un botón propio "Instalar la app" en Inicio.
   - **iOS:** Safari no tiene aviso automático. Se muestra una guía corta y descartable: "Toca Compartir → Agregar a pantalla de inicio". Se recuerda que el huésped la cerró.
   - Si la app ya corre instalada (`display-mode: standalone`), no se muestra ninguno de los dos.
6. **Pruebas:**
   - Unitarias de `GuestIdStore` y de cómo se resuelve el guestId.
   - Playwright: abrir con guestId, recargar sin guestId y comprobar que es el mismo huésped; un link nuevo cambia de huésped.
   - Prueba manual en Android Chrome y en iPhone Safari: instalar, cerrar del todo la app y volver a abrirla.

## Fase C — Repo y documentación
- Rama `feature/kachava-command-center`.
- Commit de DESIGN.md y del movimiento `docs/`→`doc/` (como renombre).
- Arreglar los enlaces rotos.
- Actualizar DESIGN.md: "Villas", TEAM diferido, las 6 métricas.
- ADRs en `doc/adr/`:
  - 004 catálogo único
  - 005 reloj del resort (America/Cancun)
  - 006 tareas como entidad propia
  - 007 vista segura de la estancia para el huésped
  - 008 Firestore como única fuente de verdad

## Fase D — Diseño visual y navegación del admin (solo UI)
- **Tokens:** `admin/lib/core/theme/kachava_tokens.dart` con la paleta de DESIGN.md. El borde de los inputs es `#80868B`; el oliva nunca se usa para texto.
- **Tema:** un `ThemeData` completo en `admin_theme.dart`, con la fuente Roboto empaquetada. `KachavaAdminColors` queda como alias obsoleto.
- **Componentes:** `AdminDataTable`, `StatusChip`, `KpiTile`, `AsyncStateView`, `ConfirmDialog`, `UnavailableValue`, y un anillo de foco doble para teclado.
- **Navegación:** un modelo de menú por secciones, sin números (`admin/lib/presentation/navigation/admin_nav_model.dart`).
  - Se mantienen los ids actuales (`nav-tab-<id>`, `workspace-<id>`) para no romper los tests.
  - Lo que aún no exista queda oculto.
  - Escritorio: sidebar. Tablet: rail. Móvil: drawer.
- **Pruebas:** contraste, menú, actualizar los tests que buscan títulos con número, y el E2E selecciona por id.

## Fase E — Datos base (backend + admin)
- **Vista segura para el huésped:** `GET /stays/:uuid` deja de devolver todo. Una proyección `toGuestStayView()` excluye las notas internas y los datos del staff.
- **Fechas:**
  - Formato `YYYY-MM-DD` validado, calculadas con `ResortClockPort` (America/Cancun).
  - Se eliminan las fechas falsas por defecto (`admin.service.ts:188`, `stays_dialogs.dart:217`).
  - Script de migración con `--dry-run`.
- **Villas en el backend:** `GET/POST/PATCH /admin/villas`, con estado operativo, de limpieza y de mantenimiento editables desde el admin.
- **Estancias:** Resort Host asignado (`PATCH /admin/stays/:id/host`; si no hay, dice "Sin asignar") y notas internas.
- **Ajustes del resort** editables desde el admin: horas de check-in y check-out, aeropuertos y el margen de tiempo para traslados de salida.
- **Controlador del admin:** dividir `admin_dashboard_controller.dart` (545 líneas) detrás de una fachada que no cambia lo que usa el resto de la app.

## Fase F — Dashboard
- `GET /admin/dashboard` devuelve la fecha del resort, las 6 métricas y la tabla de actividad.
- Funciones puras:
  - `deriveActivityStatus`: Arrival si hoy es su check-in, Departure si hoy es su check-out, In-house si ya hizo check-in, y aviso rojo si se pasó de la fecha de salida.
  - `computeDashboardKpis`.
- La pantalla `overview_workspace.dart` se rehace según la imagen del cliente:
  - Título y píldora "Today".
  - Grid de 3×2 `KpiTile`, con la fórmula en un tooltip ⓘ.
  - Tabla de 3 columnas (Guest, Villa, Status). La fila abre el detalle (Resort Host, notas, resumen de estancia).
  - Sin alertas en esta pantalla.

## Fase G — Catálogo único de servicios (backend)
`ServiceItem` en la colección `catalog_services`:

| Campo | Valores / notas |
|---|---|
| `category` | VILLA_STOCKING, DINING, WELLNESS, IN_VILLA_COMFORT, TRANSPORTATION, EXPERIENCE |
| `requestMode` | ORDER, BOOKING, PREFERENCE, TRIP |
| `name` / `description` | EN/ES. Si falta el español se muestra "traducción pendiente"; nunca se traduce automáticamente |
| Precio | Incluido, fijo, por persona, por unidad o a consultar |
| `options[]` | Productos, tipos de almohada, aromas, horarios… |
| Otros | Capacidad, anticipación, proveedor/responsable |
| `status` | DRAFT, ACTIVE, DISABLED |

- **Endpoints:** el admin usa `GET/POST/PATCH /admin/services`, protegido por rol. El huésped usa `GET /catalog/services?category`, que solo devuelve servicios activos.
- **Precios:** `quoteService()` reemplaza los precios fijos en el código (`guest-booking.service.ts:255-291`). Un servicio desactivado devuelve error, sin precio por defecto.
- **Limpieza:** script con `--dry-run` que exporta Firestore antes de borrar y pide tu confirmación antes de tocar producción. Borra los servicios viejos y sus seeds (`sanctuary-catalog.seed.ts`, `sanctuary-yacht.seed.ts`, `web/lib/data/seed/villa_102_*`). Las reservas pasadas guardan el título del servicio para que el Folio no se rompa.
- **Precarga de los 9 servicios como borrador:**

  | Servicio | Categoría | Cómo lo usa el huésped |
  |---|---|---|
  | Abastecimiento de villa | VILLA_STOCKING | Lo pide (productos con cantidades) |
  | Lux bar | DINING | Lo pide |
  | Desayuno | DINING | Elige horario y opciones (incluido) |
  | Aromaterapia | WELLNESS | Elige aroma o reserva sesión (lo decide el admin) |
  | Menú de almohadas | IN_VILLA_COMFORT | Elige una opción |
  | Traslado aeropuerto Cancún/Tulum | TRANSPORTATION | Pide viaje de llegada o salida |
  | Transporte local privado | TRANSPORTATION | Pide viaje local |
  | Parrillada (grill experience) | EXPERIENCE | La reserva |
  | Experiencia sensorial mexicana | EXPERIENCE | La reserva |

## Fase H — Admin: Services y vistas por categoría
- **Services:** tabla con filtros, formulario EN/ES para crear y editar, y activar/desactivar con confirmación.
- **Experiences, Dining, Transportation y Wellness** son un solo componente, `ServiceCategoryWorkspace(category)`: el catálogo filtrado arriba y las solicitudes de esa categoría abajo.
- **Transporte:**
  - Lista de proveedores (nombre, teléfono, email).
  - Entidad "viaje": tipo llegada, salida o local.
  - Estados: Solicitado → Enviado al proveedor → Confirmado (con chofer, teléfono y vehículo anotados) → En camino → Completado, más Cancelado.
  - El staff también puede crear viajes en nombre del huésped.
  - Lo que hoy está en `flightTransfer` se migra a viajes de llegada.

## Fase I — Portal del huésped simple (mismo estilo visual de la marca)
**Problemas actuales:**
- Cinco formas de navegar: mosaicos numerados, barra inferior, el drawer "todas las pantallas", el botón "ver las 13 pantallas" y el medallón de la villa.
- Títulos con números y "PASO 1/2/3".
- Jerga: Sanctuary, Larder, Philosophy, 432Hz, SLA, "HOST ADMIN".
- Textos de 8–10 px.
- Cada flujo usa estados con nombres distintos.
- Mensajes de éxito aunque el envío falle.

**Nueva estructura: una sola navegación, con 4 pestañas abajo**
1. **Inicio:** saludo, villa y fechas, y tarjetas de "Lo próximo" que cambian según el momento de la estancia.
   - Antes de llegar: registra tu vuelo, elige tus preferencias.
   - Durante: Wi-Fi, servicios destacados, encuesta de mitad de estancia.
   - Último día: tu salida y tu traslado.
   - Incluye el botón o la guía para instalar la app.
2. **Servicios:** secciones que se arman solas con el catálogo activo (Abastecimiento, Dining, Wellness, Comodidad, Transporte, Experiencias). Una categoría sin servicios activos no aparece.
   - Cada tarjeta muestra foto, nombre, una línea de descripción, precio o "Incluido" y la anticipación necesaria.
   - Al tocarla se abre una hoja con un solo formulario, según el tipo:
     - **Pedir:** +/- y Enviar.
     - **Reservar:** fecha, hora, personas, notas.
     - **Elegir preferencia:** opciones y Guardar.
     - **Viaje:** vuelo o destino.
3. **Mis solicitudes:** una sola lista con 4 estados en lenguaje simple: Recibida → Confirmada → En preparación / En camino → Lista. Se puede cancelar o cambiar mientras esté en "Recibida". Muestra los datos del chofer cuando el viaje se confirma.
4. **Resort Host:** foto y nombre del Resort Host asignado, chat y botón para adjuntar foto real.

**Reglas generales:**
- Texto mínimo de 14 px (12 px para etiquetas) y sin jerga.
- Estados de carga, vacío y error en todas las pantallas.
- Confirmaciones que aparecen junto al botón y se cierran solas.
- El idioma se detecta del navegador y se recuerda.
- Los contenidos en español vienen del campo ES del catálogo.

**Se elimina:**
- El drawer "todas las pantallas" y los títulos numerados.
- Las pantallas Yacht, Included y Philosophy (contenido inventado).
- El badge que siempre está encendido.
- El teléfono fijo en el código y los mensajes de "copiado" que no copian nada.

**Implementación:**
- `ServiceCatalogRepository` en `web/lib/domain/repositories`.
- Componentes reutilizables `ServiceListSection` y `ServiceDetailSheet`.
- Reescribir `sanctuary_shell.dart`, `sanctuary_bottom_nav.dart`, `home_screen.dart` y `screen_id.dart`.
- Eliminar `screen_switcher_drawer.dart`.

**Pruebas:** widget tests por flujo (pedir, reservar, preferencia, viaje, error de red) y actualizar `e2e/tests/guest-portal.e2e.spec.ts`.

## Fase J — Operaciones: Tasks y Notifications
- **Tasks:**
  - Colección `tasks`; cada solicitud o viaje puede generar varias tareas.
  - Estados: Pending → Assigned → In Progress → Completed, con responsable, fecha límite y confirmación de cumplimiento (`transitionTask()` como función pura).
  - El estado vencido se calcula al leer.
- **Notifications:**
  - Se agregan `targetRef` y categorías nuevas.
  - Niveles: Info, Acción pendiente, Urgente.
  - `shouldChime()` solo suena con alertas urgentes. Se quita el sonido por cada pedido (`admin_dashboard_controller.dart:162-197`).
  - Botón "Abrir registro" que lleva a lo que originó la alerta.

## Fase K — Guest Operations
- **Reservations:** tabla y calendario villa × día. Origen y pagos muestran "Sin integración PMS".
- **Guests:** perfil por estancia (preferencias, alergias, historial de solicitudes, notas internas, chat). Solo lo ven HOST_ADMIN y CONCIERGE_STAFF.
- **Villas:** estado de ocupación, limpieza y mantenimiento.
- **Folio:** sale del menú. `folio_workspace.dart` pasa a ser la pestaña "Resumen de estancia" dentro del detalle de Guests/Reservations, en formato de tablas y sin cambios de comportamiento.

## Fase L — Proteger el backend (DIFERIDA: después de probar en local todo lo anterior)
Objetivo: que el backend solo atienda a las apps reales, sin login visible. El front no se protege por ahora; el admin sigue sin ninguna pantalla de login.
- **Firebase App Check (admin y portal):**
  - Proveedor reCAPTCHA Enterprise, invisible para el usuario.
  - Las apps envían `X-Firebase-AppCheck` en cada llamada.
  - El backend lo verifica con `firebase-admin` (`appCheck().verifyToken`) mediante un guard global, y responde 401 si falta o es inválido.
  - En local se usa un debug token de App Check.
  - Bloquea scripts, curl, bots y otros orígenes, incluido el uso de `/admin/auth/login` desde fuera de la app y el barrido de `guestId` al azar.
- **Auth anónimo de Firebase (solo admin):**
  - Reemplaza la sesión silenciosa basada en un correo de staff embebido en el build.
  - Cada navegador obtiene un ID token anónimo (vence cada hora y se renueva solo).
  - El backend lo verifica con el `firebase-id-token.verifier.ts` existente.
  - Permite bloquear un dispositivo y limitar peticiones por uid.
  - En el portal del huésped no se usa (link `guestId` + App Check), para no acumular cuentas anónimas.
- **Pendiente con aprobación del dueño:** registrar App Check y reCAPTCHA Enterprise en `kavacha-app`, confirmar el tramo gratuito de reCAPTCHA y, si se usa Identity Platform, la limpieza automática de cuentas anónimas de más de 30 días.

---

## Verificación (cada fase)
- `cd backend && npm run typecheck && npm test`
- `cd admin && dart analyze && flutter test`
- `cd web && dart analyze && flutter test`
- `./run-local.sh`, luego `cd e2e && npx playwright test`
- En las fases con UI: capturas a 1440, 800 y 375 px, y revisión de teclado y contraste.
- Fase B: prueba real en Android e iPhone (instalar, cerrar, reabrir).
- Despliegue a producción solo con tu aprobación explícita.

## Pendiente de Kachava (no bloquea A–F)
- Textos, precios y fotos de los 9 servicios, incluido qué es exactamente el Lux bar.
- Nombres reales de las 8 villas.
- Aprobación de los textos en español.
