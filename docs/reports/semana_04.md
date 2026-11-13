# Relatório — Semana 4: Expansão de chave e datapath AES-128

## 1. Objetivo da semana

Implementar a expansão de chave AES-128 e o datapath que cifra e decifra um
bloco de 128 bits, com interface de controle start/done, e verificá-los com os
vetores da FIPS-197 nos dois sentidos.

**Entregável:** RTL de `minisoc_aes_key_exp` e `minisoc_aes_dp` e testbench com
os vetores do padrão.

**Critério de aceite:** cifragem e decriptação conferem com os vetores de
referência; lint sem erros.

## 2. O que foi feito

### 2.1 `minisoc_aes_key_exp` — expansão de chave pré-computada

- No `i_start`, a chave é copiada para `rk_q[0]` (ciclo de carga) e as round
  keys 1 a 10 são calculadas de forma iterativa, **uma por ciclo**.
- As **11 round keys** ficam armazenadas (11 × 128 bits) e são lidas pelo
  datapath por índice (`i_rk_idx` → `o_rk`, leitura combinacional).
- Cálculo de cada round key a partir da anterior (palavras w0..w3):
  `t = SubWord(RotWord(w3)) ⊕ {rcon, 24'h0}`, `w0' = w0 ⊕ t`,
  `w1' = w1 ⊕ w0'`, `w2' = w2 ⊕ w1'`, `w3' = w3 ⊕ w2'`.
  O SubWord usa 4 instâncias de `minisoc_aes_sbox`; o `rcon` começa em `01` e
  é multiplicado por 2 (`xtime`) a cada round key.
- **Latência:** `o_done` sobe **11 ciclos** após o `i_start` (1 de carga +
  10 round keys). `o_ready` indica que o banco contém as round keys da última
  chave carregada.

**Justificativa da escolha (pré-computada × on-the-fly):** a chave é a mesma
para todos os blocos de uma operação (até 256), então as round keys são
calculadas uma única vez; na decriptação basta lê-las em ordem inversa
(rk10 → rk0), sem agenda de chave inversa; e a lógica de expansão fica fora do
caminho crítico da rodada. O custo é a área do banco (1408 flip-flops), a ser
medida na síntese (Semana 8). A alternativa on-the-fly (128 + 128 flip-flops,
com agenda inversa para decriptar) fica registrada como opção de redução de
área.

### 2.2 `minisoc_aes_dp` — datapath iterativo

- Registrador de estado de 128 bits e lógica de rodada reutilizada, **uma
  rodada por ciclo**.
- **Ciclo de carga:** `estado = i_block ⊕ rk0` (cifra) ou `i_block ⊕ rk10`
  (decifra).
- **Rodadas 1 a 10:**
  - cifra: SubBytes → ShiftRows → MixColumns (exceto na rodada 10) →
    AddRoundKey(rk[r]);
  - decifra: InvShiftRows → InvSubBytes → AddRoundKey(rk[10−r]) →
    InvMixColumns (exceto na rodada 10).
- Um único `minisoc_aes_add_round_key` é compartilhado pelo ciclo de carga e
  pelos dois sentidos (mux na entrada).
- O índice da round key (`o_rk_idx`) é gerado pelo datapath: 0/10 na carga,
  `r` na cifra e `10 − r` na decifra.
- **Latência:** `o_done` sobe **11 ciclos** após o `i_start`; `o_block` fica
  estável até o próximo `i_start`. Um `i_start` com o datapath ocupado é
  ignorado.

As interfaces foram acrescentadas ao documento de microarquitetura (v1.1),
que também teve a latência da expansão corrigida de 10 para 11 ciclos.

### 2.3 Testbench `minisoc_aes_dp_tb`

| Verificação | Vetores |
|-------------|---------|
| 11 round keys | FIPS-197 Apêndices A.1 e C.1 |
| Cifra e decifra | FIPS-197 Apêndices B e C.1 |
| Cifra e decifra | 8 vetores (chave, plaintext, ciphertext) gerados pelo modelo de referência `tb/ref/aes128_ref.py` |
| Latência | 11 ciclos na expansão e 11 ciclos por bloco |
| `i_start` durante o processamento | ignorado (resultado inalterado) |

O modelo de referência em Python foi escrito de forma independente do RTL e
confere os ciphertexts dos Apêndices B e C.1 antes de gerar os vetores
(semente fixa, reprodutível).

**Teste de mutação:** o testbench foi executado contra cinco versões
propositalmente erradas do RTL — `rcon` inicial errado, RotWord removido,
índice da round key da decifra deslocado, MixColumns aplicado na rodada 10 e
InvMixColumns aplicado na última rodada da decifra — e falhou em todas.

## 3. Resultados

| Etapa | Resultado |
|-------|-----------|
| `minisoc_aes_sbox_tb` | <!-- preencher --> |
| `minisoc_aes_sub_shift_tb` | <!-- preencher --> |
| `minisoc_aes_round_tb` | <!-- preencher --> |
| `minisoc_aes_dp_tb` | <!-- preencher: PASS (84 verificacoes) --> |
| Lint (9 módulos de topo) | <!-- preencher --> |

## 4. Problemas encontrados

- A especificação inicial da microarquitetura previa 10 ciclos para a expansão
  de chave; o testbench mostrou que são 11 (o ciclo de carga da chave também
  conta). O documento foi corrigido.

## 5. Próximos passos (Semana 5)

- `minisoc_spi`: SPI Mode 0, quadro de 40 bits, leitura em duas transações,
  sincronização por toggle e banco de registradores (BG §5 e §6).
- `minisoc_pll_mock`: referência de 2 GHz, enable, PLL_DIV_SEL e lock
  pseudoaleatório (BG §4.1).
- Testbench de escrita/leitura de todos os registradores via SPI e do lock do
  PLL nos quatro divisores.
