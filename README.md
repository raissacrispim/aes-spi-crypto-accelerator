# AES SPI Crypto Accelerator

Projeto hands-on de desenvolvimento RTL de um acelerador criptográfico AES
controlado através de uma interface SPI.

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
aes_spi/
├── docs/
│   ├── architecture/
│   ├── reports/      # relatórios semanais, estudo AES/SPI e logs das ferramentas
│   └── spec/         # especificação funcional (fornecida pelo instrutor)
├── formal/
├── models/       # modelos comportamentais do PLL e da memória (fora do RTL sintetizável)
├── rtl/
├── scripts/
├── syn/
├── tb/
├── upf/
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

## Fluxo mínimo

O ambiente inicial utiliza o módulo `simple_and` apenas para validar a
infraestrutura de desenvolvimento.

Executar todo o fluxo:

```bash
make test
```

Esse comando executa:

1. verificação de que o ambiente Synopsys está carregado;
2. lint do RTL com SpyGlass;
3. compilação SystemVerilog com VCS;
4. execução do testbench com VCS.

Os logs de cada etapa são salvos em `docs/reports/logs/` (`lint.log`,
`compile.log`, `sim.log`) e versionados como evidência da entrega. O
comando termina com erro se alguma etapa falhar, inclusive se algum teste da
simulação falhar.

Os arquivos RTL e de testbench são listados em `scripts/rtl.f` e
`scripts/tb.f`, usados tanto pelo lint quanto pela compilação.

Também é possível executar cada etapa separadamente:

```bash
make lint
make compile
make sim
```

Para remover os arquivos gerados:

```bash
make clean
```

## Resultado esperado

O lint do módulo de teste deve terminar com:

```text
Reported Messages:         0 Fatals,    0 Errors,      0 Warnings
```

A simulação deve apresentar:

```text
Todos os testes passaram!
```

seguida de:

```text
=== Fluxo concluido com sucesso ===
```

Para conferir rapidamente os resultados nos logs:

```bash
grep "Reported Messages" docs/reports/logs/lint.log
grep "Todos os testes" docs/reports/logs/sim.log
```

## Documentação

- `docs/reports/estudo_aes_spi.md` — estudo sobre AES (FIPS-197) e SPI.
- `docs/reports/semana_XX.md` — relatório de cada semana.
- `docs/backlog.md` — backlog do projeto, alinhado ao cronograma.

## Entregas

| Semana | Tag | Conteúdo |
|--------|-----|----------|
| 1 | `w01-setup-v1.1` | ambiente, estrutura do repositório, backlog, fluxo mínimo e estudo AES/SPI |

## Status

Semana 1 concluída. Próxima etapa: Semana 2 — arquitetura e microarquitetura.
