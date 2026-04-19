# Log de Sessões

Entradas em ordem cronológica. Adiciona uma nova a cada sessão não-trivial. Foco no *por quê*, não no *o que* (o código já mostra o o quê).

Formato sugerido por entrada:
```
## YYYY-MM-DD — Título curto
**Contexto**: o que havia antes
**Decisão**: o que foi feito
**Razão**: por que (constraint, skill, discussão)
**Impacto**: arquivos/sistemas afetados
```

---

## 2026-04-18 — Bootstrap do projeto + skill godot-senior-dev

**Contexto**: projeto Godot 4.6 vazio, só `project.godot` e ícone.
**Decisão**: criar `CLAUDE.md` documentando o estado inicial e uma skill `godot-senior-dev` com boas práticas de Godot 4 (composição, static typing, sinais, layers, Jolt, performance).
**Razão**: dar ao time (e às próximas sessões com IA) uma baseline compartilhada antes de começar a codar.
**Impacto**: `CLAUDE.md`, `.claude/skills/godot-senior-dev/SKILL.md`.

---

## 2026-04-18 — Protótipo top-down (player vermelho + moeda amarela)

**Contexto**: projeto vazio após bootstrap.
**Decisão**: player 2D top-down com `Input.get_vector(move_*)`, moeda `Area2D` que emite `collected` ao tocar. Cenas separadas em `entities/player/` e `entities/coin/`. Main compõe e escuta.
**Razão**: exercitar a estrutura mínima (cena-por-responsabilidade, sinal child→parent, Input Map).
**Impacto**: `entities/player/*`, `entities/coin/*`, `main.*`, `project.godot` (Input Map).

---

## 2026-04-18 — Score + spawn exponencial de moedas

**Contexto**: player coletava 1 moeda e acabava.
**Decisão**: Main mantém `score: int`, escuta `collected(at)`, spawna 2 moedas novas em posição aleatória próxima. Score rendering num `Label` num `CanvasLayer`.
**Razão**: rejeitar autoload pra score (da skill: "autoload não é pra conveniência"). Main já era o listener e dono natural do estado.
**Impacto**: `main.{gd,tscn}`, `entities/coin/coin.gd` (sinal ganhou `at: Vector2`).

---

## 2026-04-18 — Pivot pra plataformer estilo Hollow Knight

**Contexto**: usuário pediu mudança de gênero (top-down → plataformer lateral).
**Decisão**: reescrever player pra `CharacterBody2D` com gravidade + pulo. Adicionar ground estático, background `CanvasLayer`, inimigo que persegue horizontalmente, spawner temporizado. Player ganhou `Camera2D` filho.
**Razão**: começar o novo gênero do jeito certo em vez de esticar o top-down. Cenas de `coin` ficaram no repo mas desconectadas.
**Impacto**: `entities/player/*` (reescrita), novo `entities/enemy/*`, `main.*`, `project.godot` (+ action `jump`).

---

## 2026-04-18 — Plataformas, HP, game over, stomp, spray

**Contexto**: plataformer mínimo rodando.
**Decisão grande 1**: separar collision layers (Player=1, Enemy=2, World=4). Player e inimigo não se empurram mais — interação via `Area2D` no inimigo. **Simplifica controle** e desacopla dano de física.
**Decisão grande 2**: Nível com 3 chões e 2 buracos; 4 plataformas flutuantes. Queda (`y > 900`) → game over.
**Decisão grande 3**: HP no player com sinais (`health_changed`, `died`), i-frames 1s, flash por `modulate.a`. HUD com 2 barras em `ColorRect` (bg + fill), game over overlay hidden por padrão, restart com Espaço.
**Decisão grande 4**: Spray — bullets `Area2D` com lifetime 0.35s, cone ±17°, cadência 25/s. Carga 100 com dreno 40/s e recarga 25/s. Player emite `fired(at, dir, speed)` e Main instancia. Acumulador com while-loop pra cadência correta em low-fps.
**Decisão grande 5**: Stomp — detectado no `_on_hitbox_body_entered` comparando `velocity.y > 0` E `player.y < enemy.y - 12`. Stomp mata instantâneo + bounce; senão, dano.
**Razão**: seguir as diretrizes da skill — cenas pequenas com responsabilidades claras, sinais pra comunicação, stats ajustáveis via `const` no topo do script.
**Impacto**: `entities/player/*`, `entities/enemy/*`, novo `entities/bullet/*`, `main.*`, `project.godot` (+ action `fire`).

