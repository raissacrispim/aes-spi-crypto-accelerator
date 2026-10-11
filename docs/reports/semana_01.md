# Relatório — Semana 1: Kick-off, estudo e ambiente

## 1. Objetivo da semana

Preparar o ambiente de desenvolvimento, estruturar o repositório, criar o
backlog inicial e estudar o algoritmo AES (FIPS-197) e o protocolo SPI.

**Entregável:** repositório estruturado, backlog inicial, ambiente executando
um exemplo mínimo (compilação, lint e simulação) e relatório de estudo sobre
AES e SPI.

**Critério de aceite:** o repositório pode ser clonado em um ambiente limpo e o
fluxo mínimo executado com um único comando.

## 2. O que foi feito

| Item | Onde |
|------|------|
| Estrutura do repositório conforme a estrutura sugerida no escopo | raiz do repositório (`docs/`, `rtl/`, `models/`, `tb/`, `formal/`, `syn/`, `upf/`, `scripts/`) |
| Exemplo mínimo (`simple_and`) e testbench autoverificável | `rtl/simple_and.sv`, `tb/tb_simple_and.sv` |
| Listas de arquivos compartilhadas por lint e simulação | `scripts/rtl.f`, `scripts/tb.f` |
| Projeto de lint do SpyGlass | `scripts/lint.prj` |
| Fluxo automatizado (`make test`) | `Makefile` |
| Documentação do ambiente e da execução | `README.md` |
| Backlog do projeto, alinhado ao cronograma de 15 semanas | `docs/backlog.md` |
| Estudo sobre AES e SPI | `docs/reports/estudo_aes_spi.md` |
| Logs da execução do fluxo | `docs/reports/logs/` |

### 2.1 Ambiente

Ferramentas Synopsys, carregadas com `source /Tools/synopsys-scripts/snps.sh`:

- VCS X-2025.06-SP2 (compilação e simulação);
- SpyGlass X-2025.06-SP2 (lint);
- Verdi X-2025.06-SP2 (formas de onda);
- Design Compiler X-2025.06-SP2 (síntese, a partir da Semana 7).

### 2.2 Fluxo mínimo

```bash
git clone <url-do-repositorio>
cd aes-spi-crypto-accelerator
source /Tools/synopsys-scripts/snps.sh
make test
```

O alvo `make test` executa, em sequência:

1. `check-env` — verifica se `vcs` e `spyglass` estão no `PATH` e, caso
   contrário, indica o comando para carregar o ambiente;
2. `lint` — SpyGlass, objetivo `lint/lint_rtl`;
3. `compile` — VCS;
4. `sim` — execução do testbench.

Qualquer falha (erro de lint, de compilação ou teste reprovado) interrompe o
fluxo com código de saída diferente de zero. O testbench conta os erros e
encerra com `$fatal` se algum caso falhar, de modo que a mensagem de sucesso
só aparece quando todos os casos passam.

### 2.3 Estudo

O documento `docs/reports/estudo_aes_spi.md` cobre:

- AES: tamanhos de bloco e chave, organização do State, transformações de
  rodada, expansão de chave, sequência de rodadas e considerações para
  hardware;
- SPI: sinais, transferência, CPOL/CPHA e modos, mestre e escravo,
  considerações para RTL;
- relação entre SPI, banco de registradores e núcleo AES no projeto;
- lista de pontos a definir na arquitetura (Semana 2).

## 3. Resultados

Execução de `make test` (logs completos em
`docs/reports/logs/`):

| Etapa | Resultado |
|-------|-----------|
| Lint (SpyGlass, `lint/lint_rtl`) | 0 fatal, 0 error, 0 warning, 2 infos — *Exit Code 0* |
| Compilação (VCS) | sem erros; top `tb_simple_and`, timescale 1 ns / 1 ps |
| Simulação (VCS) | 4/4 casos da tabela-verdade corretos — "Todos os testes passaram!" |
| Fluxo completo | "=== Fluxo concluido com sucesso ===" |

Ferramentas: SpyGlass X-2025.06-SP2 e VCS X-2025.06-SP2, servidor
`srv-microeletronica3`, em 11/10/2026.

Relatórios detalhados do SpyGlass (HTML e `moresimple.rpt`) são gerados em
`scripts/lint/` e não são versionados; o resumo fica em `lint.log`.

## 4. Problemas encontrados

- O testbench inicial imprimia a mensagem de sucesso mesmo se uma verificação
  falhasse, pois `$error` não interrompe a simulação. Corrigido com contador
  de erros e `$fatal` ao final.
- O lint e a compilação usavam listas de arquivos diferentes (`rtl.f` e
  variável no `Makefile`). Unificado em `scripts/rtl.f` e `scripts/tb.f`.
- A execução de `make` sem carregar o ambiente Synopsys gerava erro pouco
  claro. Adicionada a verificação `check-env`.
- O relatório de estudo estava em `docs/spec/`, pasta reservada para a
  especificação fornecida pelo instrutor. Movido para `docs/reports/`.

- O SpyGlass avisa que as políticas clássicas usadas pelo objetivo
  `lint/lint_rtl` (lint, morelint, starc etc.) serão descontinuadas a partir
  da versão 2026.12, em favor do VC SpyGlass. Não afeta a versão instalada
  (X-2025.06-SP2); fica registrado para o caso de atualização do ambiente.
- O `simv` reexecutava a simulação por causa do ASLR da máquina (mensagem
  `VCS_SAVE_RESTORE_INFO`). Como o fluxo não usa `$save`, foi adicionada a
  opção `-no_save` à execução.

## 5. Próximos passos (Semana 2)

- Definir o diagrama de blocos e as interfaces de topo (GLOBAL RESET, clk
  from OSC, SPI IF, MEMORY DATA IF) e internas.
- Definir o mapa de registradores, incluindo os bits de configuração do PLL.
- Definir a estratégia de clock e reset e a travessia entre os domínios do
  SCLK e do sistema.
- Definir as interfaces dos modelos comportamentais do PLL e da memória.
- Escolher e justificar a microarquitetura do AES e definir a interface do
  núcleo.
- Responder aos pontos em aberto listados na seção 5 do estudo.
- Assim que estiverem disponíveis, alinhar as interfaces com a especificação
  funcional do instrutor e com o RTL de referência da trilha de verificação.
