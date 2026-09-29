# Estudo Inicial — AES e SPI

## 1. Objetivo

Este documento registra o estudo inicial dos conceitos necessários para o
desenvolvimento do acelerador criptográfico AES com interface SPI.

O objetivo é apresentar os fundamentos do algoritmo AES e do protocolo SPI,
relacionando esses conceitos com a futura implementação RTL do projeto. As
decisões específicas de arquitetura e protocolo que ainda não foram definidas
serão estabelecidas durante a etapa de especificação.

## 2. AES

### 2.1 Visão geral

O AES (Advanced Encryption Standard) é um algoritmo de criptografia simétrica
por blocos. O algoritmo processa blocos de dados de 128 bits e pode utilizar
chaves de 128, 192 ou 256 bits.

As três configurações são denominadas AES-128, AES-192 e AES-256,
respectivamente. O tamanho da chave determina o número de rodadas executadas
pelo algoritmo: 10 rodadas para AES-128, 12 para AES-192 e 14 para AES-256.

Durante o processamento, o bloco de 128 bits é interpretado como 16 bytes
organizados em uma matriz 4x4 denominada State. As transformações realizadas
pelo AES operam sobre esse estado até a geração do bloco cifrado de 128 bits.

Para a implementação RTL, será necessário definir qual tamanho de chave será
suportado pelo núcleo AES do projeto.

### 2.2 Tamanho do bloco e da chave

O tamanho do bloco processado pelo AES é sempre de 128 bits,
independentemente do tamanho da chave utilizada. Portanto, cada operação de
cifragem recebe um bloco de plaintext de 128 bits e produz um bloco de
ciphertext também de 128 bits.

Os tamanhos de chave definidos pelo AES são:

- AES-128: chave de 128 bits e 10 rodadas;
- AES-192: chave de 192 bits e 12 rodadas;
- AES-256: chave de 256 bits e 14 rodadas.

A escolha da variante influencia a arquitetura do hardware, especialmente a
lógica de expansão da chave e o número de rodadas necessárias para completar
uma operação.

### 2.3 Organização do estado

O bloco de entrada de 128 bits é dividido em 16 bytes. Internamente, esses
bytes são organizados em uma matriz 4x4 denominada State.

A organização do State é importante porque as transformações do AES são
definidas em termos dos bytes, linhas e colunas dessa matriz. Dessa forma, a
implementação RTL deve preservar corretamente a correspondência entre os bits
do barramento de entrada e as posições do State.

Uma representação conceitual dos bytes do estado é:

```text
| B0 | B4 | B8  | B12 |
| B1 | B5 | B9  | B13 |
| B2 | B6 | B10 | B14 |
| B3 | B7 | B11 | B15 |
```

A definição exata da indexação dos bytes no SystemVerilog deverá ser
documentada durante a implementação para evitar ambiguidades na manipulação do
State.

### 2.4 Etapas do algoritmo

O AES utiliza uma sequência de transformações aplicadas ao State. As principais
operações são SubBytes, ShiftRows, MixColumns e AddRoundKey.

Antes das rodadas principais ocorre uma operação AddRoundKey inicial. Em
seguida são executadas as rodadas do algoritmo. A rodada final possui uma
diferença importante: ela não executa a transformação MixColumns.

#### SubBytes

SubBytes realiza uma substituição não linear de cada byte do State. Cada byte
é substituído de acordo com uma tabela denominada S-box.

Como cada byte é transformado individualmente, a implementação em hardware
precisa fornecer uma forma de realizar a consulta à S-box. Diferentes
arquiteturas podem implementar essa operação por lógica combinacional, tabelas
ou outras estruturas adequadas à tecnologia utilizada.

#### ShiftRows

ShiftRows realiza deslocamentos cíclicos nas linhas do State.

A primeira linha permanece inalterada. As demais linhas são deslocadas por
diferentes quantidades de posições. Essa operação altera a posição dos bytes,
mas não modifica o valor individual de cada byte.

Em hardware, ShiftRows pode ser implementado principalmente por meio do
rearranjo das conexões entre os bytes do State.

#### MixColumns

MixColumns transforma cada coluna do State por meio de operações matemáticas
definidas sobre o campo finito GF(2^8).

Cada byte de saída de uma coluna é obtido a partir da combinação dos bytes da
coluna de entrada. Essa etapa contribui para a difusão dos dados durante a
cifragem.

A implementação RTL deverá realizar as operações necessárias sobre os bytes
sem utilizar aritmética inteira convencional de forma incorreta, pois as
operações são definidas no campo finito utilizado pelo AES.

