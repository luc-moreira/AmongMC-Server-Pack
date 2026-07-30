# Setup

Este guia assume que você já possui experiência hospedando servidores de Minecraft. Ele cobre apenas a configuração específica do AmongMC.

## 1. Clone o repositório

Clone este repositório para a pasta de sua preferência.

## 2. Ajuste a memória do servidor

Abra o arquivo `start.bat` e altere os parâmetros `-Xms` e `-Xmx` para a quantidade de memória desejada.

O valor padrão é **4 GB**, que se mostrou suficiente durante os testes.

## 3. Linux

O repositório inclui apenas um `start.bat`.

Caso esteja utilizando Linux, crie um script `.sh` equivalente contendo os mesmos parâmetros da JVM. Este guia assume que você já saiba iniciar um servidor Paper através da linha de comando.

## 4. Configure uma forma de conexão

Para jogar pela internet, será necessário utilizar alguma forma de conexão entre os jogadores.

O servidor pode ser hospedado utilizando **Port Forwarding**, porém **isso não é recomendado**.

> **Nunca abra uma DMZ no seu roteador para hospedar o servidor.** Isso expõe sua máquina diretamente à internet e representa um risco significativo de segurança.

As alternativas recomendadas são:

- **Radmin VPN** para grupos em que todos os jogadores utilizam a versão Java no computador.
- **ZeroTier** quando houver jogadores na Bedrock Edition (celular ou outros dispositivos). Nesse caso, o ZeroTier também deve ser instalado no computador que hospeda o servidor.

## 5. (Opcional) Sincronização de voz com o Discord

AmongMC possui suporte opcional para sincronizar automaticamente o mute dos jogadores em um canal de voz do Discord durante as partidas.

Para utilizá-lo:

- Crie um bot no Discord Developer Portal (ou utilize um já existente).
- Convide o bot para o servidor onde ocorrerão as partidas.
- Edite o arquivo:

```
server/plugins/Skript/scripts/changeme.sk
```

e preencha, **entre aspas**:

- Token do bot
- ID do servidor (Guild ID)
- ID do canal de voz utilizado para as partidas

Caso você nunca tenha criado um bot para Discord, uma pesquisa rápida na internet mostra o processo completo em poucos minutos.

## 6. Inicie o servidor

Execute o arquivo `start.bat` (ou seu equivalente em Linux).

Na primeira inicialização, o Paper fará o download automático das bibliotecas necessárias.

## Pronto!

O servidor já estará configurado e pronto para uso.

Para aprender as mecânicas do jogo e conhecer todas as features implementadas, consulte o arquivo **`gameplay.md`**.