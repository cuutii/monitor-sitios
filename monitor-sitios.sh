#!/usr/bin/env bash
# ============================================================
# monitor-sitios.sh
# ------------------------------------------------------------
# Revisa que los 7 sitios de GitHub Pages sigan arriba y que
# NO se publique nada de estudio (los `.comentado` e
# `INSTRUCCIONES.md`, que existen solo en la compu local).
#
#   FALLO (sale con 1)  sitio caído, o archivo de estudio publicado
#   AVISO (no falla)    servidor-prueba.ps1 publicado, o sitio lento
#
# Por qué los avisos no rompen el build: si el aviso hiciera
# fallar, el indicador estaría rojo de por vida (hoy hay 3
# sitios con el servidor publicado y es decisión del dueño), y
# una alerta que siempre está roja deja de ser una alerta.
#
# Solo hace GET contra los sitios propios en GitHub Pages.
# No prueba credenciales, no escanea, no toca nada de terceros.
#
# Uso:  ./monitor-sitios.sh
#       (en GitHub Actions además escribe el resumen en la página)
# ============================================================

BASE="${BASE:-https://cuutii.github.io}"
UMBRAL_LENTO="${UMBRAL_LENTO:-5}"    # segundos: más que esto = aviso
TIEMPO_ESPERA="${TIEMPO_ESPERA:-20}" # --max-time de curl

SITIOS=(
  gestor-contrasenas
  perito-map
  generador-contrasenas
  Explore-Calafate
  Portfolio-Maximo
  Fernanda
  Progresivo
)

# NUNCA deben estar publicados. Estos nombres salen de los 20
# archivos .comentado que existen de verdad en MIS-PROYECTOS,
# medidos con glob, no inventados de memoria.
PROHIBIDOS=(
  "INSTRUCCIONES.md"
  "index.comentado.html"
  "style.comentado.css"
  "estilos.comentado.css"
  "script.comentado.js"
  "sw.comentado.js"
  "Pagina1.comentado.html"
  "Pagina2.comentado.html"
  "src/app.comentado.js"
  "src/crypto.comentado.js"
  "trigonometria.comentado.cpp"
)

# Informativos: no rompen el build, pero se reportan.
INFORMATIVOS=(
  "servidor-prueba.ps1"
)

# ---------- colores solo si estamos en una terminal ----------
if [ -t 1 ]; then
  ROJO="\033[31m"; AMAR="\033[33m"; VERD="\033[32m"; GRIS="\033[90m"; FIN="\033[0m"
else
  ROJO=""; AMAR=""; VERD=""; GRIS=""; FIN=""
fi

fallos=0
avisos=0
md_sitios=""

printf "%b\n" "${GRIS}============================================================${FIN}"
printf "%b\n" "  MONITOR DE SITIOS - $(date -u '+%Y-%m-%d %H:%M UTC')"
printf "%b\n" "${GRIS}============================================================${FIN}"
echo ""
md_sitios="## 🛰 Monitor de sitios — $(date -u '+%Y-%m-%d %H:%M UTC')\n\n"
md_sitios+="| Sitio | Estado | Tiempo | Archivos de estudio | Informativos |\n"
md_sitios+="|---|---|---|---|---|\n"

for sitio in "${SITIOS[@]}"; do
  url="$BASE/$sitio/"

  # Una sola petición: trae código y tiempo a la vez.
  # --retry 2: un bache de red no debería generar una alerta falsa.
  lectura=$(curl -sS -o /dev/null \
                -w "%{http_code} %{time_total}" \
                --max-time "$TIEMPO_ESPERA" \
                --retry 2 -L "$url" 2>/dev/null || echo "000 0")
  codigo=$(echo "$lectura" | cut -d' ' -f1)
  tiempo=$(echo "$lectura" | cut -d' ' -f2)
  tiempo_form=$(printf "%.2f" "$tiempo" 2>/dev/null || echo "?")

  # ---- archivos de estudio: deben dar 404 ----
  publicados=""
  for archivo in "${PROHIBIDOS[@]}"; do
    c=$(curl -sS -o /dev/null -w "%{http_code}" \
          --max-time "$TIEMPO_ESPERA" \
          "$BASE/$sitio/$archivo" 2>/dev/null || echo "000")
    if [ "$c" = "200" ]; then
      publicados="$publicados \`$archivo\`"
      fallos=$((fallos + 1))
    fi
  done

  # ---- informativos: se reportan, no rompen ----
  info=""
  for archivo in "${INFORMATIVOS[@]}"; do
    c=$(curl -sS -o /dev/null -w "%{http_code}" \
          --max-time "$TIEMPO_ESPERA" \
          "$BASE/$sitio/$archivo" 2>/dev/null || echo "000")
    if [ "$c" = "200" ]; then
      info="$info \`$archivo\`"
      avisos=$((avisos + 1))
    fi
  done

  # ---- estado del sitio ----
  if [ "$codigo" != "200" ]; then
    estado_emoji="🔴"
    estado_txt="FALLO ($codigo)"
    col="$ROJO"
    fallos=$((fallos + 1))
  else
    estado_emoji="🟢"
    estado_txt="200 OK"
    col="$VERD"
  fi

  # ---- lentitud: aviso, no fallo ----
  lento=""
  if [ "$codigo" = "200" ]; then
    if awk "BEGIN{exit !($tiempo > $UMBRAL_LENTO)}" 2>/dev/null; then
      lento=" (lento: ${tiempo_form}s)"
      col="$AMAR"
    fi
  fi

  # ---- archivos de estudio publicados = fallo ----
  est_txt="ninguno"
  est_md="—"
  if [ -n "$publicados" ]; then
    est_txt="PUBLICADO$publicados"
    est_md="🔴$publicados"
    col="$ROJO"
  fi

  info_md="—"
  if [ -n "$info" ]; then
    info_md="🟡$info"
  fi

  # Cuidado con los printf: el número de argumentos tiene que
  # coincidir con el de marcadores, si no los campos se corren.
  printf "  %b %-20s %b%-12s%b  %6ss  %s\n" \
         "$estado_emoji" "$sitio" "$col" "$estado_txt" "$FIN" "$tiempo_form" "$est_txt"
  if [ -n "$info" ]; then
    printf "      %baviso:%b %s\n" "$AMAR" "$FIN" "$info"
  fi
  if [ -n "$lento" ]; then
    printf "      %b%s%b\n" "$AMAR" "$lento" "$FIN"
  fi

  md_sitios+="| $sitio | $estado_emoji $estado_txt | ${tiempo_form}s | $est_md | $info_md |\n"
done

# ---------- resumen ----------
echo ""
printf "%b\n" "${GRIS}------------------------------------------------------------${FIN}"
if [ "$fallos" -eq 0 ]; then
  printf "%b\n" "  ✅ Todo arriba. Archivos de estudio: ninguno publicado."
  md_sitios+="\n### ✅ Sin fallos\n"
else
  printf "%b\n" "  🔴 $fallos fallo(s). Mirá los detalles arriba."
  md_sitios+="\n### 🔴 $fallos fallo(s)\n"
fi
if [ "$avisos" -gt 0 ]; then
  printf "%b\n" "  🟡 $avisos aviso(s) informativo(s) (no rompen el build)."
  md_sitios+="\n🟡 **$avisos aviso(s)** informativo(s): hoy no rompen el build a propósito.\n"
fi
printf "%b\n" "${GRIS}------------------------------------------------------------${FIN}"

# ---------- resumen para GitHub Actions ----------
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  printf "%b" "$md_sitios" >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$fallos" -gt 0 ]; then
  exit 1
fi
exit 0
