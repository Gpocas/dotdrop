# tmux cheatsheet          (prefix = Ctrl-a)        [q] fecha   [/] busca

## Meus atalhos (tmux.conf)
| Atalho            | Ação                                              |
|-------------------|---------------------------------------------------|
| prefix H          | Abre este cheatsheet                              |
| prefix r          | Recarrega o tmux.conf                             |
| prefix C-l        | Busca janelas de todas as sessões (fzf) e troca   |
| prefix c          | Nova janela no diretório atual                    |
| prefix -          | Divide o painel na horizontal (um em cima/baixo)  |
| prefix |          | Divide o painel na vertical (lado a lado)         |
| prefix h/j/k/l    | Move entre painéis (repetível)                    |
| prefix C-setas    | Redimensiona o painel (5 células)                 |
| prefix e          | Fecha TODOS os outros painéis (confirma)          |
| prefix C-y        | Liga/desliga sincronização (digitar em todos)     |
| prefix C-a        | Envia Ctrl-a para o programa (ex.: início linha)  |

> Atenção: `prefix l` (última janela, padrão) foi substituído por mover painel.
> Use `prefix ;` (último painel) ou `prefix n/p` para janelas.

## Sessões
| Atalho            | Ação                                              |
|-------------------|---------------------------------------------------|
| prefix s          | Lista sessões (árvore)                            |
| prefix $          | Renomeia a sessão atual                           |
| prefix ( / )      | Sessão anterior / próxima                         |
| prefix L          | Última sessão usada                               |
| prefix d          | Desanexa (detach) – a sessão continua rodando     |

### Dentro da árvore (prefix s / prefix w)
| Tecla             | Ação                                              |
|-------------------|---------------------------------------------------|
| Enter             | Vai para o item selecionado                       |
| x                 | EXCLUI o item (sessão/janela/painel) – confirma   |
| t  /  X           | Marca item  /  exclui todos os marcados           |
| + / -             | Expande / recolhe                                 |
| C-s  /  n         | Busca por nome  /  repete a busca                 |
| f                 | Filtra itens                                      |
| v                 | Liga/desliga preview                              |
| q                 | Sai                                               |

## Janelas
| Atalho            | Ação                                              |
|-------------------|---------------------------------------------------|
| prefix w          | Lista janelas de todas as sessões                 |
| prefix ,          | Renomeia a janela                                 |
| prefix &          | Fecha a janela (confirma)                         |
| prefix n / p      | Próxima / anterior                                |
| prefix 1..9       | Vai para a janela N                               |
| prefix .          | Move a janela para outro índice                   |
| prefix f          | Procura janela pelo texto                         |

## Painéis
| Atalho            | Ação                                              |
|-------------------|---------------------------------------------------|
| prefix x          | Fecha o painel (confirma)                         |
| prefix z          | Zoom (maximiza / restaura)                        |
| prefix q          | Mostra números dos painéis (digite p/ ir)         |
| prefix o / ;      | Próximo painel / último painel                    |
| prefix { / }      | Troca de posição com o anterior / próximo         |
| prefix !          | Transforma o painel em uma nova janela            |
| prefix Espaço     | Alterna entre layouts                             |
| prefix M-1..M-5   | Layouts prontos (M = Alt)                         |

## Copy mode (vi)
| Tecla             | Ação                                              |
|-------------------|---------------------------------------------------|
| prefix [          | Entra no copy mode (rolar o histórico)            |
| v / V / C-v       | Seleção normal / linha / retângulo                |
| y                 | Copia (clipboard do Windows) e sai                |
| / ?  e  n N       | Busca para frente / trás e próximo / anterior     |
| C-u / C-d         | Meia página acima / abaixo                        |
| g / G             | Topo / fim do histórico                           |
| q                 | Sai                                               |
| prefix ]          | Cola o último buffer do tmux                      |

## Outros
| Atalho            | Ação                                              |
|-------------------|---------------------------------------------------|
| prefix :          | Prompt de comandos do tmux                        |
| prefix ?          | Lista TODOS os atalhos ativos                     |
| prefix /          | Mostra o que uma tecla faz                        |
| prefix t          | Relógio                                           |
| prefix ~          | Mensagens recentes do tmux                        |

## Linha de comando (fora ou dentro do tmux)
```sh
tmux new -s nome              # cria sessão "nome"
tmux new -A -s nome           # anexa se existir, senão cria
tmux ls                       # lista sessões
tmux a  -t nome               # anexa à sessão
tmux kill-session -t nome     # exclui a sessão "nome"
tmux kill-session -a          # exclui todas, menos a atual
tmux kill-server              # encerra o tmux inteiro
tmux rename-session -t a b    # renomeia sessão a -> b
tmux source ~/.config/tmux/tmux.conf
```

## No prompt (prefix :)
```
kill-session                  # exclui a sessão atual
kill-session -t nome          # exclui outra sessão
new -s nome                   # nova sessão
swap-window -t 1              # troca a janela atual com a 1
move-window -r                # renumera as janelas
setw synchronize-panes        # mesmo que prefix C-y
```
