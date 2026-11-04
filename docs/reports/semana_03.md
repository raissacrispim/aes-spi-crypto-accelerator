# Relatório — Semana 3: Microarquitetura e transformações de rodada

## 1. Objetivo da semana

Definir a microarquitetura do MiniSoC AES (como implementar o que o Block Guide
especifica) e completar as transformações de rodada do AES, diretas e
inversas, com testes unitários pelos valores intermediários da FIPS-197.

**Entregável:** documento de microarquitetura v1.0 (`docs/architecture/`), RTL
de todas as transformações de rodada (diretas e inversas) e testes unitários.

**Critério de aceite:** microarquitetura aprovada pelo instrutor na defesa
curta; transformações conferem com os valores de referência; lint sem erros.

## 2. O que foi feito

### 2.1 Documento de microarquitetura

`docs/architecture/microarquitetura_v1.0.md`, com:

- diagrama de blocos interno e a tabela de módulos, arquivos e domínios de
  clock;
- **datapath AES iterativo, uma rodada por ciclo** (11 ciclos por bloco),
  com caminhos de cifra e cifra inversa compartilhando o registrador de estado;
- **expansão de chave pré-computada** uma vez por operação (11 round keys,
  10 ciclos), lida em ordem inversa na decriptação;
- estrutura de encadeamento para os seis modos (ECB, CBC, PCBC, CFB, OFB, CTR);
- **FSM do `minisoc_aes_top`** (IDLE, CHECK, KEY_EXP, READ, RUN, WRITE, NEXT,
  FINISH);
- **estratégia de CDC**: toggle para o quadro SPI (`spi_sclk` → `clk`) e para o
  START (`clk` → `sys_clk`), 2 FFs para status de nível, código Gray para
  BLOCKS_DONE, sinais quase-estáticos para a configuração;
- **sequência de reset** do domínio do sistema (reset mantido até o lock do
  PLL e mais 4 ciclos de `sys_clk`).

As decisões e alternativas estão justificadas no documento. As hipóteses que
dependem de respostas às dúvidas da Semana 2 estão marcadas como
**[Dúvida n]**.

### 2.2 RTL (`rtl/minisoc_aes/`)

| Módulo | Função | Semana |
|--------|--------|--------|
| `minisoc_aes_sbox` / `minisoc_aes_inv_sbox` | S-box e S-box inversa | 2 |
| `minisoc_aes_sub_bytes` / `minisoc_aes_inv_sub_bytes` | SubBytes e InvSubBytes | 2 |
| `minisoc_aes_shift_rows` / `minisoc_aes_inv_shift_rows` | ShiftRows e InvShiftRows | 2 |
| `minisoc_aes_mix_columns` | MixColumns (matriz 02 03 01 01) | **3** |
| `minisoc_aes_inv_mix_columns` | InvMixColumns (matriz 0e 0b 0d 09) | **3** |
| `minisoc_aes_add_round_key` | AddRoundKey (XOR; é a própria inversa) | **3** |

MixColumns e InvMixColumns usam a função `xtime` (multiplicação por 2 em
GF(2^8)); as multiplicações por 09, 0b, 0d e 0e são decompostas em somas de
potências de 2. Todas as transformações são combinacionais.

### 2.3 Testbench `minisoc_aes_round_tb`

- **Apêndice B (cifragem), rodadas 1, 2 e 9:** MixColumns(after ShiftRows),
  InvMixColumns(after MixColumns) e AddRoundKey até o início da rodada seguinte;
  rodada 10: AddRoundKey até o ciphertext.
- **Apêndice C.1 (cifragem inversa), rodadas 1, 2 e 9:** AddRoundKey e
  InvMixColumns até o início da rodada seguinte; rodada 10: AddRoundKey até o
  plaintext.
- **Encadeamento completo:** todas as transformações compostas na ordem da
  FIPS-197, com as round keys dos apêndices, reproduzem o ciphertext e o
  plaintext dos Apêndices B e C.1 nos dois sentidos. Isso confirma que os
  módulos funcionam juntos, na convenção de bytes do Block Guide, antes do
  datapath da Semana 4.

Validação adicional: o testbench foi executado contra versões propositalmente
alteradas do RTL (um coeficiente errado em MixColumns, outro em InvMixColumns e
um XOR invertido em AddRoundKey) e falhou nos três casos.

## 3. Resultados

| Etapa | Resultado |
|-------|-----------|
| `minisoc_aes_sbox_tb` | **PASS** — 514 verificações |
| `minisoc_aes_sub_shift_tb` | **PASS** — 20 verificações |
| `minisoc_aes_round_tb` | **PASS** — 21 verificações (incluindo cifragem e decriptação completas dos Apêndices B e C.1) |
| Lint dos 7 módulos de topo (`sub_bytes`, `inv_sub_bytes`, `shift_rows`, `inv_shift_rows`, `mix_columns`, `inv_mix_columns`, `add_round_key`) | 0 fatal, 0 error, 0 warning, 2 infos em cada |
| Fluxo completo (`make test`) | `=== Fluxo concluido com sucesso ===` |

Ferramentas: SpyGlass X-2025.06-SP2 e VCS X-2025.06-SP2, em 04/11/2026. Logs
completos em `docs/reports/logs/`.

## 4. Problemas encontrados

- O testbench usava arrays como argumento de tarefa, recurso de SystemVerilog
  não suportado por todos os simuladores; foi reescrito com uma função de
  acesso às round keys para manter a portabilidade.

## 5. Próximos passos (Semana 4)

- `minisoc_aes_key_exp`: expansão de chave AES-128 pré-computada.
- `minisoc_aes_dp`: datapath iterativo de cifra e cifra inversa com interface
  start/done.
- Testbench com os vetores da FIPS-197 nos dois sentidos.
- Incorporar as respostas do instrutor às dúvidas sobre o Block Guide.
