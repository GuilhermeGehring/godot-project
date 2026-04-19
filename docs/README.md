# docs/

Documentação viva do projeto, pro time.

## Arquivos

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — arquitetura técnica: estrutura de pastas, camadas de colisão, fluxos de sinal, hierarquias de classe, performance.
- **[GAME_RULES.md](GAME_RULES.md)** — design e regras de gameplay: stats de player/inimigos, mecânicas, controles, layout do nível.
- **[SESSION_LOG.md](SESSION_LOG.md)** — log cronológico de decisões tomadas em cada sessão de desenvolvimento (inclusive as feitas junto com a IA).

## Política de atualização

Qualquer decisão arquitetural ou de gameplay deve ser refletida aqui **no mesmo commit** que a mudança no código. Os arquivos registram o *porquê* das decisões — o código já mostra o *como*.

A IA (Claude Code) foi instruída via `CLAUDE.md` na raiz do projeto a:
- atualizar `ARCHITECTURE.md` quando mexer em estrutura, layers, sinais ou hierarquias
- atualizar `GAME_RULES.md` quando mudar stats, mecânicas, controles ou layout
- acrescentar uma entrada em `SESSION_LOG.md` ao fim de cada sessão não-trivial

Se estiver mexendo manualmente (sem IA), siga o mesmo padrão.

## Escopo

Estes docs são o contrato entre o time. Não substituem:
- **README.md da raiz** — se existir, cobre setup e como rodar
- **CLAUDE.md** — instruções exclusivas pra IA; não tem regra de gameplay nem arquitetura, só como colaborar
- **`.claude/skills/godot-senior-dev/SKILL.md`** — boas práticas gerais de Godot 4 que valem pra qualquer projeto; não é específico deste game
