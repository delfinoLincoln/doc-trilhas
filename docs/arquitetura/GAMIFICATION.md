# Gamificação e progresso

Este documento descreve o comportamento implementado de XP, níveis, progresso semanal e conquistas no Trilhas. Ele deve ser atualizado junto com `GamificationService`, `ContentProgressService`, `TrailProgressService` e as respectivas migrations e classes de teste.

## Visão geral

```text
Conclusão inédita de conteúdo
          │
          ├── concede 50 XP
          ├── atualiza o total e o nível do estudante
          ├── acumula XP na semana ISO atual
          ├── verifica conquistas por XP acumulado
          └── recalcula o progresso da trilha
                            │
                            └── ao chegar a 100%, concede 500 XP uma única vez
```

O sistema mantém três visões relacionadas:

- `students.xp` e `students.level`: estado acumulado atual;
- `xp_weekly`: XP recebido por semana;
- `student_achievements`: conquistas desbloqueadas pelo estudante.

## Regras de XP

| Evento | Recompensa atual | Condição |
| --- | ---: | --- |
| Concluir um conteúdo | 50 XP | Somente na primeira conclusão do par estudante–conteúdo |
| Concluir uma trilha | 500 XP | Quando todos os conteúdos da trilha estão concluídos e ela ainda não estava finalizada |
| Desbloquear uma conquista | Definida em `achievements.xp_reward` | Quando uma conquista implementada alcança seu critério |
| Concluir um módulo | 0 XP | Não existe recompensa de módulo implementada |

As recompensas de conteúdo e trilha são constantes nos services. Os campos `modules.xp_reward` e `trails.xp_reward` existem no modelo, mas não determinam os valores concedidos atualmente.

Não existe operação para desfazer uma conclusão. Repetir a chamada de conclusão em um conteúdo já concluído devolve o estado existente e não concede XP novamente.

`GamificationService.addXp` aceita apenas valores positivos. Toda concessão atualiza, na mesma transação:

1. o XP total do estudante;
2. o nível derivado desse total;
3. o acumulado da semana ISO corrente;
4. as conquistas elegíveis por XP acumulado.

XP recebido como recompensa de conquista também participa do total, do nível e do histórico semanal, podendo liberar outra conquista de XP.

## Níveis

A progressão é quadrática. O XP total mínimo para alcançar um nível é:

```text
XP mínimo = 250 × (nível − 1)²
```

O nível correspondente ao XP acumulado é:

```text
Nível = 1 + piso(√(XP total ÷ 250))
```

| Nível | XP total mínimo | XP desde o nível anterior |
| ---: | ---: | ---: |
| 1 | 0 | 0 |
| 2 | 250 | 250 |
| 3 | 1.000 | 750 |
| 4 | 2.250 | 1.250 |
| 5 | 4.000 | 1.750 |
| 6 | 6.250 | 2.250 |

Exemplo: com 1.150 XP, o estudante está no nível 3. O nível 4 começa em 2.250 XP, portanto faltam 1.100 XP.

A API devolve:

- `level`: nível atual;
- `xpTotal`: XP acumulado;
- `xpNextLevel`: total necessário para alcançar o próximo nível;
- `xpToNextLevel`: diferença restante, nunca menor que zero.

## Progresso de conteúdo e trilha

Cada par estudante–conteúdo possui no máximo um registro em `content_progress`. A primeira conclusão grava `completed=true` e `completed_at`; chamadas posteriores são idempotentes.

Após uma conclusão inédita, o progresso da trilha é calculado por:

```text
percentual = piso((conteúdos concluídos ÷ conteúdos totais) × 100)
```

O cálculo considera todos os conteúdos de todos os módulos da trilha. Uma trilha sem conteúdos permanece sem percentual calculável e não concede recompensa.

Quando o percentual chega a 100% pela primeira vez:

- `trail_progress.completed` passa para `true`;
- a última atividade é atualizada;
- o estudante recebe 500 XP.

A constraint única `(student_id, trail_id)` impede mais de um progresso para o mesmo estudante e trilha. O estado concluído impede que recálculos posteriores concedam novamente os 500 XP.

### Exemplo completo

Considere uma trilha com quatro conteúdos e um estudante começando com 0 XP:

| Momento | XP do evento | XP total | Nível | Progresso da trilha |
| --- | ---: | ---: | ---: | ---: |
| Primeiro conteúdo | 50 | 50 | 1 | 25% |
| Segundo conteúdo | 50 | 100 | 1 | 50% |
| Terceiro conteúdo | 50 | 150 | 1 | 75% |
| Quarto conteúdo | 50 | 200 | 1 | 100% |
| Recompensa pela trilha | 500 | 700 | 2 | Concluída |

