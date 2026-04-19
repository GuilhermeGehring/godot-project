# Regras do Game

Stats e comportamentos oficiais. Fonte da verdade — se o código divergir, **atualiza isso aqui** na mesma mudança.

## Controles

| Ação               | Input                          |
|--------------------|--------------------------------|
| Andar esquerda     | `A` ou seta esquerda           |
| Andar direita      | `D` ou seta direita            |
| Pular              | `Espaço`                       |
| Spray              | Click esquerdo do mouse (segura) |
| Reiniciar (após game over) | `Espaço`               |

Os inputs são declarados no **Input Map** (Project Settings → Input Map). Não hardcode teclas no código.

## Player

| Stat               | Valor                          |
|--------------------|--------------------------------|
| HP máximo          | 5                              |
| Velocidade         | 320 px/s                       |
| Velocidade de pulo | v.y = -520 (inicial)           |
| Bounce (stomp)     | v.y = -380                     |
| Invencibilidade após hit | 1.0 s (flash `modulate.a = 0.5`) |
| Tamanho            | 32×48 px (retângulo vermelho)  |
| Colliding com      | Só cenário (layer 4)           |

Game over acontece se:
- HP chega a 0, ou
- `global_position.y > 900` (caiu num buraco)

Reiniciar: aperta Espaço na tela de game over → `get_tree().reload_current_scene()`.

## Spray

| Stat                     | Valor            |
|--------------------------|------------------|
| Carga máxima             | 100              |
| Dreno enquanto atira     | 40 unidades/s    |
| Recarga quando solto     | 25 unidades/s    |
| Cadência                 | 25 tiros/s (intervalo 0.04 s) |
| Ângulo do cone (spread)  | ±0.30 rad (~±17°) |
| Velocidade da bullet     | 750 px/s         |
| Lifetime da bullet       | 0.35 s (alcance ~260 px) |
| Dano por bullet          | 1                |

Detalhes:
- Mira pela posição do mouse no mundo (`get_global_mouse_position()`).
- Bullet morre no primeiro contato (inimigo ou parede).
- Quando a carga zera, o spray para de atirar mesmo se o botão continuar pressionado. Só volta quando a carga estiver > 0 (recarga é automática soltando o botão).

## Inimigos

Base comum:
- HP: 3
- Dano ao encostar no player: 1
- Morrem com 1 stomp ou 3 bullets
- Despawnam se caírem abaixo de `y = 1500`

### Walking enemy (roxo, 28×28)

| Stat                      | Valor                  |
|---------------------------|------------------------|
| Velocidade horizontal     | 160 px/s               |
| Gravidade                 | sim (padrão do projeto) |
| Colliding com             | Só cenário (layer 4)   |
| Comportamento             | anda horizontalmente até o player, cai nos buracos |

Cor: `Color(0.4, 0.12, 0.5, 1)`.

### Flying enemy (ciano, 24×24)

| Stat                  | Valor                                      |
|-----------------------|--------------------------------------------|
| Velocidade (2D)       | 140 px/s                                   |
| Gravidade             | não                                        |
| Colliding com         | nada (collision_mask = 0) — atravessa plataformas |
| Comportamento         | voa em linha reta até o player (`direction.normalized() * speed`) |

Cor: `Color(0.2, 0.75, 0.9, 1)`.

## Stomp

Ao encostar no inimigo via Hitbox do inimigo, checa:
```
player.velocity.y > 0.0           # player está caindo
AND
player.global_position.y < enemy.global_position.y - 12.0   # player está acima
```
- Se **ambos verdadeiros** → stomp: inimigo morre, player leva bounce (v.y = -380).
- Caso contrário → player leva 1 de dano (ignorado se estiver em i-frames).

Stomp funciona tanto em walking quanto em flying.

## Spawner

| Stat                         | Valor                                |
|------------------------------|--------------------------------------|
| Intervalo                    | 2.5 s (Timer autostart)              |
| Chance de ser voador         | 50%                                  |
| Distância horizontal         | 700 px à esquerda ou direita do player (sorteado) |
| Altura acima do player (walking) | 120 px                          |
| Altura acima do player (flying)  | 250 px                          |

Não há limite máximo de inimigos vivos (pode acumular em sessões longas — ver `docs/ARCHITECTURE.md` → Pendências).

## Layout do nível

Player spawna em `(-600, 400)`.

### Chão (3 segmentos)

| Nó            | Centro          | Tamanho      |
|---------------|-----------------|--------------|
| GroundLeft    | (-600, 600)     | 500×100      |
| GroundMid     | (0, 600)        | 500×100      |
| GroundRight   | (700, 600)      | 500×100      |

Buracos: `x ∈ [-350, -250]` e `x ∈ [250, 450]`.

### Plataformas flutuantes (4)

| Nó         | Centro          | Tamanho    |
|------------|-----------------|------------|
| Platform1  | (-300, 450)     | 150×20     |
| Platform2  | (350, 400)      | 150×20     |
| Platform3  | (-100, 350)     | 200×20     |
| Platform4  | (600, 300)      | 200×20     |

Platform1 e Platform2 servem como ponte pros buracos. Platform3 e Platform4 são alturas pra o player subir.

## UI

- **Health bar**: canto superior esquerdo, (20, 20) a (220, 40), 200×20 px. Cor fill `Color(0.9, 0.15, 0.15)`. Fundo `Color(0.2, 0.02, 0.02)`.
- **Spray bar**: logo abaixo, (20, 48) a (220, 68). Fill amarelo `Color(1, 0.85, 0.2)` (mesmo tom da bullet).
- **Game over overlay**: ocupa tela inteira, preto translúcido, label centralizado "GAME OVER / Press SPACE to restart", fonte 48pt.
- **Background**: `CanvasLayer` fixa, cor `Color(0.08, 0.1, 0.15)` (azul-escuro).

## Legado (não ativo)

- `entities/coin/`: scene da moeda + script. Era do protótipo top-down anterior; ficou após o pivot pra plataformer. Pode ser removido ou reaproveitado pra uma mecânica de coleta futura.
