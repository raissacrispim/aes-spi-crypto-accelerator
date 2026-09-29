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
│   ├── reports/
│   └── spec/
├── formal/
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

1. lint do RTL com SpyGlass;
2. compilação SystemVerilog com VCS;
3. execução do testbench com VCS.

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

## Status

Semana 1 — configuração inicial do ambiente e estruturação do projeto.
