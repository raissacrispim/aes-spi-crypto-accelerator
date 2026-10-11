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
0 fatal
0 error
0 warning
```

A simulação deve apresentar:

```text
Todos os testes passaram!
```

seguida de:

```text
=== Fluxo concluido com sucesso ===
```

## Documentação

- `docs/reports/estudo_aes_spi.md` — estudo sobre AES (FIPS-197) e SPI.
- `docs/reports/semana_XX.md` — relatório de cada semana.
- `docs/backlog.md` — backlog do projeto, alinhado ao cronograma.

## Status

Semana 1 — configuração inicial do ambiente e estruturação do projeto.
