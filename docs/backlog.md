# Backlog — AES SPI Crypto Accelerator

Backlog alinhado ao cronograma oficial do projeto (15 semanas, um entregável
por semana). Cada entrega é identificada por *tag* (ex.: `w06-rtl-v1.0`) e
acompanhada de `docs/reports/semana_XX.md`.

## Fase 1 — Especificação e arquitetura

### Semana 1 — Kick-off, estudo e ambiente

- [x] Criar estrutura inicial do repositório.
- [x] Configurar ambiente Synopsys.
- [x] Validar compilação e simulação com VCS.
- [x] Configurar lint com SpyGlass.
- [x] Criar fluxo automatizado com Makefile (`make test`).
- [x] Documentar ambiente e execução no README.
- [x] Estudar AES (FIPS-197) e protocolo SPI.
- [x] Elaborar relatório da Semana 1.

**Aceite:** repositório clonado em ambiente limpo executa o fluxo mínimo com um único comando.

### Semana 2 — Arquitetura e microarquitetura

- [ ] Diagrama de blocos e interfaces internas (RESET, PLL, SPI, AES, MEMORY/DATA, memória).
- [ ] Interfaces de topo: GLOBAL RESET, clk from OSC, SPI IF, MEMORY DATA IF.
- [ ] Mapa de registradores (configuração, controle, status, bits do PLL; reserva para modos de energia).
- [ ] Estratégia de clock e reset: SPI no domínio SCLK (shift register, contador, MISO), banco de registradores e interface com AES no domínio do sistema; travessia entre domínios e reset de cada um.
- [ ] PLL com configuração padrão após reset; reprogramação via SPI somente após `locked`.
- [ ] Interface dos modelos comportamentais do PLL e da memória (compatível com a trilha de verificação).
- [ ] Escolha e justificativa da microarquitetura do AES.
- [ ] Interface do núcleo AES (controle/status, chave, acesso à memória).
- [ ] Apresentar arquitetura ao verificador parceiro.

**Entregável:** documento de arquitetura v1.0. **Aceite:** arquitetura aprovada na defesa.

## Fase 2 — Desenvolvimento do RTL

### Semana 3 — Núcleo AES I: datapath das rodadas

- [ ] SubBytes, ShiftRows, MixColumns, AddRoundKey.
- [ ] Testes unitários com valores intermediários da FIPS-197.

**Aceite:** todas as transformações conferem com a referência; lint sem erros.

### Semana 4 — Núcleo AES II: expansão de chave e controle

- [ ] Expansão de chave.
- [ ] Controle do núcleo (sequenciamento das rodadas, início/fim).
- [ ] Testbench dirigido com vetores FIPS-197.

**Aceite:** todos os vetores de referência passam; lint sem erros.

### Semana 5 — SPI, RESET e modelo do PLL

- [ ] Interface SPI.
- [ ] Sincronização SCLK → sistema.
- [ ] Banco de registradores (configuração, controle, status, bits do PLL).
- [ ] Bloco de RESET.
- [ ] Modelo comportamental do PLL em `models/`.
- [ ] Testbench: escrita/leitura via SPI, sequência de reset e travamento do PLL.

**Aceite:** escrita/leitura de todos os registradores via SPI; reset e `locked` conforme especificação; lint sem erros e avisos justificados.

### Semana 6 — Subsistema de dados, integração e RTL v1.0

- [ ] MEMORY / DATA System.
- [ ] Modelo comportamental da memória (mock) em `models/`.
- [ ] Integração do top-level.
- [ ] Teste ponta a ponta: SPI → MEMORY DATA IF → AES → MEMORY DATA IF.
- [ ] Verificação de CDC (SCLK × sistema).
- [ ] Correção dos problemas encontrados.
- [ ] Entrega ao verificador parceiro (tag **RTL v1.0**).

**Aceite:** fluxo completo em simulação; interfaces de topo conforme especificação; nenhuma violação de CDC sem justificativa.

## Fase 3 — Síntese inicial

### Semana 7 — Rodada inicial de síntese

- [ ] SDC: clock do PLL e SCLK assíncronos, entradas, saídas, caminhos de sincronização.
- [ ] Modelos (PLL, memória) como caixas-pretas/macros.
- [ ] Síntese do RTL v1.0 com a biblioteca do PDK.
- [ ] Análise de área, timing e potência; caminhos críticos.

**Aceite:** síntese sem erros, sem latches não intencionais, timing atendido ou plano de correção documentado.

## Fase 4 — Verificação formal de equivalência

### Semana 8 — Equivalência I: RTL × netlist

- [ ] Fluxo Formality: RTL, netlist, bibliotecas do PDK, SVF.
- [ ] Caixas-pretas consistentes com a síntese.
- [ ] *match* / *verify* e análise de pontos não casados/não equivalentes.

**Aceite:** fluxo por script; pontos casados ou justificados; resultado registrado.

### Semana 9 — Equivalência II: depuração e fechamento

- [ ] Depurar não equivalências e pontos não verificados.
- [ ] Exercício de diagnóstico com alteração intencional.
- [ ] Corrigir defeitos (incluindo issues do verificador parceiro), nova síntese e equivalência.
- [ ] Tag **RTL v1.1**.

**Aceite:** equivalência RTL v1.1 × netlist confirmada, sem pontos não verificados sem justificativa.

## Fase 5 — Intenção de potência

### Semana 10 — Arquitetura de energia

- [ ] Perfil de atividade dos blocos.
- [ ] Modos de operação (ativo, ocioso, desligado).
- [ ] Domínios de potência e power state table (RESET, PLL, SPI sempre ligados).
- [ ] Estratégias de isolamento e retenção.
- [ ] Sequência de desligamento e religamento.

**Aceite:** arquitetura de energia aprovada na defesa.

### Semana 11 — UPF

- [ ] UPF: domínios, redes, chaves, isolamento, retenção, level shifters (se aplicável).
- [ ] Verificação estática UPF × RTL.
- [ ] Simulação power-aware dos modos.

**Aceite:** UPF sem erros; corrupção em domínios desligados e isolamento/retenção corretos.

## Fase 6 — Técnicas de baixo consumo

### Semana 12 — Power gating

- [ ] Controlador de energia (isolar, salvar, desligar, religar, restaurar, liberar).
- [ ] Integração com banco de registradores (comandos e status).
- [ ] Testbench das transições entre modos.

**Aceite:** desligamento/religamento em simulação power-aware com isolamento e retenção corretos.

### Semana 13 — Clock gating e outras técnicas

- [ ] Clock gating com ICG.
- [ ] Isolamento de operandos, redução de chaveamento, desligamento de lógica ociosa.
- [ ] Entrega ao verificador parceiro para regressão (tag **RTL v2.0 (low power)**).

**Aceite:** funcionalidade da v1.0 preservada; transições de modo funcionando em simulação power-aware.

### Semana 14 — Síntese low power e comparação

- [ ] Síntese do RTL v2.0 com UPF e inserção automática de clock gating.
- [ ] Comparação com baseline (área, timing, potência por modo).
- [ ] Equivalência RTL v2.0 × netlist low power.

**Aceite:** síntese com UPF sem erros; ganhos/custos quantificados; equivalência confirmada.

## Fase 7 — Encerramento

### Semana 15 — Encerramento

- [ ] Consolidar documentação (arquitetura, energia, guia do repositório).
- [ ] Consolidar defeitos do verificador parceiro e estado final.
- [ ] Apresentação final.
- [ ] Artigo técnico/científico.
- [ ] Release final.

**Aceite:** projeto reproduzível (simulação, síntese, formal, UPF por scripts); apresentação realizada.