---

## 2026-04-19 — Walker spawna do lado oposto quando player está perto de parede

**Contexto**: depois do clamp, walkers ainda podiam nascer em cima do player quando ele tava colado numa parede. Player perto da parede direita (x=400) + sorteio side=+1 → spawn_x clampado pra 480 → inimigo aparece a 80 px do player, sem chance de reagir.
**Decisão**: extrair `_pick_spawn_side` e detectar proximidade de parede. Se `player.x > 480 - 200 = 280`, walker força `side = -1` (esquerda). Espelho pra parede esquerda. Random só no meio do mapa.
**Razão**: spawn por lado existe pra dar ao player tempo de ver o inimigo chegando. Spawn ao lado mata essa intenção. A constante `WALL_PROXIMITY_THRESHOLD = 200` é o "espaço mínimo de visão" garantido. Flyers continuam random porque eles aparecem voando do nada — surpresa é feature deles.
**Impacto**: `main.gd` (+ constante `WALL_PROXIMITY_THRESHOLD`, função `_pick_spawn_side`), `docs/GAME_RULES.md` (+ linha "Lado forçado" na tabela do Spawner).

---

## 2026-04-19 — Bug: walkers nascendo fora do mapa (clamp horizontal)

**Contexto**: depois do mapa virar vertical (paredes em x=±530, playable ~[-510, 510]), `SPAWN_OFFSET_X = 700` ficou maior que meia-largura do mapa. Player no meio → walker nascia em x=±700, do lado de fora das paredes, sem chão → caía até `DESPAWN_Y` sem nunca aparecer.
**Decisão / fix**: clampar `spawn_x` de walking enemies em `[-480, 480]` (50 px de margem pras paredes). Flyers continuam livres — eles têm `collision_mask = 0` e passam pelas paredes, então nascer fora é feature (entrada surpresa pelo lado).
**Razão**: o spawn original assumia mapa horizontal aberto. Quando o mapa virou vertical e fechado, a constante de offset ficou desatualizada. Em vez de reduzir o offset (perde o "ataque vindo de longe" pros flyers), só clampa walkers — eles não conseguem nascer fora porque não atravessam as paredes.
**Impacto**: `main.gd` (+ constantes `WALKING_SPAWN_X_MIN/MAX`, clamp em `_on_spawn_timer_timeout`), `docs/GAME_RULES.md` (linhas de clamp na tabela do Spawner).

---

## 2026-04-19 — Bug: shake recharge não disparava (mouse_filter na UI)

**Contexto**: shake recharge implementado e mergeado na sessão anterior, mas no teste o `_unhandled_input` do player não recebia nenhum evento de mouse. Action `recharge` registrada no InputMap, prints em `_input` confirmavam que o evento chegava ao Godot. Só `_unhandled_input` ficava silencioso.
**Decisão / fix**: setar `mouse_filter = 2` (IGNORE) em todos os ColorRects decorativos: o Background fullscreen, HealthBarBg/Fill, SprayBarBg/Fill.
**Razão raiz**: `Control.mouse_filter` é `STOP` por padrão. O Background tinha `anchors_preset = 15` (fullscreen) → cobria a tela toda → engolia 100% dos eventos de mouse na pipeline da GUI antes deles virarem "unhandled". A skill recomenda usar `_unhandled_input` pra gameplay; a correção certa é fazer a UI decorativa não consumir input, não trocar pra `_input` (que mata a hierarquia de input).
**Lição registrada em** `docs/ARCHITECTURE.md` (seção "Gotcha — mouse_filter em UI decorativa").
**Impacto**: `main.tscn` (5 ColorRects ganharam `mouse_filter = 2`), `docs/ARCHITECTURE.md` (nova seção).

---

## 2026-04-19 — Recarga do spray por shake (remove recarga passiva)

