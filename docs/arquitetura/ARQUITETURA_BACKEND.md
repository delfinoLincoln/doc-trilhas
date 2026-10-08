# Arquitetura do backend

O backend do Trilhas é uma API REST construída com Spring Boot. A aplicação segue uma arquitetura em camadas: as requisições HTTP entram pelos controllers, as regras de negócio ficam nos services e o acesso ao MySQL é feito pelos repositories do Spring Data JPA.

Dentro de cada camada, os pacotes são subdivididos pelos domínios da aplicação, como autenticação, usuários, trilhas, gamificação e notificações.

## Tecnologias principais

- Java 25 e Spring Boot 4.1.1;
- Spring Web MVC para a API REST;
- Spring Security com autenticação stateless por JWT;
- Spring Data JPA e Hibernate para persistência;
- MySQL como banco de dados;
- Flyway para versionamento do schema;
- Bean Validation para validação dos dados de entrada;
- Spring Mail para confirmação de e-mail;
- Springdoc OpenAPI e Swagger UI para documentação interativa;
- Maven para build e gerenciamento de dependências;
- JUnit e módulos de teste do Spring para testes automatizados.

As versões e dependências efetivamente utilizadas ficam declaradas em `trilhas-backend/pom.xml`.

## Fluxo de uma requisição

```text
Cliente Ionic/Angular
        │
        ▼
SecurityFilter ── valida o JWT e estabelece o usuário autenticado
        │
        ▼
Controller ────── recebe HTTP, valida a entrada e define a resposta
        │
        ▼
Service ───────── aplica regras de negócio e controla transações
        │
        ▼
Repository ────── consulta e persiste entidades com Spring Data JPA
        │
        ▼
MySQL
```

Os DTOs separam o contrato HTTP das entidades persistidas. Exceções lançadas pelas camadas são convertidas em respostas HTTP padronizadas pelo `GlobalExceptionHandler`.

## Estrutura do projeto

A árvore abaixo mostra os diretórios relevantes ao desenvolvimento. `target/` não faz parte da arquitetura: ele é gerado pelo Maven durante compilação e testes.

```text
trilhas-backend/
├── .mvn/wrapper/                      # Maven Wrapper
├── pom.xml                            # Dependências e configuração do build
├── mvnw
├── mvnw.cmd
└── src/
    ├── main/
    │   ├── java/com/ifpr/trilhas/
    │   │   ├── TrilhasApplication.java
    │   │   ├── config/
    │   │   │   ├── exceptions/       # Erros HTTP e autorização de recursos
    │   │   │   └── security/         # Spring Security e filtro JWT
    │   │   ├── controllers/
    │   │   │   ├── auth/             # Login, cadastro e confirmação de e-mail
    │   │   │   ├── gamifications/    # XP, conquistas e progresso
    │   │   │   ├── notifications/    # Avisos e estado de leitura
    │   │   │   ├── trails/           # Trilhas, módulos, conteúdos e materiais
    │   │   │   └── users/            # Usuários, estudantes e professores
    │   │   ├── dto/                   # Contratos de entrada e saída da API
    │   │   ├── models/                # Entidades JPA e enums
    │   │   ├── repository/            # Interfaces de persistência
    │   │   └── services/              # Regras de negócio e integrações
    │   └── resources/
    │       ├── db/migration/          # Migrations versionadas do Flyway
    │       ├── application.properties
    │       ├── application-dev.properties
    │       ├── application-test.properties
    │       └── application-prod.properties
    └── test/java/com/ifpr/trilhas/
        ├── controllers/               # Testes da camada HTTP
        └── services/                  # Testes unitários e de concorrência
```

## Responsabilidade das camadas

### Configuração

O pacote `config` concentra preocupações compartilhadas pela aplicação:

- `SecurityConfig` define as rotas públicas, a política stateless e a cadeia de filtros;
- `SecurityFilter` extrai o token Bearer, valida o JWT e preenche o contexto de segurança;
- `ResourceAuthorization` verifica se o usuário autenticado pode acessar ou alterar um recurso específico;
- `CorsConfig` libera as origens usadas pelo Ionic, Angular e Capacitor durante o desenvolvimento;
- `OpenApiConfig` configura a documentação da API e o esquema Bearer JWT;
- `MaterialStorageConfig` expõe os arquivos enviados em `/uploads/materials/**`;
- `DataSeeder`, ativo somente no perfil `test`, recria dados de demonstração ao iniciar a aplicação.

