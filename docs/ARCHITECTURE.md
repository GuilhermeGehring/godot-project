# Arquitetura

## Stack

- **Engine**: Godot 4.6, renderer Forward Plus, driver Direct3D 12 no Windows.
- **Física**: Jolt Physics (3D, configurado no `project.godot`). O jogo é 2D, então Jolt não afeta nada aqui — mas fica anotado pra caso se adicione 3D depois.
- **Linguagem**: GDScript 2 com tipagem estática em todas as funções e variáveis não-triviais.

## Estrutura de pastas

```
res://
├── entities/
│   ├── player/         player.{gd,tscn}
│   ├── enemy/          enemy.gd (base) + walking_enemy.{gd,tscn} + flying_enemy.{gd,tscn}
│   │                   (enemy.tscn ainda aponta pra walking_enemy.gd por compatibilidade de path)
│   ├── bullet/         bullet.{gd,tscn}
│   └── coin/           coin.{gd,tscn}  (legado do protótipo top-down, não está em main.tscn)
├── main.{gd,tscn}      cena principal (nível + UI + spawners)
├── project.godot       config + Input Map
├── CLAUDE.md           instruções pra IA
├── docs/               este diretório
└── .claude/skills/     skill godot-senior-dev (boas práticas Godot 4)
```

Regra (da skill): **arquivos de uma cena ficam junto dela**. Evite espalhar por pastas genéricas tipo `scripts/` ou `sprites/`.

## Camadas de colisão

| Layer (bit / valor) | Uso                                  |
|---------------------|--------------------------------------|
| 1 (bit 0 / 1)       | Player                               |
| 2 (bit 1 / 2)       | Enemy (qualquer subtipo)             |
| 4 (bit 2 / 4)       | World (ground, plataformas)          |

Masks:
- `Player.collision_mask = 4`: colide só com cenário — passa pelos inimigos.
- `WalkingEnemy.collision_mask = 4`: mesmo.
- `FlyingEnemy.collision_mask = 0`: passa por tudo — voa livre sem bater nas plataformas.
- `Bullet.collision_mask = 6` (2|4): acerta inimigo e cenário, não vê o player (evita auto-fogo).
- `Hitbox` (Area2D do inimigo).`collision_mask = 1`: detecta player.

**Decisão-chave:** player e inimigos não se **empurram fisicamente**. Interação de dano é toda via `Area2D`. Isso simplifica o controle do player (não treme ao encostar num inimigo) e desacopla dano de colisão física.

## Hierarquia de entidades

```
CharacterBody2D
├── Player              (class_name Player)
└── Enemy (base)        (class_name Enemy)          — abstract-ish, sem cena própria
    ├── WalkingEnemy    (class_name WalkingEnemy)   — gravidade + andar horizontal
    └── FlyingEnemy     (class_name FlyingEnemy)    — sem gravidade + chase 2D
```

`Enemy` concentra:
- HP (`max_health`, `_health`)
- `hit(damage)` público (usado pelo Bullet)
- `_on_hitbox_body_entered` (stomp vs dano)
- Sinal `died`
- Despawn por queda (`y > DESPAWN_Y`)

Subclasses sobrescrevem apenas `_update_velocity(delta)`. O template method `_physics_process` fica no base, chama `_update_velocity` e depois `move_and_slide`.

**Por que não composição pura?** Só movimento difere. Extrair um "MovementComponent" seria mais cerimônia que benefício pra 2 tipos. Herança de 2 níveis é aceita pela skill; o limite é 3+ níveis.

## Comunicação entre nós

Segue a regra da skill:
- **Parent → child**: chamada direta de método.
- **Child → parent/irmão**: sinal.
- **Never**: `get_parent()`, paths absolutos (`$/Root/...`), singletons de conveniência.

### Sinais emitidos

| Emissor | Sinal                                | Payload                                   | Ouvinte |
|---------|--------------------------------------|-------------------------------------------|---------|
| Player  | `health_changed(current, max)`       | `int, int`                                | Main    |
| Player  | `spray_changed(current, max)`        | `float, float`                            | Main    |
| Player  | `died`                               | —                                         | Main    |
| Player  | `fired(at, direction, speed)`        | `Vector2, Vector2, float`                 | Main    |
| Enemy   | `died`                               | —                                         | (nenhum por enquanto) |
| Coin    | `collected(at)` (legado)             | `Vector2`                                 | — (legado) |

