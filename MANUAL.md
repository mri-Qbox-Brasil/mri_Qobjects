# MANUAL - mri_Qobjects

## O que o recurso faz
Spawner de objetos para servidores FiveM baseados em MRI Qbox, permitindo criar, gerenciar e persistir objetos no mundo do jogo com posicionamento preciso via raycast e sincronização automática para todos os jogadores.

## Funcionalidades principais
- Spawn de qualquer modelo de objeto no mundo do jogo
- Persistência de objetos em banco de dados para manter após reinicialização
- Gerenciamento administrativo via menu para criar, editar e remover objetos
- Posicionamento preciso via raycast (mira do jogador)
- Sincronização automática de objetos para todos os jogadores conectados

## Como funciona (fluxo de trabalho)
1. Administradores abrem o menu de object spawner via comando `/objectspawner`
2. O jogador usa raycast para posicionar o objeto no local desejado
3. O objeto é spawnado localmente e salvo no banco de dados via server
4. O server sincroniza a lista de objetos com todos os clients, que spawnam os objetos localmente
5. Edição ou remoção de objetos atualiza o banco de dados e sincroniza as alterações

## Opções de configuração disponíveis
Configurações em `shared/`:
| Opção | Descrição |
|-------|-----------|
| Permissões | ACE permissions para acesso administrativo ao menu |
| Debug | Habilita mensagens de debug no console |

## Comandos disponíveis
| Comando | Descrição | Permissão |
|---------|-----------|-----------|
| `/objectspawner` | Abre o menu de gerenciamento de objetos | Admin |

## Eventos que dispara/ouve
Eventos de sincronização para spawn, atualização e remoção de objetos entre server e clients

## Exports que fornece/consome
Nenhum export documentado (gerenciamento via eventos e banco de dados)

## Integração com outros recursos MRI Qbox
- `ox_lib`: Utilizado para menus, notificações e raycast
- `oxmysql`: Persistência de objetos em banco de dados

## Casos de uso / exemplos práticos
- Spawnar caixas de loot em pontos estratégicos da cidade
- Criar barreiras de trânsito em obras na estrada
- Editar a posição de um objeto via menu admin para ajuste fino
- Remover objetos obsoletos do mapa via interface de gerenciamento

## Dicas de solução de problemas
- Objeto não aparece: Verifique se o modelo está correto e o banco de dados foi inicializado com o script `sql.sql`
- Posicionamento impreciso: Use o raycast mirando exatamente no local desejado
- Objetos não persistem: Confirme que o `oxmysql` está ativo e o script SQL foi executado
- Erro de banco de dados: Verifique as credenciais de conexão com o banco de dados no servidor