Os handlers de autenticação, acesso negado e exceções de negócio produzem respostas JSON consistentes para erros `400`, `401`, `403`, `404`, `409` e `500`.

### Controllers

Os controllers formam a camada HTTP. Eles definem os endpoints, validam DTOs de entrada, consultam o usuário autenticado quando necessário e delegam o processamento aos services.

Os principais grupos de rotas são:

| Prefixo | Responsabilidade |
| --- | --- |
| `/auth` | Cadastro, login local e confirmação de e-mail |
| `/users`, `/students`, `/teachers` | Cadastro e consulta dos perfis de usuário |
| `/trails`, `/modules`, `/contents`, `/materials` | Estrutura e materiais das trilhas de aprendizagem |
| `/progress` | Conclusão de conteúdos e progresso nas trilhas |
| `/gamification` | XP, progresso e conquistas dos estudantes |
| `/notifications` | Publicação, consulta e leitura de avisos |

O contrato detalhado dos endpoints é mantido pelas anotações OpenAPI do código e pode ser consultado pelo Swagger UI quando a aplicação está em execução.

### DTOs

O pacote `dto` contém records e classes usados nas entradas e saídas da API. Ele acompanha a divisão dos domínios e impede que o formato das entidades JPA determine diretamente o contrato HTTP.

As classes terminadas em `Request` representam dados recebidos. As terminadas em `Response` representam dados devolvidos ao cliente. `ExceptionResponse` padroniza o corpo das respostas de erro.

### Models

O pacote `models` contém as entidades persistidas e os enums do domínio. Os principais grupos são:

- `users`: usuário base, estudante e professor;
- `trails`: trilha, módulo, conteúdo e material;
- `gamifications`: XP semanal, conquistas e conquistas obtidas por estudantes;
- `gamifications/progress`: progresso por trilha e por conteúdo;
- `notifications`: notificações e registros de leitura;
- `token`: tokens de confirmação de e-mail;
- `enums`: tipos de usuário, conteúdo, material, notificação e conquista.

A hierarquia educacional principal é `Trail → Module → Content`. Professores são os responsáveis pela autoria de trilhas e materiais, enquanto o progresso e as conquistas são associados aos estudantes.

### Repositories

Os repositories são interfaces do Spring Data JPA. Eles encapsulam consultas e operações de persistência, mantendo SQL e detalhes do banco fora dos controllers.

Sua organização acompanha os models: usuários, trilhas, módulos, conteúdos, materiais, gamificação, progresso, notificações e tokens.

### Services

Os services concentram regras de negócio, composição de DTOs e limites transacionais. Eles também coordenam ações que envolvem mais de um repository, como concluir um conteúdo, recalcular o progresso da trilha e conceder XP.

Além dos serviços de domínio, esta camada possui integrações específicas:

- `auth/token`: geração e validação de JWT;
- `auth/email`: envio do link de confirmação de e-mail;
- `trails/materials/MaterialFileStorageService`: gravação e remoção de arquivos enviados.

## Domínios funcionais

### Autenticação e usuários

O sistema permite cadastro e login locais e confirmação de e-mail. `User` implementa `UserDetails`, permitindo que o Spring Security use os dados persistidos na autenticação.

Os perfis são definidos por `TypeUser`: `STUDENT`, `TEACHER` e `ADMIN`. Dados específicos de estudantes e professores ficam em entidades próprias, relacionadas ao usuário base.

### Trilhas de aprendizagem

Uma trilha pertence a um professor e contém módulos ordenados. Cada módulo contém conteúdos que podem representar guias, vídeos ou exercícios. Materiais complementares possuem fluxo próprio de criação, upload e revisão.

Operações de escrita verificam tanto o papel do usuário quanto a propriedade do recurso. Isso impede, por exemplo, que um professor altere a trilha pertencente a outro professor.

### Gamificação e progresso

A conclusão de conteúdos alimenta o progresso do estudante e a pontuação de XP. O domínio mantém:

- progresso individual por conteúdo;
- percentual e estado de conclusão por trilha;
- XP acumulado por semana;
- catálogo de conquistas;
- conquistas desbloqueadas por estudante.

As atualizações críticas são transacionais. Há um teste específico de concorrência para a conclusão de conteúdo, protegendo o sistema contra atribuição duplicada de progresso ou XP.

### Notificações