**Main orquestra.** Player não sabe da HUD, não sabe da cena. Trocar arma ou tirar a HUD não exige mexer em Player.

### Duck-typing

Bullet faz `body is Enemy` + `(body as Enemy).hit(DAMAGE)`. Qualquer coisa que extenda `Enemy` funciona — adicionar um terceiro inimigo não pede mudança no bullet.

## Gameplay — ganchos arquiteturais

### Player

- `CharacterBody2D` com `Camera2D` filho (câmera segue de graça).
- Gravidade puxada de `ProjectSettings.get_setting("physics/2d/default_gravity")` — um único lugar pra ajustar pro jogo inteiro.
- `take_damage` aplica i-frames (1s) via `await get_tree().create_timer(...).timeout` + `modulate.a = 0.5` pro flash.
- `kill()` externo (usado pela queda da plataforma) e morte interna (HP→0) convergem no mesmo sinal `died`.

### Spray

- Estado no player: `spray_charge: float` 0–100.
- Dreno contínuo (`SPRAY_DRAIN_PER_SEC * delta`) enquanto `Input.is_action_pressed("fire")` e `charge > 0`.
- Recarga contínua (`SPRAY_RECHARGE_PER_SEC * delta`) quando não está atirando.
- Cadência controlada por **acumulador**: `_fire_accumulator += delta`, e enquanto >= intervalo, dispara uma bullet. Funciona bem em low-fps (múltiplos tiros por frame, sem perder cadência).
- Direção: `(get_global_mouse_position() - player.global_position).normalized().rotated(random(-spread, +spread))`.
- Bullets spawnam como filhas de `Main` (sibling do Player). Render order fica atrás na árvore → em cima do player visualmente.

### Bullet

- `Area2D` com lifetime curta (0.35s). Posição atualizada por `position += velocity * delta` em `_physics_process`.
- `body_entered` → se é `Enemy`, chama `hit`. Sempre se mata no primeiro contato.
- `collision_mask = 6` → não vê o player, mas acerta inimigo e cenário (parede).

### Spawn de inimigos

- `SpawnTimer` (Timer autostart de 2.5s) em Main.
- Ao timeout: sorteia walking ou flying (`FLYING_CHANCE` = 0.5), escolhe lado, calcula altura relativa ao player, instancia, atribui `target = player`, adiciona como child de Main.
- Inimigos não estão em grupo; Main só sabe do Player via `@onready`. Se crescer, adicionar grupo `"enemies"` é trivial.

## UI

- Health bar e Spray bar: dois `ColorRect` empilhados (background escuro + fill colorido), posicionados em offsets fixos num `CanvasLayer` (layer 100).
- Fill tem `size.x` ajustado pelo ratio atual/máximo ao receber o sinal.
- Game over: `Control` cobrindo a tela (anchors 0,0,1,1), hidden no início, `mouse_filter = IGNORE` pra não consumir eventos.

## Performance

- Sem pool de objetos: bullets e inimigos são instanciados/liberados ao vivo. Suficiente pro protótipo.
- `DESPAWN_Y` no inimigo (= 1500) impede vazamento de memória de quem cai em buracos.
- `_process` em Main só checa fall-death do player. Nenhum loop pesado.
- Flashes e invincibility usam `create_timer` + `await` — cheap pra 1–2 ocorrências, evitar pra centenas.

## Pendências técnicas conhecidas

- Sem object pool de bullets (25/s × muitas bullets em sessão longa = allocation churn).
- Sem knockback no hit do player — só flash.
- Sem sprite/animação — tudo é `ColorRect`.
- Sem som.
- Flying enemy atravessa plataformas — é intencional (fantasma), mas sem pathfinding pode bugar em cenários fechados.
- Enemy não tem grupo/registro; se precisar iterar em todos (ex: "limpar tela"), precisa ou adicionar a grupo ou manter lista em Main.
