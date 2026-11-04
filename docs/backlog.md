# Backlog — MiniSoC AES (RTL Design Track)

Backlog alinhado ao cronograma de 13 semanas (encerramento em 29/01/2027,
recesso de 21/12/2026 a 03/01/2027, entregas às sextas). Especificação de
referência: Block Guide MiniSoC AES v1.0.0.

Cada entrega é identificada por *tag* e acompanhada de
`docs/reports/semana_XX.md`. Marcos: `rtl-v1.0`, `rtl-v1.1`, `rtl-v2.0`.

## Semana 1 — Kick-off, estudo e ambiente (concluída)

- [x] Estrutura do repositório, ambiente Synopsys e fluxo `make test`.
- [x] Estudo de AES (FIPS-197) e SPI.
- [x] Backlog inicial e relatório da semana.

## Semana 2 — Desafio SubBytes e ShiftRows (30/10)

- [x] `minisoc_aes_sbox`, `minisoc_aes_sub_bytes`, `minisoc_aes_shift_rows`.
- [x] Opcional: `minisoc_aes_inv_sbox`, `minisoc_aes_inv_sub_bytes`, `minisoc_aes_inv_shift_rows`.
- [x] Testbench: S-box nas 256 entradas; Apêndice B (rodadas 1 e 10).
- [x] Leitura das seções 1–3 e 8 do Block Guide e lista de dúvidas.
- [x] Reorganização de `rtl/` conforme a seção 10 do Block Guide.
- [x] Execução com VCS/SpyGlass, logs e relatório `semana_02.md` completos.

**Aceite:** um comando; PASS na S-box e no Apêndice B; lint sem erros.

## Semana 3 — Microarquitetura e transformações de rodada (06/11)

- [x] Documento de microarquitetura v1.0: diagrama interno, microarquitetura do AES, FSM do `minisoc_aes_top`, CDC `spi_sclk` × `clk` por toggle (§5.3), sequência de reset (§4.2).
- [x] MixColumns e AddRoundKey.
- [x] InvSubBytes, InvShiftRows, InvMixColumns.
- [x] Testes unitários: Apêndice B (cifragem) e C.1 (cifragem inversa).
- [x] Execução com VCS/SpyGlass, logs e relatório `semana_03.md` completos.
- [ ] Apresentação da microarquitetura ao verificador parceiro.

**Aceite:** microarquitetura aprovada na defesa; transformações conferem; lint sem erros.

## Semana 4 — Expansão de chave e datapath AES-128 (13/11)

- [ ] `minisoc_aes_key_exp` (11 round keys; pré-computada ou on-the-fly, justificada).
- [ ] `minisoc_aes_dp`: cifra e cifra inversa de um bloco, interface start/done.
- [ ] Testbench com os vetores da FIPS-197 nos dois sentidos.

**Aceite:** cifragem e decriptação conferem com os vetores; lint sem erros.

## Semana 5 — SPI front-end e PLL mock (20/11)

- [ ] `minisoc_spi` (§5): Mode 0, MSB-first, quadro de 40 bits, leitura em duas transações (NOP 0x3F).
- [ ] Recepção em `spi_sclk`, banco no domínio `clk`, evento de quadro por toggle.
- [ ] Banco de registradores (§6).
- [ ] `minisoc_pll_mock` (§4.1): 2 GHz, enable, PLL_DIV_SEL, lock pseudoaleatório.
- [ ] Testbench: leitura/escrita de todos os registradores; PLL até PLL_LOCKED (passos 8 e 9 da §9).

**Aceite:** registradores R/W escritos e lidos; R não alterados; PLL trava nos quatro divisores; lint sem erros e avisos justificados.

## Semana 6 — AES engine e memória compartilhada (27/11)

- [ ] `minisoc_memory` (§7): 1024 × 32, single-port, ownership por MEM_SEL_AES.
- [ ] `minisoc_aes_top` (§8): captura no START, leitura/escrita in-place, BUSY/DONE/ERROR/BLOCKS_DONE.
- [ ] Modos ECB, CBC e CTR, cifragem e decriptação.
- [ ] Detecção de configuração inválida (NUM_BLOCKS, MODE).
- [ ] Modelo de referência em software e testbench com 1, 2 e 256 blocos.

**Aceite:** ECB, CBC e CTR conferem nos dois sentidos; ERROR nas configurações inválidas; lint sem erros.

## Semana 7 — Integração do top-level e RTL v1.0 (04/12)

- [ ] `minisoc_top` com as interfaces de topo idênticas à §3.
- [ ] Sequência de reset (§4.2).
- [ ] Teste de ponta a ponta com os 14 passos da §9.
- [ ] Análise de CDC: `spi_sclk`×`clk`, `clk`×`sys_clk`, `mem_clk`×`sys_clk`.
- [ ] Tag `rtl-v1.0` e entrega ao verificador parceiro.

## Semana 8 — Síntese inicial (11/12)

- [ ] SDC: `clk`, `sys_clk`, `spi_sclk`, `mem_clk`, grupos assíncronos.
- [ ] PLL mock e memória como caixas-pretas/macros.
- [ ] Síntese do RTL v1.0 e relatório de baseline (área, timing, potência).

## Semana 9 — Verificação formal de equivalência (18/12)

- [ ] Fluxo Formality (RTL, netlist, bibliotecas, SVF).
- [ ] Match/verify e depuração; exercício de diagnóstico.

## Recesso — 21/12 a 03/01

## Semana 10 — Fechamento funcional e RTL v1.1 (08/01)

- [ ] Modos PCBC, CFB e OFB.
- [ ] Correção das issues do verificador parceiro.
- [ ] Nova síntese e equivalência; tag `rtl-v1.1`.

## Semana 11 — Arquitetura de energia e UPF (15/01)

- [ ] Perfil de atividade, modos, domínios e tabela de estados de potência.
- [ ] Isolamento, retenção e sequências; UPF.
- [ ] Verificação estática e simulação power-aware.

## Semana 12 — Técnicas de baixo consumo e RTL v2.0 (22/01)

- [ ] Controlador de energia e power gating.
- [ ] Clock gating (ICG) e outras técnicas.
- [ ] Tag `rtl-v2.0` e entrega ao verificador parceiro.

## Semana 13 — Síntese low power e encerramento (29/01)

- [ ] Síntese com UPF, comparação com o baseline, equivalência.
- [ ] Documentação, defeitos do verificador, release final e apresentação.