#### AddRoundKey

AddRoundKey combina o State com uma chave de rodada utilizando a operação XOR.

Conceitualmente:

```text
State_out = State_in XOR RoundKey
```

Essa transformação conecta diretamente o processamento dos dados ao mecanismo
de expansão da chave, responsável por gerar as diferentes chaves utilizadas
ao longo das rodadas.

### 2.5 Expansão de chave

O AES utiliza uma chave diferente em cada rodada. Essas chaves são derivadas
da chave original por um procedimento denominado Key Expansion ou Key
Schedule.

A expansão utiliza operações sobre palavras da chave, incluindo substituições,
rotações e constantes de rodada. O número de chaves necessárias depende da
variante do AES utilizada.

Na implementação em hardware, será necessário decidir como as chaves de rodada
serão produzidas e armazenadas. Essa decisão influencia área, desempenho e
complexidade do núcleo.

### 2.6 Rodadas do AES

De forma simplificada, o fluxo de cifragem pode ser representado como:

```text
Plaintext
    |
    v
AddRoundKey inicial
    |
    v
Rodadas principais
    |
    |-- SubBytes
    |-- ShiftRows
    |-- MixColumns
    |-- AddRoundKey
    |
    v
Rodada final
    |
    |-- SubBytes
    |-- ShiftRows
    |-- AddRoundKey
    |
    v
Ciphertext
```

A rodada final não utiliza MixColumns.

O número de rodadas depende do tamanho da chave. Assim, o controlador do
núcleo AES deverá acompanhar o progresso das rodadas e indicar quando o
resultado final estiver disponível.

### 2.7 Considerações para implementação em hardware

Uma implementação RTL do AES pode ser dividida conceitualmente em datapath e
controle.

O datapath é responsável por armazenar e transformar o State e pode conter
blocos associados a:

- SubBytes;
- ShiftRows;
- MixColumns;
- AddRoundKey;
- expansão da chave.

A lógica de controle é responsável por coordenar as etapas do algoritmo,
controlar o número de rodadas e sinalizar o início e o término de uma operação.

Existem diferentes possibilidades arquiteturais. Por exemplo, o hardware pode
reutilizar recursos entre várias rodadas ou utilizar maior paralelismo. Essas
decisões produzem diferentes compromissos entre área, desempenho e consumo de
energia.

A arquitetura específica do núcleo AES deste projeto será definida em uma
etapa posterior.

## 3. SPI

### 3.1 Visão geral

SPI (Serial Peripheral Interface) é uma interface de comunicação serial
síncrona utilizada para transferir dados entre dispositivos.

A comunicação normalmente envolve um dispositivo que controla a transferência,
denominado master, e um ou mais dispositivos periféricos, denominados slaves.

Neste projeto, o acelerador criptográfico deverá possuir uma interface SPI para
permitir que um dispositivo externo envie comandos e dados e posteriormente
obtenha os resultados produzidos pelo núcleo AES.

### 3.2 Sinais da interface

Uma interface SPI convencional utiliza os seguintes sinais:

- SCLK: sinal de clock da comunicação SPI;
- MOSI: linha de dados transmitidos do master para o slave;
- MISO: linha de dados transmitidos do slave para o master;
- CS/SS: sinal utilizado para selecionar o dispositivo slave.

O master normalmente gera SCLK e controla a seleção do slave.

Quando o acelerador estiver operando como SPI slave, ele deverá receber os
dados enviados pelo master através de MOSI e disponibilizar os dados de
resposta através de MISO.

### 3.3 Funcionamento de uma transferência

Uma transferência SPI ocorre de forma serial. Os bits são transmitidos em
sincronismo com SCLK enquanto o slave correspondente está selecionado.

Durante os ciclos de clock, o master pode transmitir bits através de MOSI e,
simultaneamente, receber bits através de MISO. Por isso, SPI permite
comunicação full-duplex.

Para o projeto será necessário definir como a sequência de bits recebida será
organizada em comandos, endereços e dados internos.

Também deverá ser definido como o acelerador indicará informações como início
da operação, estado de processamento e disponibilidade do resultado.

### 3.4 CPOL e CPHA

O comportamento temporal da interface SPI é caracterizado por dois parâmetros
principais:

- CPOL: Clock Polarity;
- CPHA: Clock Phase.

CPOL determina o nível lógico de repouso do sinal SCLK.

CPHA determina em qual transição do clock os dados são amostrados e em qual
transição os dados são atualizados.

A combinação desses dois parâmetros produz quatro modos de operação SPI.

### 3.5 Modos SPI

