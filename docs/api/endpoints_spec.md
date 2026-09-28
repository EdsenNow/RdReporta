# RDReporta - Especificación de Endpoints REST API

Base URL local: `http://localhost:5000/api` o `https://localhost:7001/api`  
Formato de intercambio: `application/json`  
Autenticación: `Bearer <JWT_TOKEN>` en cabecera `Authorization`

---

## 1. Módulo Auth (`/api/auth`)

| Método | Endpoint | Acceso | Descripción |
|---|---|---|---|
| `POST` | `/api/auth/register` | Público | Registra un nuevo ciudadano con correo, username y contraseña. |
| `POST` | `/api/auth/login` | Público | Inicia sesión y devuelve Access Token (JWT) y Refresh Token. |
| `POST` | `/api/auth/google` | Público | Autenticación/registro con token ID de Google. |
| `POST` | `/api/auth/apple` | Público | Autenticación/registro con credenciales Apple. |
| `POST` | `/api/auth/refresh` | Público | Renueva el Access Token utilizando un Refresh Token válido. |
| `POST` | `/api/auth/logout` | Autenticado | Invalida el Refresh Token actual. |
| `POST` | `/api/auth/forgot-password` | Público | Envía correo de recuperación de contraseña. |
| `POST` | `/api/auth/reset-password` | Público | Restablece la contraseña con token temporal. |

---

## 2. Módulo Users (`/api/users`)

| Método | Endpoint | Acceso | Descripción |
|---|---|---|---|
| `GET` | `/api/users/me` | Autenticado | Obtiene la información del perfil del usuario en sesión. |
| `PATCH` | `/api/users/me` | Autenticado | Actualiza datos del perfil (avatar, zona/provincia). |
| `GET` | `/api/users/{id}` | Autenticado | Obtiene el perfil público de un usuario y sus estadísticas. |
| `GET` | `/api/users/me/posts` | Autenticado | Listado paginado de publicaciones creadas por el usuario. |

---

## 3. Módulo Categories (`/api/categories`)

| Método | Endpoint | Acceso | Descripción |
|---|---|---|---|
| `GET` | `/api/categories` | Público | Retorna lista de categorías activas (con íconos y colores). |
| `POST` | `/api/categories` | Admin | Crea una nueva categoría. |
| `PUT` | `/api/categories/{id}` | Admin | Modifica una categoría existente. |

---

## 4. Módulo Posts & Feeds (`/api/posts`)

| Método | Endpoint | Acceso | Descripción |
|---|---|---|---|
| `POST` | `/api/posts` | Autenticado | Crea un nuevo reporte con coordenadas, fotos y categoría. |
| `GET` | `/api/posts/{id}` | Público/Auth | Obtiene el detalle completo de una publicación. |
| `DELETE` | `/api/posts/{id}` | Autenticado | Elimina un reporte propio (o por moderador). |
| `GET` | `/api/posts/feed` | Autenticado | Feed "Para Ti" paginado con cursor. |
| `GET` | `/api/posts/nearby` | Público/Auth | Feed "Cerca de Mí" filtrado por `lat`, `lng`, `radiusKm`. |
| `GET` | `/api/posts/recent` | Público/Auth | Feed "Recientes" orden cronológico inverso. |
| `GET` | `/api/posts/popular` | Público/Auth | Reportes con mayor tracción e impacto en los últimos 7 días. |
| `GET` | `/api/posts/map` | Público/Auth | Puntos geográficos simplificados para renderizar en mapa con filtros. |

---

## 5. Módulo Reacciones y Confirmaciones

| Método | Endpoint | Acceso | Descripción |
|---|---|---|---|
| `POST` | `/api/posts/{id}/reactions` | Autenticado | Añade una reacción (*Me interesa*, *Importante*, *Impactante*, *Estoy aquí*). |
| `DELETE` | `/api/posts/{id}/reactions` | Autenticado | Retira una reacción previamente dada. |
| `POST` | `/api/posts/{id}/confirm` | Autenticado | Confirma el reporte como verídico. Puede enviar coordenadas del confirmador. |
| `DELETE` | `/api/posts/{id}/confirm` | Autenticado | Retira la confirmación ciudadana. |

---

## 6. Módulo Moderación (`/api/moderation`)

| Método | Endpoint | Acceso | Descripción |
|---|---|---|---|
| `POST` | `/api/posts/{id}/report` | Autenticado | Reporta una publicación por contenido indebido o información falsa. |
| `GET` | `/api/moderation/reports` | Moderador | Lista de denuncias pendientes con orden de prioridad. |
| `POST` | `/api/moderation/reports/{id}/resolve` | Moderador | Dictamina acción sobre la denuncia (aprobar, ocultar post, sancionar). |

---

## 7. Módulo Notificaciones (`/api/notifications`)

| Método | Endpoint | Acceso | Descripción |
|---|---|---|---|
| `GET` | `/api/notifications` | Autenticado | Lista de notificaciones in-app del usuario. |
| `PATCH` | `/api/notifications/{id}/read` | Autenticado | Marca una notificación como leída. |
| `POST` | `/api/notifications/fcm-token` | Autenticado | Registra o renueva el token FCM del dispositivo. |
