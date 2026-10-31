# Setup

Este guia assume que você já possui experiência hospedando servidores de Minecraft. Ele cobre apenas a configuração específica do AmongMC.

## 1. Clone o repositório

Clone este repositório para a pasta de sua preferência.

## 2. Instale o Server Pack

Execute o instalador para sua plataforma:

- **Windows:** `install.bat`
- **Linux / macOS / Git Bash / WSL:** `./install.sh`

Isso fará o download do Paper e de todos os plugins definidos no `plugins.json`. Se algum plugin falhar na instalação automática (ex.: proteção do Cloudflare no SpigotMC), você precisará baixá-lo manualmente, colocá-lo na pasta `server/plugins/` (verificando se a versão corresponde ao que está no `plugins.json`) e, opcionalmente, abrir uma issue se acreditar que é um bug.

Você pode passar `--accept-eula` para aceitar automaticamente o EULA da Mojang. Ao fazer isso, você está concordando com o EULA. Caso contrário, o `eula.txt` será criado para que você aceite manualmente.

## 3. Ajuste a memória do servidor

Abra o arquivo `server/start.bat` (não o que está na raiz do projeto, pois é apenas um atalho) ou `server/start.sh` com um editor de texto e altere os parâmetros `-Xms` e `-Xmx` para a quantidade de memória desejada.

O valor padrão é **4 GB**, que se mostrou suficiente durante os testes.

## 4. Configuração para Linux

O repositório agora inclui tanto `start.bat` quanto `start.sh`.

Se estiver utilizando Linux, use `start.sh` em vez de `start.bat`. Além disso, edite `server/spigot.yml` e altere o parâmetro `restart-script` de `start.bat` para `start.sh` para que o servidor possa reiniciar corretamente.

## 5. Configure uma forma de conexão

Para jogar pela internet, será necessário utilizar alguma forma de conexão entre os jogadores.

O servidor pode ser hospedado utilizando **Port Forwarding**, porém **isso não é recomendado**.

> **Nunca abra uma DMZ no seu roteador para hospedar o servidor.** Isso expõe sua máquina diretamente à internet e representa um risco significativo de segurança.

As alternativas recomendadas são:

- **Radmin VPN** para grupos em que todos os jogadores utilizam a versão Java no computador.
- **ZeroTier** quando houver jogadores na Bedrock Edition.

## 6. (Opcional) Sincronização de voz com o Discord

AmongMC possui suporte opcional para sincronizar automaticamente o mute dos jogadores em um canal de voz do Discord durante as partidas.

Para utilizá-lo:

- Crie um bot no Discord Developer Portal (ou utilize um já existente).
- Convide o bot para o servidor onde ocorrerão as partidas.
- Edite o arquivo:

```
server/plugins/Skript/scripts/changeme.sk
```

**Acesso rápido:** Você também pode abrir este arquivo diretamente usando o atalho **`DiscordSetup.lnk`** localizado na **pasta raiz do projeto**.

e preencha, **entre aspas**:

- Token do bot
- ID do servidor (Guild ID)
- ID do canal de voz utilizado para as partidas

Caso você nunca tenha criado um bot para Discord, uma pesquisa rápida na internet mostra o processo completo em poucos minutos.

## 7. Inicie o servidor

Execute `start.bat` (Windows) ou `./start.sh` (Linux / macOS / Git Bash / WSL) a partir da raiz do projeto.

Na primeira inicialização, o Paper fará o download automático das bibliotecas necessárias.

## 8. Pronto!

O servidor já estará configurado e pronto para uso.

Para aprender as mecânicas do jogo e conhecer todas as features implementadas, consulte o arquivo **`gameplay.md`**.