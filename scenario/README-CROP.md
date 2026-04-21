# Recorte de Cenário SUMO (Cropping)

Este documento explica o procedimento realizado para criar um recorte (sub-cenário) da simulação Hanover Traffic Scenario.

## Ferramentas Utilizadas
- **netconvert**: Para recortar a rede viária (`.net.xml`).
- **cutRoutes.py**: Ferramenta oficial do SUMO para filtrar rotas que passam pela sub-rede.
- **Python (Custom Scripts)**: Para filtragem de polígonos e obstáculos customizados.

## Procedimento Passo a Passo

### 1. Rede (Network)
A rede foi recortada utilizando o parâmetro `--keep-edges.in-boundary`. É fundamental usar `--offset.disable-normalization true` para manter o sistema de coordenadas original, garantindo que os polígonos e rotas ainda se alinhem perfeitamente.

### 2. Rotas (Routes)
As rotas de veículos e bicicletas foram processadas pelo script `cutRoutes.py`. 
- **Dica**: O uso de `--orig-net` ajuda a recalcular tempos de partida caso as rotas originais sejam fragmentadas.

### 3. Polígonos e POIs
Como o `polyconvert` pode apresentar conflitos de IDs ao processar arquivos SUMO nativos, utilizamos um script Python para manter apenas os elementos cujas coordenadas (`shape` ou `x,y`) estejam dentro do bound definido.

### 4. Obstáculos (Obstacles)
O arquivo `hats.obstacles.xml` utiliza um formato customizado. Observou-se que as coordenadas Y neste arquivo estão invertidas (valores negativos). O script de recorte aplica essa lógica de inversão para filtrar corretamente os objetos no espaço 3D/Ambiente.

## Como usar o script de automação
O arquivo `crop_scenario.sh` automatiza todo este processo. Basta configurar as variáveis de `BOUNDS` no topo do arquivo ou passar novos valores.

```bash
./crop_scenario.sh
```