O exemplo desconsidera recompensas de conquistas. Se alguma conquista por XP for desbloqueada durante o fluxo, seu `xp_reward` também será somado.

## Histórico semanal

`xp_weekly` agrega o XP recebido por estudante, semana ISO e ano baseado em semana. A semana começa na segunda-feira.

A combinação `(student_id, number_week, year)` é única. Ao consultar os detalhes de gamificação, a API monta as últimas seis semanas, incluindo semanas sem atividade com valor zero. A semana atual recebe o rótulo `Atual`; as anteriores usam `Sem -1` até `Sem -5`.

O histórico é um agregado, não um extrato de eventos. Ele informa quanto XP foi recebido em cada semana, mas não registra qual ação originou cada parcela.

## Conquistas

O catálogo global fica em `achievements`. O vínculo `student_achievements` registra cada conquista liberada e o momento do desbloqueio. A combinação `(student_id, achievement_id)` é única.

### Tipos modelados

| Tipo | Critério pretendido | Situação atual |
| --- | --- | --- |
| `ACCUMULATED_XP` | Alcançar `standard_value` de XP total | Implementado |
| `FIRST_TRACK` | Concluir a primeira trilha | Modelado, ainda não avaliado |
| `COMPLETED_TRACKS` | Concluir determinada quantidade de trilhas | Modelado, ainda não avaliado |
| `TOP_RANKING` | Atingir posição de destaque no ranking | Modelado, ainda não avaliado |
| `SUBMITTED_MATERIALS` | Enviar determinada quantidade de materiais | Modelado, ainda não avaliado |
| `DAY_STREAK` | Manter uma sequência de dias | Modelado, ainda não avaliado |

Atualmente, `checkAchievements` desbloqueia somente conquistas `ACCUMULATED_XP` quando:

```text
students.xp >= achievements.standard_value
```

No desbloqueio:

1. é criado um `student_achievements` com `achieved_at`;
2. `students.badges_count` é incrementado;
3. `achievements.xp_reward`, quando positivo, é concedido ao estudante.

A API combina o catálogo completo com as conquistas do estudante e informa, para cada item, `unlocked` e `unlockedAt`.

## Concorrência e proteção contra duplicidade

As operações críticas são transacionais. Antes de conceder XP, o estudante é consultado com bloqueio pessimista de escrita por `StudentRepository.findByIdForUpdate`. A entidade `Student` também possui a coluna `version` para bloqueio otimista.

O banco reforça a idempotência com constraints únicas:

- `content_progress(student_id, content_id)`;
- `trail_progress(student_id, trail_id)`;
- `student_achievements(student_id, achievement_id)`;
- `xp_weekly(student_id, number_week, year)`.

Há um teste de concorrência específico que dispara duas conclusões simultâneas do mesmo conteúdo e verifica que apenas 50 XP sejam concedidos.

## API e autorização

| Método | Rota | Resultado |
| --- | --- | --- |
| `POST` | `/progress/students/{studentId}/contents/{contentId}/complete` | Marca a primeira conclusão e inicia o fluxo de XP e progresso |
| `GET` | `/progress/students/{studentId}/trails/{trailId}` | Consulta ou inicializa o progresso da trilha |
| `GET` | `/gamification/students/{studentId}` | Retorna nível, XP, seis semanas e conquistas |

As três rotas exigem JWT e validam que o estudante autenticado seja o proprietário do `studentId` informado.

## Limitações conhecidas

- Recompensas de conteúdo e trilha estão fixas em 50 e 500 XP nos services.
- Os campos `xp_reward` de módulo e trilha ainda não alimentam a concessão de XP.
- Não existe recompensa específica pela conclusão de um módulo.
- Apenas conquistas do tipo `ACCUMULATED_XP` são avaliadas.
- Não existe operação de estorno, correção ou extrato detalhado de XP.
- `xp`, `level`, `badges_count` e os totais semanais são agregados persistidos e precisam permanecer sincronizados.
- O cálculo semanal usa o relógio e a data local do servidor diretamente.

## Regras para evolução

- Novas fontes de XP devem passar por `GamificationService.addXp`.
- Uma nova conquista só deve ser anunciada como disponível depois que seu critério estiver implementado e testado.
- Alterações na curva de níveis exigem estratégia para recalcular estudantes existentes.
- Mudanças de recompensa devem atualizar services, testes e este documento na mesma entrega.
- Novas constraints ou estruturas de histórico exigem uma migration Flyway incremental.
- Operações concorrentes devem preservar idempotência e bloqueio por estudante.

O detalhamento das tabelas está em [Arquitetura do banco de dados](database/ARQUITETURA_BANCO_DE_DADOS.md).
