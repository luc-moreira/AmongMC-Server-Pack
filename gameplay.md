# Gameplay

## Antes de começar

Para iniciar uma partida, **ao menos um jogador deve ser operador (OP)** do servidor.

Isso pode ser feito pelo console com:

```text
op <nickname>
```

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