# Monitoring & Observability

Este documento resume cómo mantener visibilidad sobre la API desplegada en `https://access-control.eukahack.com` usando herramientas externas gratuitas y verificaciones manuales.

## 1. Monitoreo de salud con UptimeRobot

UptimeRobot permite crear un monitor HTTPS gratuito que revisa la API cada 5 minutos y envía alertas por correo cuando falla.

### Pasos

1. Registrarse o iniciar sesión en [https://uptimerobot.com](https://uptimerobot.com).
2. Ir a **Add New Monitor**.
3. Configurar:
   - **Monitor Type**: HTTPS (port 443)
   - **Friendly Name**: `Access Control API`
   - **URL/IP**: `https://access-control.eukahack.com/api/v1/health`
   - **Monitoring Interval**: 5 min (mínimo gratuito)
   - **Alert Contacts**: seleccionar correo/Telegram/Slack deseado
4. Guardar. UptimeRobot comenzará a consultar el endpoint y notificará cualquier downtime.

> El endpoint devuelve `{ success: true, message: 'API funcionando correctamente', ... }` cuando el backend responde. Si Traefik o la app fallan se registrará como downtime.

## 2. Verificación de certificados y Traefik

Traefik emite certificados TLS con Let's Encrypt. Es importante revisar periódicamente que continúe renovándolos.

### Revisión manual (semanal o tras cambios)

1. Ingresar a Portainer → **Stacks** → stack de Traefik → contenedor `traefik`.
2. Abrir **Logs** y filtrar por `acme` o `letsencrypt`.
3. Buscar mensajes como:
   - `"Certificates obtained for domains [access-control.eukahack.com]"`
   - `"Server configuration reloaded"`
4. Si aparecen errores (`timeout during challenge`, `unable to generate certificate`), verificar:
   - DNS A/AAAA del dominio apunta al servidor
   - Puerto 80/443 abiertos
   - Servicio `app` sigue conectado a la red externa `InventNet`

### Inspección del certificado desde la terminal

```powershell
openssl s_client -connect access-control.eukahack.com:443 -servername access-control.eukahack.com | openssl x509 -noout -dates -subject -issuer
```

Esto muestra la fecha de expiración y el emisor (Let's Encrypt). Recomendación: ejecutar mensualmente o automatizarlo en un job de monitorización.

## 3. Checklist posterior a despliegues

1. `docker stack ps access-control-production` (o Portainer) para confirmar tareas saludables.
2. Revisar logs del servicio `app` (debe mostrar `Callback server.listen ejecutado`).
3. Verificar el monitor de UptimeRobot no registra downtime.
4. Ejecutar manualmente `curl https://access-control.eukahack.com/api/v1/health` desde una máquina externa.
5. Revisar logs de Traefik para certificar que detectó el backend y no hay errores ACME.

Con estos pasos se cubren alertas proactivas (UptimeRobot) y validación de certificados (Traefik/openssl).
