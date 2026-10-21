# Monitor de Sitios

Revisa cada 6 horas que los 7 sitios de GitHub Pages de [cuutii](https://github.com/cuutii) sigan arriba y que no se publique nada que no debe.

## Qué revisa

**Falla (acción roja + mail):**
- Un sitio no responde con 200
- Aparece publicado un archivo de estudio (`.comentado` o `INSTRUCCIONES.md`)

**Avisa pero no falla:**
- `servidor-prueba.ps1` publicado (hoy en 3 sitios, decisión del dueño)
- Un sitio tarda más de 5 segundos en responder

## Los 7 sitios monitoreados

| Sitio | URL |
|---|---|
| gestor-contrasenas | https://cuutii.github.io/gestor-contrasenas/ |
| perito-map | https://cuutii.github.io/perito-map/ |
| generador-contrasenas | https://cuutii.github.io/generador-contrasenas/ |
| Explore-Calafate | https://cuutii.github.io/Explore-Calafate/ |
| Portfolio-Maximo | https://cuutii.github.io/Portfolio-Maximo/ |
| Fernanda | https://cuutii.github.io/Fernanda/ |
| Progresivo | https://cuutii.github.io/Progresivo/ |

## Cómo funciona

- **Cada 6 horas** corre automáticamente (cron en GitHub Actions)
- **Manual**: pestaña Actions → "Monitor de Sitios" → "Run workflow"
- **Si falla**: GitHub manda un mail con el detalle
- **Resumen**: cada corrida genera un reporte en la pestaña Actions

## Correrlo en local

```bash
# Los 7 sitios
bash monitor-sitios.sh

# Solo algunos
bash monitor-sitios.sh gestor-contrasenas perito-map

# Contra otro servidor (para pruebas)
BASE=http://localhost:8130 bash monitor-sitios.sh .
```

No necesita dependencias: solo `curl` y `bash`.

## Ética

Solo hace peticiones GET a los 7 sitios propios en GitHub Pages. No prueba credenciales, no escanea redes, no toca nada de terceros.