Professores e administradores podem publicar notificações gerais ou destinadas a uma turma. A leitura é registrada separadamente por estudante, sem alterar a notificação original.

## Segurança

A API não mantém sessão no servidor. Após o login, o cliente envia o JWT em cada requisição:

```http
Authorization: Bearer <token>
```

Somente login, cadastro, confirmação de e-mail, documentação OpenAPI e requisições CORS `OPTIONS` são públicas. As demais rotas exigem um JWT válido.

A autorização ocorre em dois níveis:

1. papel do usuário, com regras como `STUDENT`, `TEACHER` e `ADMIN`;
2. vínculo com o recurso, verificando propriedade, identidade do estudante ou turma.

As verificações específicas ficam declaradas com `@PreAuthorize` nos controllers e são apoiadas por `ResourceAuthorization`. Senhas locais são armazenadas com BCrypt. O segredo do JWT e as credenciais externas devem ser fornecidos por variáveis de ambiente, nunca versionados no repositório.

## Persistência e migrations

O banco relacional utilizado é MySQL. O Hibernate valida o mapeamento das entidades, enquanto o Flyway é responsável por criar e evoluir o schema nos ambientes `dev` e `prod`.

As migrations ficam em `src/main/resources/db/migration` e devem ser adicionadas de forma incremental. Uma migration já aplicada não deve ser editada; alterações posteriores devem receber um novo número de versão.

As migrations atuais criam, nesta ordem, usuários, estudantes, professores, trilhas, módulos, conteúdos, materiais, conquistas, XP, progresso, notificações, tokens de confirmação e registros de leitura.

Relacionamentos, constraints, índices e política de evolução estão detalhados em [Arquitetura do banco de dados](database/ARQUITETURA_BANCO_DE_DADOS.md).

## Perfis e configuração

O perfil ativo é selecionado por `SPRING_PROFILES_ACTIVE` e assume `dev` quando não informado.

| Perfil | Banco e schema | Dados iniciais |
| --- | --- | --- |
| `dev` | MySQL; Hibernate valida e Flyway migra | Nenhum seeder |
| `test` | MySQL de teste; Hibernate usa `create-drop`; Flyway desativado | `DataSeeder` recria dados de demonstração |
| `prod` | MySQL configurado por variáveis; Hibernate valida e Flyway migra | Nenhum seeder |

O `application.properties` importa opcionalmente um arquivo `.env` na raiz de execução. Entre as configurações externas usadas pela aplicação estão:

- banco: `DB_HOST`, `DB_PORT`, `DB_NAME_DEV`, `DB_USERNAME` e `DB_PASSWORD`;
- produção: `DB_URL_PROD`, `DB_USERNAME_PROD` e `DB_PASSWORD_PROD`;
- testes: `DB_HOST_TEST`, `DB_PORT_TEST`, `DB_NAME_TEST`, `DB_USERNAME_TEST` e `DB_PASSWORD_TEST`;
- segurança: `JWT_SECRET`;
- e-mail: `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME` e `MAIL_PASSWORD`;
- URLs: `APP_BASE_URL`, `FRONTEND_BASE_URL` e `FRONTEND_BASE_URL_PROD`;

Uploads de materiais são limitados a 20 MB e gravados, por padrão, em `uploads/materials`. Em produção, esse caminho deve apontar para um volume persistente.

## Testes

Os testes seguem a estrutura de pacotes do código principal. Atualmente há cobertura para controllers de autenticação e trilhas e para services de trilhas, notificações, gamificação e progresso.

Os testes de integração usam o perfil `test` e um banco MySQL exclusivo. Esse banco é recriado pelo Hibernate, portanto nunca deve compartilhar credenciais ou schema com desenvolvimento ou produção. Testes unitários isolados usam Mockito e não dependem do banco.

```powershell
cd trilhas-backend
mvn clean test
```

## Convenções para evolução

- Controllers devem permanecer finos e sem acesso direto a repositories.
- Regras de negócio e transações pertencem aos services.
- Entidades JPA não devem ser usadas como contratos públicos quando houver DTO correspondente.
- Novas funcionalidades devem seguir a subdivisão por domínio dentro das camadas existentes.
- Mudanças no banco exigem uma nova migration Flyway.
- Novas rotas precisam declarar validação, autorização e códigos HTTP adequados.
- Segredos e credenciais devem ser recebidos por configuração externa.
- `target/`, uploads locais e arquivos `.env` não devem fazer parte da documentação estrutural nem ser versionados.