Os quatro modos SPI são tradicionalmente identificados como:

```text
Modo 0: CPOL = 0, CPHA = 0
Modo 1: CPOL = 0, CPHA = 1
Modo 2: CPOL = 1, CPHA = 0
Modo 3: CPOL = 1, CPHA = 1
```

Master e slave precisam utilizar uma configuração compatível para que os dados
sejam transmitidos e amostrados corretamente.

O modo SPI utilizado pelo acelerador ainda deverá ser definido na
especificação do projeto.

### 3.6 SPI Master e SPI Slave

O SPI master controla a comunicação. Entre suas responsabilidades estão a
geração de SCLK, a seleção do slave e o início das transferências.

O SPI slave responde às transferências iniciadas pelo master.

No contexto deste projeto, o acelerador será controlado externamente através
da interface SPI. Portanto, a lógica RTL deverá implementar o comportamento
necessário para receber os comandos do dispositivo externo, interpretar os
dados recebidos e fornecer as respostas correspondentes.

### 3.7 Considerações para implementação em RTL

A interface SPI possui um domínio de clock associado ao SCLK externo, enquanto
o restante do acelerador poderá utilizar um clock interno diferente.

Essa situação exige atenção à transferência de informações entre domínios de
clock. O projeto prevê um bloco de sincronização/CDC entre a interface SPI e a
lógica interna.

Conceitualmente, a recepção SPI deverá:

1. detectar uma transferência válida;
2. receber os bits através de MOSI;
3. agrupar os bits recebidos;
4. interpretar comandos e dados;
5. transferir as informações para a lógica interna.

No sentido contrário, a interface deverá obter os dados internos que precisam
ser enviados e transmiti-los serialmente através de MISO.

A estratégia específica de CDC, o formato das transações e os detalhes
temporais serão definidos durante a especificação e implementação.

## 4. Relação com o projeto

### 4.1 Papel da interface SPI

A interface SPI constitui o meio de comunicação entre o dispositivo externo e
o acelerador.

Ela deverá permitir que comandos e dados sejam enviados ao circuito e que
informações de status e resultados sejam posteriormente lidas.

### 4.2 Papel do banco de registradores

O banco de registradores funciona como uma interface entre os comandos
recebidos e os blocos internos do acelerador.

Conceitualmente, ele poderá armazenar informações como:

- dados de entrada;
- chave criptográfica;
- sinais ou comandos de controle;
- informações de status;
- resultado produzido pelo AES.

O mapa de registradores e os campos específicos ainda deverão ser definidos na
etapa de especificação.

### 4.3 Papel do núcleo AES

O núcleo AES será responsável pelo processamento criptográfico.

Ele receberá os dados e a chave provenientes da lógica de controle, executará
as transformações necessárias e produzirá o bloco de resultado.

A lógica ao redor do núcleo deverá controlar o início da operação e identificar
quando o processamento tiver sido concluído.

### 4.4 Fluxo esperado de uma operação

Em alto nível, uma operação poderá seguir o seguinte fluxo conceitual:

```text
SPI Master
    |
    | comandos / chave / dados
    v
SPI Slave
    |
    v
Sincronização / CDC
    |
    v
Banco de Registradores
    |
    | start + key + plaintext
    v
AES Core
    |
    | ciphertext + status
    v
Banco de Registradores
    |
    v
SPI Slave
    |
    | resultado
    v
SPI Master
```

Esse fluxo representa apenas a arquitetura conceitual. O protocolo exato entre
os blocos e o mapa de registradores serão definidos posteriormente.

## 5. Pontos a definir na especificação

Os seguintes pontos deverão ser definidos antes da implementação definitiva:

- definir se o núcleo implementará AES-128, AES-192, AES-256 ou mais de uma
  configuração;
- definir se o projeto realizará apenas cifragem ou também decifragem;
- definir a arquitetura do datapath AES;
- definir a estratégia para geração e armazenamento das chaves de rodada;
- definir o modo SPI utilizado;
- definir a ordem de transmissão dos bits e bytes;
- definir o formato dos comandos SPI;
- definir o mapa de registradores;
- definir os sinais de controle e status;
- definir a estratégia de CDC entre SPI e a lógica interna;
- definir o comportamento de reset;
- definir os clocks utilizados pelos diferentes blocos.

## 6. Referências

As referências técnicas utilizadas no desenvolvimento deverão ser registradas
nesta seção durante o projeto.

Como referências primárias para o estudo detalhado, deverão ser consultadas a
especificação oficial do AES e documentação técnica referente ao protocolo SPI.
