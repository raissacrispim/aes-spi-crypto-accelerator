# AES SPI Crypto Accelerator — MiniSoC AES

Projeto hands-on de desenvolvimento RTL de um acelerador criptográfico AES-128
controlado através de uma interface SPI.

Especificação de referência: **Block Guide MiniSoC AES v1.0.0** (fornecido
pelo instrutor). Interfaces de topo, nomes de módulos e arquivos, mapa de
registradores, protocolo SPI e modelo de programação seguem esse documento.

## Objetivo

Desenvolver e verificar uma arquitetura RTL composta por:

- interface SPI;
- sincronização/CDC;
- banco de registradores;
- núcleo criptográfico AES;
- controle de baixo consumo.

O projeto será desenvolvido em SystemVerilog e seguirá um fluxo incluindo
lint, simulação, síntese, verificação formal e técnicas de low power.

## Estrutura do repositório

```text
aes-spi-crypto-accelerator/
├── docs/
│   ├── architecture/      # microarquitetura e arquitetura de energia
│   ├── reports/           # relatórios semanais, estudo AES/SPI e logs
│   ├── spec/              # especificação (Block Guide)
│   └── backlog.md
├── rtl/                   # organização da seção 10 do Block Guide
│   ├── minisoc_aes/       # AES: transformações, datapath, expansão de chave, engine
│   ├── minisoc_mem/       # memória compartilhada 1024 x 32
│   ├── minisoc_pll/       # PLL mock (modelo de integração)
│   └── minisoc_spi/       # front-end SPI e banco de registradores
├── tb/                    # testbenches e modelo de referência
├── formal/                # scripts e relatórios do Formality
├── syn/                   # SDC, scripts e relatórios de síntese
├── upf/                   # arquivos UPF e relatórios
├── scripts/               # automação do fluxo (rtl.f)
├── Makefile
└── README.md
```

## Ambiente

O desenvolvimento está sendo realizado utilizando ferramentas Synopsys.

Versões validadas:

- VCS X-2025.06-SP2
- SpyGlass X-2025.06-SP2
- Verdi X-2025.06-SP2
- Design Compiler X-2025.06-SP2

Antes de utilizar as ferramentas, carregar o ambiente:

```bash
source /Tools/synopsys-scripts/snps.sh
```

## Início rápido

A partir de um ambiente limpo, o fluxo completo é executado com:

```bash
git clone https://github.com/raissacrispim/aes-spi-crypto-accelerator.git
cd aes-spi-crypto-accelerator
source /Tools/synopsys-scripts/snps.sh
make test
```

O `git clone` cria a pasta `aes-spi-crypto-accelerator` no diretório atual;
se ela já existir, escolha outro nome no final do comando
(`git clone <url> outro_nome`) e entre nessa pasta.

Para obter exatamente a versão de uma entrega, use a *tag* correspondente:

```bash
git checkout w01-setup-v1.1
```

## Fluxo

`make test` executa, em sequência:

1. verificação de que o ambiente Synopsys está carregado;
2. lint (SpyGlass, goal `lint/lint_rtl`) de cada módulo listado em `LINT_TOPS`;
3. compilação e simulação (VCS) de cada testbench listado em `TESTS`.

O comando termina com erro se alguma etapa falhar, inclusive se algum teste
falhar. Os arquivos RTL são listados em `scripts/rtl.f`.

Comandos individuais:

```bash
make lint                              # somente lint
make sim                               # somente simulação
make lint-minisoc_aes_sub_bytes        # lint de um módulo
make sim-minisoc_aes_sbox_tb           # um testbench
make clean                             # remove os arquivos gerados
```

Os arquivos gerados ficam em `build/` (não versionado). Os logs ficam em
`docs/reports/logs/` e são versionados como evidência das entregas:
`lint_<módulo>.log`, `compile_<testbench>.log` e `sim_<testbench>.log`.

## Testbenches

| Testbench | O que verifica |
|-----------|----------------|
| `minisoc_aes_sbox_tb` | S-box e S-box inversa nas 256 entradas, contra referência calculada em GF(2^8) |
| `minisoc_aes_sub_shift_tb` | SubBytes, ShiftRows e inversas com os vetores da FIPS-197 (Apêndices B e C.1) |
| `minisoc_aes_round_tb` | MixColumns, InvMixColumns e AddRoundKey (Apêndices B e C.1) e cifragem/decriptação completas encadeando todas as transformações |

## Resultado esperado

Cada lint deve terminar com:

```text
Reported Messages:         0 Fatals,    0 Errors,      0 Warnings
```

Cada testbench imprime uma linha `PASS: ...`, e o fluxo termina com:

```text
=== Fluxo concluido com sucesso ===
```

Para conferir rapidamente os resultados nos logs:

```bash
grep "Reported Messages" docs/reports/logs/lint_*.log
grep -h "PASS\|FAIL" docs/reports/logs/sim_*.log
```

## Documentação

- `docs/architecture/microarquitetura_v1.0.md` — microarquitetura do MiniSoC AES.
- `docs/reports/estudo_aes_spi.md` — estudo sobre AES (FIPS-197) e SPI.
- `docs/reports/semana_XX.md` — relatório de cada semana.
- `docs/backlog.md` — backlog do projeto, alinhado ao cronograma.

## Entregas

| Semana | Tag | Conteúdo |
|--------|-----|----------|
| 1 | `w01-setup-v1.1` | ambiente, estrutura do repositório, backlog, fluxo mínimo e estudo AES/SPI |
| 2 | `w02-sbox-v1.0` | S-box, SubBytes, ShiftRows (e inversas) + testbenches |
| 3 | `w03-uarch-v1.0` | microarquitetura v1.0 + todas as transformações de rodada |

## Status

Semana 3 em andamento — microarquitetura e transformações de rodada.
