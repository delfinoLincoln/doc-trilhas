# Arquitetura do frontend

O frontend do Trilhas é uma aplicação Ionic com Angular standalone. Sua organização é **feature-first**: páginas, modelos e acesso a dados que mudam juntos ficam agrupados pelo domínio funcional, e não pelo perfil do usuário ou pelo tipo técnico do arquivo.

`core`, `shared` e `layouts` formam a estrutura transversal da aplicação. Os domínios de negócio ficam em `features`.

## Tecnologias principais

- Angular 21 com componentes standalone;
- Ionic 8 para componentes e navegação mobile;
- Capacitor 8 para a aplicação Android;
- Angular Router com carregamento lazy das páginas;
- Angular HttpClient e interceptors funcionais;
- RxJS para composição de operações assíncronas;
- TypeScript em modo estrito.

As versões efetivamente utilizadas ficam em `trilhas-frontend/package.json`.

## Estrutura

```text
trilhas-frontend/src/app/
├── app.component.ts
├── app.routes.ts                       # Composição das rotas públicas e protegidas
├── core/                               # Infraestrutura global e serviços singleton
│   ├── api/                            # Cliente HTTP e URL da API
│   ├── auth/                           # Guards e interceptor JWT
│   ├── feedback/                       # Feedback e confirmação globais
│   ├── session/                        # Estado da sessão autenticada
│   └── theme/                          # Tema claro/escuro
├── shared/
│   └── components/                     # Componentes visuais sem regra de domínio
│       ├── action-feedback/
│       └── app-header/
├── layouts/                            # Shells de navegação por perfil
│   ├── student-tabs/
│   │   ├── student-tabs.page.*
│   │   └── student.routes.ts
│   └── teacher-tabs/
│       ├── teacher-tabs.page.ts
│       └── teacher.routes.ts
└── features/                           # Funcionalidades organizadas por domínio
    ├── auth/
    │   ├── data-access/
    │   └── pages/
    ├── gamification/
    │   ├── data-access/
    │   └── pages/
    ├── home/
    │   └── pages/
    ├── materials/
    │   ├── data-access/
    │   └── pages/
    ├── notifications/
    │   ├── data-access/
    │   └── pages/
    ├── trails/
    │   ├── data-access/
    │   └── pages/
    └── users/
        ├── data-access/
        └── pages/
```

Pastas `student` e `teacher` podem existir dentro de uma feature quando o mesmo domínio possui experiências diferentes para cada perfil. Elas não são o primeiro nível de organização.

## Fluxo da aplicação

```text
Página da feature
      │
      ▼
Serviço em data-access
      │
      ▼
ApiService em core/api
      │
      ▼
authInterceptor ── adiciona o JWT e trata respostas 401
      │
      ▼
API Spring Boot
```

O estado do usuário autenticado fica em `core/session`. Páginas consomem esse estado e os serviços de seu domínio, sem realizar chamadas HTTP diretamente.

## Responsabilidades

### Core

`core` contém infraestrutura carregada uma única vez e independente das telas:

- `api`: resolve a URL do backend e encapsula o `HttpClient`;
- `auth`: protege rotas e anexa o token JWT às requisições;
- `session`: mantém token, usuário e papel da sessão atual;
- `feedback`: oferece notificações de ação e diálogos de confirmação;
- `theme`: controla e persiste o tema visual.

Serviços específicos de trilhas, materiais, usuários ou outros domínios não pertencem a `core`.

### Shared

`shared` contém componentes visuais reutilizáveis e sem conhecimento de uma feature específica. Um componente compartilhado pode depender de infraestrutura de `core`, mas não deve importar páginas ou serviços de domínio.

### Layouts

Os layouts definem os shells de navegação e as abas disponíveis para cada perfil:

- `student-tabs` compõe as rotas do aluno;
- `teacher-tabs` compõe as rotas do professor.

Layouts podem carregar páginas das features, mas não concentram regras de negócio.

### Features

Cada feature representa um domínio funcional. Quando necessário, ela é subdividida em:

- `pages`: componentes associados a rotas;
- `data-access`: serviços HTTP, contratos e estado específico do domínio;
- `components`: componentes usados somente dentro daquela feature, quando existirem.

As features atuais são:

| Feature | Responsabilidade |
| --- | --- |
| `auth` | Login, cadastro, confirmação de e-mail e preparação da sessão |
| `home` | Painéis iniciais de aluno e professor |
| `trails` | Consulta, criação e edição de trilhas, módulos e conteúdos |
| `materials` | Catálogo, envio e revisão de materiais |
| `gamification` | XP, progresso e conquistas |
| `notifications` | Avisos e registros de leitura |
| `users` | Perfil do aluno e consulta de estudantes e professores |

## Rotas e perfis

`app.routes.ts` é o ponto de composição da navegação. Ele mantém as rotas públicas de autenticação, aplica os guards e carrega os dois layouts protegidos.

As rotas filhas pertencem aos layouts porque representam a navegação disponível para cada perfil, mas cada rota carrega sua página diretamente da feature correspondente.

```text
app.routes.ts
├── rotas públicas → features/auth
├── student layout → student.routes.ts → páginas das features
└── teacher layout → teacher.routes.ts → páginas das features
```

As URLs existentes foram preservadas:

- aluno: `/inicio`, `/trilhas`, `/xp`, `/materiais` e `/perfil`;
- professor: `/professor/inicio`, `/professor/trilhas`, `/professor/alunos`, `/professor/materiais` e `/professor/avisos`;
- detalhe de trilha do professor: `/professor/trilhas/:id`;
- os atalhos `/alunos` e `/avisos` redirecionam para a área do professor.

Todas as páginas são carregadas de forma lazy com `loadComponent`.

## Segurança e sessão

`authGuard` exige uma sessão válida. `roleGuard` limita cada layout aos papéis esperados: estudantes acessam o layout do aluno; professores e administradores acessam o layout do professor.

`authInterceptor` envia o JWT nas chamadas protegidas e encerra a sessão quando a API responde que a autenticação não é mais válida. A autorização definitiva continua sendo responsabilidade do backend; os guards do frontend controlam apenas a experiência de navegação.

## Execução web e Android

O mesmo código Angular atende ao navegador e ao aplicativo Android empacotado pelo Capacitor. `capacitor.config.ts` define o identificador do aplicativo, seu nome e o diretório `www` usado como origem dos arquivos web compilados.

A URL da API é resolvida por `core/api/api.config.ts`:

- no navegador, utiliza o host atual do frontend e a porta `8080`;
- quando o servidor Angular usa `0.0.0.0`, o cliente troca esse endereço por `localhost`;
- no Android, utiliza `http://localhost:8080`, considerando o encaminhamento `adb reverse tcp:8080 tcp:8080` durante o desenvolvimento por USB.

Esse comportamento pertence à infraestrutura de `core/api`. Páginas e services de domínio não devem montar URLs de ambiente diretamente.

## Dívida técnica conhecida

A tela de login e o `AuthService` ainda contêm um fluxo legado de autenticação via SUAP que chama `/auth/suap/login`. O backend não oferece mais esse endpoint. Esse fluxo não faz parte da arquitetura suportada e deve ser removido do frontend antes da entrega.

## Aliases de importação

O `tsconfig.json` define aliases para reduzir caminhos relativos frágeis:

| Alias | Destino |
| --- | --- |
| `@app/*` | `src/app/*` |
| `@core/*` | `src/app/core/*` |
| `@features/*` | `src/app/features/*` |
| `@layouts/*` | `src/app/layouts/*` |
| `@shared/*` | `src/app/shared/*` |

Imports relativos continuam adequados entre arquivos muito próximos, como um componente e seu template. Para dependências entre áreas da arquitetura, os aliases tornam o limite explícito.

## Regras para evolução

- Uma nova funcionalidade deve começar em `features/<domínio>`.
- Páginas não devem acessar o `HttpClient` diretamente.
- Serviços de domínio devem ficar no `data-access` da própria feature.
- `core` não deve importar uma feature.
- `shared` não deve conter regras de negócio nem depender de features.
- Layouts organizam navegação, não dados ou regras de negócio.
- Código usado por apenas uma feature deve permanecer dentro dela.
- Uma abstração só deve ir para `shared` quando for realmente reutilizada por mais de uma feature.
- Rotas devem continuar lazy e protegidas no nível apropriado.
- Mudanças estruturais devem manter esta documentação e os aliases atualizados.
