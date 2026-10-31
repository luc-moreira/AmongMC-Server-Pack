# Gameplay

## Antes de começar

Para iniciar uma partida, **ao menos um jogador deve ser operador (OP)** do servidor.

Isso pode ser feito pelo console com:

```text
op <nickname>
```

---

## Idioma

Para mudar o idioma para **Português**, primeiro certifique-se de que você é um operador (OP) do servidor.

Em seguida, clique com o botão direito na **bússola** para abrir as configurações da partida. Clique no **livro** no canto inferior esquerdo até que o idioma exibido seja **Português**.

---

## Lobby

Ao entrar no servidor, todos os jogadores aparecerão no lobby.

Na barra de atalhos (hotbar), cada jogador possui itens para personalizar seu personagem:

- 🎨 Escolher cor
- 👒 Escolher chapéu

Jogadores operadores também recebem uma **bússola**, que abre o menu de configurações da partida.

Praticamente todos os aspectos do jogo podem ser configurados por esse menu. Os nomes das configurações são autoexplicativos.

> **Importante:** apenas um jogador deve editar as configurações por vez. Alterações simultâneas podem causar comportamentos inesperados.

---

## Quantidade de jogadores

O jogo não possui um limite configurado de jogadores.

Entretanto, a quantidade recomendada é de **4 a 10 jogadores**.

Os limites práticos do sistema são:

- **Mínimo:** 3 jogadores
- **Máximo:** 16 jogadores

Com menos de **3 jogadores**, o impostor vence automaticamente.

Com mais de **16 jogadores**, o sistema de cores deixa de funcionar corretamente (existem apenas 16 cores disponíveis), o que acaba causando diversos problemas durante a partida.

---

## Livros do lobby

Antes de iniciar uma partida, recomenda-se que todos os jogadores leiam os livros disponíveis no lobby.

Eles contêm informações importantes sobre controles e funcionamento do jogo.

---

## Comandos

### Apenas operadores

```text
/start
```

Inicia uma nova partida.

```text
/end
```

Encerra a partida atual.

> **Atenção:** cuidado para não digitar `/stop` por engano... esse comando encerra o **servidor inteiro**. Cometi esse erro umas 20 vezes durante o desenvolvimento, espero que você não caia nessa também.

### Comandos de jogadores

```text
/all <mensagem>
```

**Apelidos:** `/allchat`, `/everyone`

Envia uma mensagem global para todos os jogadores durante uma partida ativa.

- **Durante o jogo (estado running):** O chat normal é **bloqueado** para jogadores vivos. Use `/all` para se comunicar com todos (vivos e mortos).
- **Durante reuniões:** O chat normal funciona para todos; `/all` também funciona.
- **Como fantasma (jogador morto):** Você só pode conversar com outros fantasmas via chat normal. Use `/all` para falar com jogadores vivos também.
- **No lobby/finalização:** O chat normal funciona; `/all` mostra uma mensagem de que não é necessário.

> **Dica:** A mensagem mostrará seu nome com sua cor e uma tag **[Morto]** se você for um fantasma.

---

## Gerenciamento de Chat

O sistema de chat se adapta com base no estado do jogo e no status do jogador:

| Estado do Jogo | Jogadores Vivos | Jogadores Mortos (Fantasmas) |
|----------------|-----------------|------------------------------|
| **Lobby / Finalização** | Chat normal ✅ | Chat normal ✅ |
| **Reunião** | Chat normal ✅ | Chat normal ✅ (com todos) |
| **Em jogo (Gameplay)** | **Bloqueado** ❌ — Use `/all` | Só pode conversar com outros fantasmas via chat normal. Use `/all` para alcançar todos. |

**Comportamentos principais:**
- Quando vivo durante o jogo, digitar no chat mostra a mensagem: *"Você não pode conversar enquanto vivo durante o jogo. Use /all para falar com todos."*
- Fantasmas veem uma tag **[Morto]** ao lado do nome no chat
- Mensagens `/all` recebem prefixo **[Todos]** (vivos) ou **[Todos - Morto]** (fantasmas)
- Todas as mensagens de chat respeitam as cores dos jogadores

---

## Chapéus & Sistema de Níveis

Chapéus são itens cosméticos que aparecem na cabeça do seu personagem. Eles são **desbloqueados ao subir de nível** através do sistema de conquistas.

### Como desbloquear chapéus

1. **Complete conquistas** para ganhar XP
2. **Suba de nível** ao atingir os limites de XP (fórmula triangular)
3. **Cada nível = 1 chapéu aleatório desbloqueado** (dos 27 chapéus disponíveis)

### Chapéus disponíveis (27 total)

Panda, Allay, Gato, Cabra, Galinha, Papagaio, Abelha, Axolotl, Morcego, Burro, Creeper, Agrupa de Ametista, Pérola do End, Diamante, Tocha de Redstone, Cenoura, Favão de Mel, Biscoito, Bolo, Baiacu, Peixe Tropical, Cogumelo Vermelho, Torchflower, Propagulo de Mangue, Muda de Cerejeira, Concha de Nautilus, Sino

### Visualizando & Equipando Chapéus

- Use `/hat` (ou `/chapeu`) para abrir o menu de seleção de chapéus
- Chapéus desbloqueados aparecem em **verde**; chapéus travados aparecem como **barreiras vermelhas** com "(Travado)"
- Slot 0 = Capacete Colorido (sua cor de jogador)
- Slot 1 = Sem Chapéu
- Slots 9–35 = Chapéus desbloqueáveis

### Tipos de Conquistas

- **Contador** — Repita uma ação X vezes (ex.: complete 100 tasks)
- **Marco** — Alcançe um objetivo específico uma vez (ex.: vença 1 partida)
- **Por Níveis** — Múltiplos níveis com recompensas crescentes (ex.: saboteie 5/25/100 vezes)
- **Coleção** — Complete um conjunto de conquistas relacionadas (ex.: todos os tipos de tasks)

### Exibição no Lobby

Enquanto estiver no lobby, seu **nível e progresso de XP** são mostrados na actionbar (acima da hotbar) e como título ao entrar.

---

## Entrar ou sair durante uma partida

O AmongMC foi programado para lidar com jogadores que entram ou saem durante uma partida.

- Se um jogador entrar sem ter participado desde o início, ele será colocado automaticamente como espectador.
- Se um jogador que já estava na partida sair e entrar novamente, ele deverá retornar como fantasma, preservando o estado da partida.

Apesar desse comportamento existir, **ele não foi extensivamente testado** e pode conter bugs. Sempre que possível, recomenda-se que jogadores que precisem sair aguardem o término da partida para entrar novamente.

---

## Compatibilidade com Bedrock Edition

O AmongMC foi desenvolvido priorizando a **Minecraft Java Edition**.

Jogadores da **Bedrock Edition** podem encontrar algumas limitações devido às diferenças entre as duas versões do Minecraft.

Algumas tasks foram propositalmente substituídas por outras mais simples na Bedrock Edition, pois sua execução era excessivamente difícil ou inconsistente nessa plataforma.

Mesmo assim, qualquer bug encontrado deve ser reportado.

---

## Boa diversão!

Caso encontre bugs, tenha sugestões ou queira contribuir com o projeto, fique à vontade para abrir uma Issue no GitHub.

Bom jogo!