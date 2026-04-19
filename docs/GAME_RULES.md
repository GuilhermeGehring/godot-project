# Regras do Game

Stats e comportamentos oficiais. Fonte da verdade — se o código divergir, **atualiza isso aqui** na mesma mudança.

## Controles

| Ação               | Input                                                   |
|--------------------|---------------------------------------------------------|
| Andar esquerda     | `A` ou seta esquerda                                    |
| Andar direita      | `D` ou seta direita                                     |
| Pular              | `Espaço`                                                |
| Spray              | Click esquerdo do mouse (segura)                        |
| Recarregar spray   | Clique direito + chacoalhar mouse na vertical           |
| Reiniciar (após game over) | `Espaço`                                        |

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

| Stat                     | Valor                               |
|--------------------------|-------------------------------------|
| Carga máxima             | 100                                 |
| Dreno enquanto atira     | 40 unidades/s                       |
| Recarga                  | **somente via shake** (ver abaixo)  |
| Cadência                 | 25 tiros/s (intervalo 0.04 s)       |
| Ângulo do cone (spread)  | ±0.30 rad (~±17°)                   |
| Velocidade da bullet     | 750 px/s                            |
| Lifetime da bullet       | 0.35 s (alcance ~260 px)            |
| Dano por bullet          | 1                                   |

Detalhes:
- Mira pela posição do mouse no mundo (`get_global_mouse_position()`).
- Bullet morre no primeiro contato (inimigo ou parede).
- Quando a carga zera, o spray para de atirar mesmo se o botão continuar pressionado. Só volta depois de recarregar.

### Recarga (shake mechanic)

O spray **não recarrega passivamente**. Acabou a tinta, sem tiro até chacoalhar.

| Parâmetro                         | Valor            |
|-----------------------------------|------------------|
| Ganho por inversão de direção     | 4 unidades       |
| Delta vertical mínimo pra contar  | 5 px             |

Como funciona:
- Segura o **clique direito** e move o mouse pra **cima e pra baixo** (vertical).
- Cada vez que a direção vertical do mouse **inverte** (ex: estava subindo, agora desce), ganha 4 unidades de carga.
- Movimentos com `|Δy| < 5 px` são ignorados (filtra jitter da mesa).
- Soltar o clique direito **reseta o detector** de direção — a próxima primeira movimentação não dá unidade de graça.
- Atirar e recarregar ao mesmo tempo é permitido, mas o dreno (40/s) passa fácil um shake casual; o jogador precisa chacoalhar rápido pra manter tinta enquanto atira.

Feel esperado:
- Shake vigoroso (~8–10 flips/s) → ~32–40 unidades/s → recarga completa em ~2.5–3 s.
- Shake casual (~2–3 flips/s) → ~8–12 unidades/s → recarga completa em ~8–12 s.

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

Player spawna em `(-280, 500)` (cai sobre F1Left). Mapa tem **parede direita** em x=530.

O padrão de 3 tipos repete a cada 3 andares (120 px de espaçamento superfície-a-superfície):

```
wide   → ----- -----   (2 blocos 450 px, buraco ~110 px no centro)
medium →  ---   ---    (2 blocos 220 px, buraco ~160 px no centro)
short  → -- -- -- --   (4 blocos 130 px distribuídos)
```

### 8 Andares

| Andar | Tipo   | Nó(s)              | y nó  | Superfície y |
|-------|--------|--------------------|-------|--------------|
| 1     | wide   | F1Left / F1Right   | 600   | 550          |
| 2     | medium | F2Left / F2Right   | 440   | 430          |
| 3     | short  | F3P1–F3P4          | 320   | 310          |
| 4     | wide   | F4Left / F4Right   | 200   | 190          |
| 5     | medium | F5Left / F5Right   | 80    | 70           |
| 6     | short  | F6P1–F6P4          | -40   | -50          |
| 7     | wide   | F7Left / F7Right   | -160  | -170         |
| 8     | medium | F8Left / F8Right   | -280  | -290         |

Posições dos nós wide: centros em x=±280 (cada 450×100).
Posições dos nós medium: centros em x=±190 (cada 220×20).
Posições dos nós short: centros em x=−320, −100, 100, 320 (cada 130×20).

### Parede direita

`StaticBody2D` em x=530, tamanho 40×1200, cobre todo o mapa verticalmente. Bloqueia o player de sair pela direita.

### Finish Zone (saída)

`Area2D` em `(530, -300)`, shape `80×100`. Está embutida na parede direita ao nível do andar 8. Quando o player pula de F8Right (borda direita x=300) até a parede e entra na zona:
- Spawner para.
- Overlay "LEVEL COMPLETE! / Press SPACE to restart" aparece.

Visual: retângulo dourado (`Color(1, 0.85, 0.1, 0.6)`, 40×100 px) na parede.

## UI

- **Health bar**: canto superior esquerdo, (20, 20) a (220, 40), 200×20 px. Cor fill `Color(0.9, 0.15, 0.15)`. Fundo `Color(0.2, 0.02, 0.02)`.
- **Spray bar**: logo abaixo, (20, 48) a (220, 68). Fill amarelo `Color(1, 0.85, 0.2)` (mesmo tom da bullet).
- **Game over overlay**: ocupa tela inteira, preto translúcido, label centralizado "GAME OVER / Press SPACE to restart", fonte 48pt.
- **Background**: `CanvasLayer` fixa, cor `Color(0.08, 0.1, 0.15)` (azul-escuro).

## Legado (não ativo)

- `entities/coin/`: scene da moeda + script. Era do protótipo top-down anterior; ficou após o pivot pra plataformer. Pode ser removido ou reaproveitado pra uma mecânica de coleta futura.