**Contexto**: spray recarregava passivamente a 25/s ao soltar o fire. Sem desafio, sem identidade de "spray can".
**Decisão**: remover a recarga passiva. Adicionar action `recharge` (clique direito) e detectar **inversões de direção vertical** do mouse enquanto segurado. Cada flip (sinal de `motion.relative.y` muda) rende `SHAKE_RECHARGE_PER_FLIP` = 4 unidades. Filtra `|Δy| < 5 px`. Detecção em `_unhandled_input` (event-driven).
**Razão**: inversão ≠ movimento. Somar cumulativo daria recarga por andar o mouse reto — quebra a intenção de "chacoalhar". Detectar flip premia shake real. Remover recarga passiva força o jogador a escolher entre atirar e recarregar, criando tensão tática.
**Números**: shake vigoroso (~10 flips/s) = ~40 un/s, recarga cheia em ~2.5 s. Shake lento (~3 flips/s) = ~12 un/s, recarga cheia em ~8 s. Dreno de atirar é 40/s, então atirar + shake ao mesmo tempo só sustenta tinta com shake bem rápido.
**Impacto**: `entities/player/player.gd` (novo `_unhandled_input`, `_process_shake`, constantes `SHAKE_*`; removido `SPRAY_RECHARGE_PER_SEC`), `project.godot` (+ action `recharge`), `docs/{GAME_RULES,ARCHITECTURE,SESSION_LOG}.md`.

---

## 2026-04-18 — Mapa duplicado + rota vertical de 9 pulos + level complete

**Contexto**: mapa horizontal curto (~1800 px), 4 plataformas sem rota vertical clara, sem condição de vitória.
**Decisão 1**: duplicar o mapa horizontal de ~1800 px para ~3700 px adicionando 3 segmentos de chão (`Ground4–6`) à direita.
**Decisão 2**: substituir as 4 plataformas antigas por 12 novas. Plataformas 1–9 formam uma escada diagonal +200 px horizontal / +110 px vertical por degrau — exatamente 9 pulos para atingir o nível superior (pulo máximo = 138 px; 110 px dá margem confortável). Plataformas 10–12 são largas (300 px) e estendem o corredor superior de x=1300 até x=2600.
**Decisão 3**: adicionar `FinishZone` (Area2D) no canto superior direito do mapa (x=2750, y=-430). Ao entrar, o spawner para e o overlay "LEVEL COMPLETE!" aparece. Reiniciar com Espaço — mesmo fluxo do game over.
**Decisão 4**: adicionar flying enemy usando sprite animado (`mosca_01.png` / `mosca_02.png`, 8 fps) com flip horizontal baseado em `direction.x` para manter o sprite voltado para onde voa.
**Razão**: dar ao nível uma progressão clara (subir) e uma condição de vitória (alcançar o canto superior direito), estilo Hollow Knight. O cálculo físico (h_max = v²/2g) guiou o espaçamento para garantir que todos os pulos sejam possíveis mas exijam intenção.
**Impacto**: `main.{gd,tscn}` (mapa + level complete UI + FinishZone connection), `entities/enemy/flying_enemy.{gd,tscn}` (sprite + flip), `docs/GAME_RULES.md` (layout atualizado).

---

## 2026-04-18 — Inimigo voador + política de documentação

**Contexto**: um só tipo de inimigo (andador), sem docs.
**Decisão 1**: refatorar `Enemy` como **classe base** (HP, hitbox, stomp, dano, sinal `died`). Criar `WalkingEnemy` (gravidade, chase horizontal) e `FlyingEnemy` (sem gravidade, chase 2D, atravessa plataformas via `collision_mask = 0`). Ambos extendem `Enemy`.
**Razão**: 2 tipos que só diferem em movimento. Herança de 2 níveis é aceita pela skill; composição via componente seria overkill. `body is Enemy` no bullet continua pegando os dois — adicionar um terceiro tipo vai ser trivial.
**Decisão 2**: Main sorteia tipo ao spawnar (50/50), com alturas de spawn diferentes (120 acima pro walking cair no chão; 250 acima pro flying).
**Decisão 3**: criar `docs/{README,ARCHITECTURE,GAME_RULES,SESSION_LOG}.md`. Adicionar regra em `CLAUDE.md` pra IA **atualizar docs a cada decisão**, garantindo que futuros colaboradores (e futuros Claudes) tenham a trilha completa.
**Razão**: o código mostra o *como*, mas o *porquê* vai pro doc. Sem isso, em 2 semanas ninguém sabe por que player e inimigo não se empurram.
**Impacto**: `entities/enemy/{enemy,walking_enemy,flying_enemy}.{gd,tscn}`, `main.gd`, `CLAUDE.md`, `docs/**`.
