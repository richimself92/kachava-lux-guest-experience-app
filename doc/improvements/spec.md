# Ronda de cambios para el Command Center de Kachava Lux

## Dashboard del Command Center

### Overview
| Métrica | Descripción |
| :--- | :--- |
| **Villas ocupadas** | Cantidad de villas actualmente con huéspedes |
| **Villas disponibles** | Villas libres y listas para asignación |
| **% de ocupación** | Porcentaje actual de ocupación del resort |
| **Llegadas** | Check-ins programados |
| **Salidas** | Check-outs programados |
| **Open requests** | Solicitudes activas o pendientes |

---

### Tabla principal (`Guest activity`)

| Guest | Villa | Status | Resort Host Asignado | Notas |
| :--- | :--- | :--- | :--- | :--- |
| *Nombre del Huésped* | *Número/Nombre* | In-house / Arrival / Departure | *Host asignado* | *Notas y observaciones* |

**Estados de estancia (`Status`):**
* `In-house`
* `Arrival`
* `Departure`

---

## Guest Operations

| Módulo | Información y Funciones |
| :--- | :--- |
| **Reservaciones** | Calendario de reservaciones, check-in/check-out, origen de reserva, número de huéspedes, estado, pagos registrados en el PMS y Resort Host asignado. |
| **Huéspedes** | Perfil del huésped, idioma, preferencias, alergias, ocasiones especiales, historial de solicitudes, notas internas y comunicación con su Resort Host. |
| **Villas** | Las ocho villas, disponibilidad, ocupación, estado de limpieza, mantenimiento, características de cada residencia y huéspedes asignados. |

---

## Hospitality

> **Arquitectura técnica:** `Services` debe funcionar como el catálogo maestro, mientras que `Dining`, `Transportation`, `Wellness` y `Experiences` funcionarán como vistas especializadas de dicho catálogo para evitar el desarrollo de cinco bases de datos independientes.

| Módulo | Información y Funciones |
| :--- | :--- |
| **Services** | Catálogo maestro de servicios. Permite al Master Admin agregar y editar todos los servicios incluidos o adicionales, precios, disponibilidad, tiempos de anticipación, proveedor o responsable y estado de solicitud. |
| **Experiences** | Experiencias privadas, culturales, gastronómicas y de aventura; itinerarios, disponibilidad, reservaciones, número de participantes y proveedores. |
| **Dining** | Desayunos incluidos, chef privado, in-villa grill experience, solicitudes especiales, horarios, preferencias alimentarias y órdenes pendientes. |
| **Transportation** | Traslados aeropuerto-resort, SUV asignada, horarios, información de vuelo, chofer, número de pasajeros y estado del servicio. |
| **Wellness** | Masajes, faciales, yoga, meditación, sound healing, personal training, tratamientos de belleza y reservas de especialistas. |

---

## Operations

Concentra la ejecución y el seguimiento operativo del servicio:

### Tasks
Cada solicitud debe convertirse en una tarea operativa cuando requiera ejecución.
* **Campos requeridos:** Villa, huésped, categoría, responsable, prioridad, fecha límite, estado y confirmación de cumplimiento.
* **Flujo de estados sugerido:** `Pending` → `Assigned` → `In Progress` → `Completed`.

### Notifications
* Centro de alertas para nuevas reservaciones, llegadas, solicitudes, cambios de itinerario, tareas vencidas, incidencias y mensajes de huéspedes.
* Redirección directa al registro o ficha correspondiente desde cada alerta.
* Clasificación por nivel de severidad: informativas, acciones pendientes y situaciones urgentes.
* Alertas sonoras restringidas únicamente a eventos críticos que requieran intervención inmediata.

---