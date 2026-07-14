# mri_Qobjects — Manual

Spawner de objetos sincronizados: admins colocam props no mundo com preview e gizmo, organizados em projetos (cenas), e tudo é persistido no banco e replicado para todos os jogadores.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Configuração](#configuração)
5. [Comandos](#comandos)
6. [Fluxo de uso](#fluxo-de-uso)
7. [Controles do preview](#controles-do-preview)
8. [Banco de dados](#banco-de-dados)
9. [Renderização e streaming](#renderização-e-streaming)
10. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
11. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Menus de contexto, `inputDialog`, `showTextUI`, callbacks, `lib.raycast.cam`, `lib.addCommand` |
| `oxmysql` | Sim | Persistência dos objetos e das cenas |
| `qbx_core` | Sim | O client escuta `QBCore:Client:OnPlayerLoaded` e `QBCore:Client:OnPlayerUnload` para carregar e limpar os objetos |
| `fivem-freecam` | Sim | Ativado ao editar um objeto já colocado (`exports['fivem-freecam']:SetActive`) |
| `object_gizmo` | Sim | Gizmo de translação/rotação na edição (`exports.object_gizmo:useGizmo`) |

Sem `fivem-freecam` e `object_gizmo` o spawner ainda coloca objetos novos, mas a opção "Editar" de um objeto já colocado quebra.

---

## Instalação

1. Copie a pasta `mri_Qobjects` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qobjects
   ```
3. As tabelas são criadas automaticamente no `onResourceStart` (`CREATE TABLE IF NOT EXISTS`). O arquivo `sql.sql` contém o mesmo schema, caso prefira importar manualmente.
4. Garanta que `fivem-freecam` e `object_gizmo` estejam iniciados **antes** deste recurso.

---

## Permissões (ACE)

Todas as operações — abrir o menu, criar, editar, duplicar e excluir — são protegidas.

```
add_ace group.admin admin allow
add_ace group.admin command.objectspawner allow
add_ace group.admin command.objectdelete allow
```

Há duas camadas de checagem:

- Os comandos são registrados com `restricted = 'group.admin'` (`lib.addCommand`), o que exige a ACE `command.<comando>` para o grupo.
- Todos os eventos e callbacks do servidor passam por `isPlayerNotAuthorized`, que valida `IsPlayerAceAllowed(src, 'admin')`. Quem não tem a ACE recebe uma notificação de erro e a ação é abortada.

O único callback sem gate é `objects:getAllObjects` — ele é chamado por todo jogador ao logar para receber a lista de objetos a renderizar.

---

## Configuração

Arquivo `shared/config.lua`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Config.imgSrv` | string | Sim | URL base das miniaturas dos props exibidas no menu. O menu monta a imagem como `Config.imgSrv .. <model> .. '.webp'`. Padrão: `https://mri-qbox-brasil.github.io/mri-assets/assets/` |
| `Config.Debug` | bool | Não | Presente no config, mas não é lido por nenhum arquivo Lua na versão atual. O modo debug real (exibir IDs dos objetos) é ligado pelo próprio menu |

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/objectspawner` | `group.admin` | Abre o menu de projetos (tela inicial do spawner) |
| `/objectdelete <id>` | `group.admin` | Remove o objeto com o ID informado do banco e do mundo de todos os jogadores |

O ID usado no `/objectdelete` é o mesmo exibido no menu (entre colchetes) e no modo debug.

---

## Fluxo de uso

O spawner organiza os objetos em **projetos** (cenas). Um objeto sempre pertence a um projeto.

1. `/objectspawner` abre o menu **Projetos**, listando todos os projetos com a contagem de objetos de cada um.
2. **Criar um novo projeto** — pede um nome e cria a cena.
3. Abrir um projeto lista seus objetos, cada um com ID, modelo, coordenadas e miniatura.
4. **Adicionar objeto** — pede o nome do modelo (spawn name do GTA V). Se o modelo não existir no CD image, o menu avisa e pede de novo. Em seguida entra no modo preview.
5. Ao confirmar a colocação, o objeto é gravado no banco, replicado para todos os clientes e o menu de edição daquele objeto abre.

### Ações sobre um objeto

| Ação | Efeito |
|---|---|
| Editar | Ativa a freecam e o gizmo para reposicionar/rotacionar. Ao sair do gizmo, a nova posição é salva e propagada |
| Duplicar | Entra em modo preview com o mesmo modelo, no mesmo projeto |
| Excluir | Remove do banco e do mundo de todos os jogadores |
| Teleportar | Move o admin até as coordenadas do objeto |

### Ações sobre um projeto

| Ação | Efeito |
|---|---|
| Renomear | Altera o nome da cena |
| Excluir projeto | Só fica habilitado quando o projeto está vazio — exclua todos os objetos antes |

### Modo debug

O item "Ativar Debug" no menu de projetos desenha, num raio de 10 metros, o ID de cada objeto em texto 3D e aplica um contorno azul na entidade. É um toggle e não depende de nenhuma config.

---

## Controles do preview

Ao adicionar ou duplicar um objeto, o prop segue a mira via raycast e é assentado no chão automaticamente (`PlaceObjectOnGroundProperly`).

| Tecla | Ação |
|---|---|
| `E` | Colocar o objeto (grava no banco) |
| `G` | Girar 90 graus |
| `Seta esquerda` / `Seta direita` | Girar continuamente para a esquerda / direita |
| `Q` | Cancelar |

Durante o preview, o objeto fica semitransparente, sem colisão e congelado.

---

## Banco de dados

Duas tabelas, criadas automaticamente na inicialização.

```sql
CREATE TABLE `synced_objects_scenes` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    PRIMARY KEY (`id`) USING BTREE
);

CREATE TABLE `synced_objects` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `model` varchar(50) NOT NULL,
    `x` varchar(50) NOT NULL,
    `y` varchar(50) NOT NULL,
    `z` varchar(50) NOT NULL,
    `rx` varchar(50) NOT NULL,
    `ry` varchar(50) NOT NULL,
    `rz` varchar(50) NOT NULL,
    `heading` int(11) NOT NULL,
    `sceneid` int(11) NOT NULL,
    PRIMARY KEY (`id`) USING BTREE,
    CONSTRAINT `FK_objects_scene` FOREIGN KEY (`sceneid`)
        REFERENCES `synced_objects_scenes` (`id`) ON UPDATE CASCADE ON DELETE CASCADE
);
```

A foreign key tem `ON DELETE CASCADE`: apagar uma cena apaga seus objetos no banco. Mesmo assim, o menu bloqueia a exclusão de projetos que ainda tenham objetos, para não deixar props órfãos renderizados no mundo até o próximo restart.

---

## Renderização e streaming

Os objetos não são entidades de rede — cada cliente cria a sua própria cópia local.

- No start do recurso, o servidor carrega todos os `synced_objects` para a tabela global `ServerObjects` e envia para os clientes.
- Ao logar, cada jogador puxa a lista via callback `objects:getAllObjects`.
- Um loop no client roda a cada 1200 ms: objetos a menos de 300 metros do jogador são criados (`CreateObjectNoOffset`, congelados e não dinâmicos); os que ficam além disso são deletados. Isso mantém a contagem de entidades baixa em mapas grandes.
- Ao parar o recurso ou ao deslogar o personagem, todas as entidades criadas são removidas.

Alterações feitas pelo menu (criar, mover, excluir) são transmitidas em broadcast (`-1`) e aparecem para todos os jogadores conectados imediatamente, sem restart.

---

## Entrypoints para outros recursos

O recurso não expõe exports. A superfície pública são eventos de rede — todos com gate de ACE `admin` no servidor, exceto onde indicado.

### Abrir o menu para um jogador

```lua
TriggerClientEvent('objects:client:menu', source)
```

O handler no client rejeita chamadas vindas de outro recurso local (`GetInvokingResource`), então o menu só pode ser aberto pelo servidor.

### Criar um objeto

```lua
-- callback: retorna o ID do objeto criado
local insertId = lib.callback.await('objects:server:newObject', 2000, {
    model = 'prop_barrier_work05',
    x = '0.000', y = '0.000', z = '0.000',
    rx = '0.000', ry = '0.000', rz = '0.000',
    heading = 0.0,
    sceneid = 1,
})

-- ou como evento, sem retorno
TriggerServerEvent('objects:server:newObject', data)
```

### Demais eventos de servidor

```lua
TriggerServerEvent('objects:server:updateObject', { insertId = 1, model = 'prop_x', x = '0', y = '0', z = '0', rx = '0', ry = '0', rz = '0' })
TriggerServerEvent('objects:server:removeObject', insertId)
TriggerServerEvent('objects:server:updateSceneName', sceneId, 'Novo nome')
TriggerServerEvent('objects:server:removeScene', sceneId)
```

### Callbacks de leitura

```lua
-- lista de todos os objetos (sem gate de ACE — usado no login de qualquer jogador)
local objects = lib.callback.await('objects:getAllObjects', false)

-- lista de cenas com contagem de objetos (requer ACE admin)
local scenes = lib.callback.await('objects:getAllScenes', 100)

-- cria uma cena e retorna true/false (requer ACE admin)
local ok = lib.callback.await('objects:newScene', 100, 'Nome do projeto')
```

---

## Estrutura de arquivos

```
mri_Qobjects/
├── client/
│   ├── main.lua       — eventos de entrada do client (abrir menu, remover objeto, menu de edição)
│   ├── menus.lua      — menus ox_lib de projetos e objetos, modo debug com IDs em texto 3D
│   └── object.lua     — preview com raycast, gizmo/freecam, spawn local e loop de streaming (300 m)
├── server/
│   ├── main.lua       — eventos e callbacks de rede, gate de ACE (isPlayerAuthorized)
│   ├── objects.lua    — regras de CRUD, broadcast para os clientes, criação das tabelas no boot
│   ├── db.lua         — queries oxmysql (synced_objects e synced_objects_scenes)
│   └── commands.lua   — /objectspawner e /objectdelete
├── shared/
│   └── config.lua     — Config.imgSrv e Config.Debug
├── sql.sql            — schema das tabelas (referência; são criadas automaticamente)
└── fxmanifest.lua
```
