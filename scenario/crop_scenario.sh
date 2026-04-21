#!/bin/bash

# Configurações de Bounds (xmin, ymin, xmax, ymax)
BOUNDS="215.03,4016.20,1171.76,4979.51"
XMIN=215.03
YMIN=4016.20
XMAX=1171.76
YMAX=4979.51

# Arquivos de entrada
NET_FILE="hats.net.xml"
VEH_ROUTES="routes/veh.rou.xml"
BIKE_ROUTES="routes/bike.rou.xml"
POLY_FILE="additionals/hats.poly.xml"
OBS_FILE="additionals/hats.obstacles.xml"
SUMOCFG="hats.sumocfg"

# Arquivos de saída
SUFFIX="_cropped"
NET_OUT="hats${SUFFIX}.net.xml"
VEH_OUT="veh${SUFFIX}.rou.xml"
BIKE_OUT="bike${SUFFIX}.rou.xml"
POLY_OUT="additionals/hats${SUFFIX}.poly.xml"
OBS_OUT="additionals/hats${SUFFIX}.obstacles.xml"
SUMOCFG_OUT="hats${SUFFIX}.sumocfg"

echo "--- Iniciando recorte do cenário ---"

# 1. Recortar Rede
echo "Recortando rede..."
netconvert --sumo-net-file "$NET_FILE" \
    --keep-edges.in-boundary "$BOUNDS" \
    --output-file "$NET_OUT" \
    --offset.disable-normalization true

# 2. Recortar Rotas
echo "Recortando rotas (veículos)..."
python3 "$SUMO_HOME/tools/route/cutRoutes.py" "$NET_OUT" "$VEH_ROUTES" --routes-output "$VEH_OUT" --orig-net "$NET_FILE"

echo "Recortando rotas (bicicletas)..."
python3 "$SUMO_HOME/tools/route/cutRoutes.py" "$NET_OUT" "$BIKE_ROUTES" --routes-output "$BIKE_OUT" --orig-net "$NET_FILE"

# 3. Recortar Polígonos (Script Python inline)
echo "Recortando polígonos..."
python3 - <<EOF
import xml.etree.ElementTree as ET
tree = ET.parse('$POLY_FILE')
root = tree.getroot()
to_remove = []
for child in root:
    if child.tag in ['poly', 'poi']:
        shape = child.get('shape')
        inside = False
        if shape:
            for p in shape.split():
                x, y = map(float, p.split(','))
                if $XMIN <= x <= $XMAX and $YMIN <= y <= $YMAX:
                    inside = True; break
        else:
            x, y = child.get('x'), child.get('y')
            if x and y and $XMIN <= float(x) <= $XMAX and $YMIN <= float(y) <= $YMAX:
                inside = True
        if not inside: to_remove.append(child)
for child in to_remove: root.remove(child)
tree.write('$POLY_OUT', encoding='UTF-8', xml_declaration=True)
EOF

# 4. Recortar Obstáculos (Script Python inline - Tratando Y negativo)
echo "Recortando obstáculos..."
python3 - <<EOF
import re
y_min_obs, y_max_obs = -$YMAX, -$YMIN
output_lines = []
with open('$OBS_FILE', 'r') as f:
    lines = f.readlines()
output_lines.append(lines[0])
for line in lines[1:]:
    if '<object' in line:
        match = re.search(r'shape="prism [0-9.]+ (.*?)"', line)
        if match:
            coords = match.group(1).split()
            inside = False
            for i in range(0, len(coords), 2):
                x, y = float(coords[i]), float(coords[i+1])
                if $XMIN <= x <= $XMAX and y_min_obs <= y <= y_max_obs:
                    inside = True; break
            if inside: output_lines.append(line)
    elif '</environment>' in line:
        output_lines.append(line)
with open('$OBS_OUT', 'w') as f:
    f.writelines(output_lines)
EOF

# 5. Criar arquivo .sumocfg
echo "Gerando novo arquivo .sumocfg..."
sed "s|$NET_FILE|$NET_OUT|g; \
     s|$VEH_ROUTES|$VEH_OUT|g; \
     s|$BIKE_ROUTES|$BIKE_OUT|g; \
     s|$POLY_FILE|$POLY_OUT|g; \
     s|$OBS_FILE|$OBS_OUT|g" "$SUMOCFG" > "$SUMOCFG_OUT"

echo "--- Recorte concluído com sucesso! ---"
echo "Para rodar: sumo-gui -c $SUMOCFG_OUT"
