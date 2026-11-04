# Relatório — Semana 2: Desafio SubBytes e ShiftRows

## 1. Objetivo da semana

Implementar as transformações SubBytes e ShiftRows do AES como blocos
combinacionais, independentes do restante do sistema, que serão reaproveitados
no datapath (`minisoc_aes_dp`) a partir da Semana 3; e ler as seções 1 a 3 e 8
do Block Guide do MiniSoC AES (v1.0.0), registrando dúvidas e ambiguidades.

**Entregável:** RTL de `minisoc_aes_sbox`, `minisoc_aes_sub_bytes` e
`minisoc_aes_shift_rows`, testbench autoverificável e este relatório.

**Critério de aceite:** testbench executado por um único comando, com PASS nas
256 entradas da S-box e nos vetores do Apêndice B; lint sem erros.

## 2. O que foi feito

### 2.1 RTL (`rtl/minisoc_aes/`)

| Módulo | Função |
|--------|--------|
| `minisoc_aes_sbox` | S-box: 8 bits → 8 bits, tabela de 256 entradas (FIPS-197, Figura 7), combinacional |
| `minisoc_aes_sub_bytes` | SubBytes: estado de 128 bits, 16 instâncias da S-box |
| `minisoc_aes_shift_rows` | ShiftRows: estado de 128 bits, apenas reordenação de fios |
| `minisoc_aes_inv_sbox` | S-box inversa (opcional; FIPS-197, Figura 14) |
| `minisoc_aes_inv_sub_bytes` | InvSubBytes (opcional) |
| `minisoc_aes_inv_shift_rows` | InvShiftRows (opcional) |

As transformações inversas, opcionais nesta semana, já foram implementadas
porque são exigidas na Semana 3 (decriptação nos modos ECB, CBC e PCBC).

**Convenção do estado** (igual à do Block Guide, em que a Word 0 de um bloco
ocupa `[127:96]`): o byte *n* ocupa `[127-8n -: 8]` — byte 0 em `[127:120]` e
byte 15 em `[7:0]` — e corresponde a `s[r][c]`, com *r* = *n* mod 4 e
*c* = *n* div 4 (FIPS-197, seção 3.4).

**ShiftRows:** `s'[r][c] = s[r][(c + r) mod 4]`; **InvShiftRows:**
`s'[r][c] = s[r][(c − r) mod 4]`. São implementados com `generate`, sem lógica.

**S-box:** implementada como tabela (`case` de 256 entradas) em vez do cálculo
pela inversa em GF(2^8) + transformação afim. A tabela é a forma mais direta,
fácil de verificar e de sintetizar; a síntese da Semana 8 permitirá avaliar
área e timing.

### 2.2 Testbenches (`tb/`)

| Testbench | Verificações |
|-----------|--------------|
| `minisoc_aes_sbox_tb` | `sbox(x)` nas 256 entradas comparado com uma referência **calculada** (inverso em GF(2^8) + transformação afim, FIPS-197 seção 5.1.1); `inv_sbox(sbox(x)) == x` nas 256 entradas; `sbox(8'h00) = 8'h63` e `sbox(8'h53) = 8'hed` |
| `minisoc_aes_sub_shift_tb` | Apêndice B, rodadas 1, 2, 9 e 10: Start of Round → After SubBytes → After ShiftRows, e as inversas no sentido contrário; Apêndice C.1, rodadas 1 e 10: InvShiftRows e InvSubBytes |

A referência da S-box no testbench **não é uma cópia da tabela do RTL**: é
calculada pela definição matemática, de modo que um erro de digitação na tabela
seria detectado.

Ambos são autoverificáveis: contam os erros, terminam com `$fatal` se algum
caso falhar e só imprimem `PASS` quando todos passam.

### 2.3 Fluxo

O `Makefile` passou a suportar vários testbenches e módulos:

```bash
make test        # lint de todos os módulos + todos os testbenches
make sim-minisoc_aes_sbox_tb
make lint-minisoc_aes_sub_bytes
```

Os logs são gravados em `docs/reports/logs/` (`lint_<módulo>.log`,
`compile_<tb>.log`, `sim_<tb>.log`).

### 2.4 Reorganização do repositório

- `rtl/` reorganizado conforme a seção 10 do Block Guide
  (`minisoc_aes/`, `minisoc_mem/`, `minisoc_pll/`, `minisoc_spi/`).
- Removidos o exemplo mínimo da Semana 1 (`simple_and`) e a pasta `models/`
  (o PLL mock e a memória passam a ficar em `rtl/minisoc_pll/` e
  `rtl/minisoc_mem/`).
- Backlog atualizado para o cronograma de 13 semanas.

## 3. Resultados

| Etapa | Resultado |
|-------|-----------|
| `minisoc_aes_sbox_tb` | <!-- preencher: PASS (514 verificacoes) --> |
| `minisoc_aes_sub_shift_tb` | <!-- preencher: PASS (20 verificacoes) --> |
| Lint (4 módulos de topo) | <!-- preencher: 0 fatal, 0 error, 0 warning em cada --> |

Validação adicional: os testbenches foram propositalmente executados contra
versões alteradas do RTL (um byte errado na S-box e um deslocamento errado no
ShiftRows) e ambos falharam, confirmando que detectam erros.

## 4. Dúvidas e ambiguidades do Block Guide (seções 1 a 3 e 8)

### Organização (seções 1.3 e 10)

1. As transformações de rodada (`minisoc_aes_sbox`, `minisoc_aes_sub_bytes`,
   `minisoc_aes_shift_rows` etc.) não aparecem na lista de arquivos da seção
   1.3 nem na seção 10. Podem ficar como submódulos em `rtl/minisoc_aes/`, em
   arquivos próprios?

### Interfaces de topo (seção 3)

2. Qual é a latência de leitura da memória pela interface MEMORY DATA? O dado
   aparece em `mem_o_data` um ciclo de `mem_clk` após o endereço (memória
   síncrona com saída registrada)?
3. Qual é o valor de `mem_o_data` quando `MEM_SEL_AES = 1` (memória com o AES)?
   Zero, último valor lido ou indefinido?
4. A seção 7.2 indica que o clock da memória vem de `mem_clk` ou do clock do AES
   conforme `MEM_SEL_AES`. A troca exige um mux de clock sem glitch, ou um mux
   simples é suficiente, dado que a troca só ocorre com os dois lados ociosos?

### AES Engine (seção 8)

5. **CTR:** a entrada da cifra é `IV XOR {64'b0, contador}`, com o contador
   inicial em `COUNTER_HI/COUNTER_LO`? O contador dá a volta (*wrap*) após
   2^64 − 1? Os registradores COUNTER são atualizados ao fim da operação?
6. **CTR, CFB e OFB** usam apenas o primitive de cifragem. Nesses modos o bit
   `DECRYPT` define apenas o sentido do encadeamento (relevante no CFB) ou é
   ignorado?
7. **CFB:** o tamanho de segmento é de 128 bits (CFB-128)?
8. **PCBC:** a definição é a usual, `C_i = E(P_i ⊕ P_{i−1} ⊕ C_{i−1})`, com
   `P_0 ⊕ C_0` substituído pelo IV no primeiro bloco?
9. Ao fim de uma operação, os registradores IV mantêm o valor programado ou
   são atualizados com o último valor de encadeamento?
10. O que acontece com um START escrito enquanto `BUSY = 1`, com
    `MEM_SEL_AES = 0` ou com o PLL sem lock? É ignorado ou gera ERROR?
11. Em caso de ERROR, `DONE` também é sinalizado? `ERROR` é limpo no próximo
    START aceito?
12. Qual é a largura do campo NUM_BLOCKS (9 bits?) e um valor maior que 256
    gera ERROR?
13. `BLOCKS_DONE` é zerado no START ou mantém o valor da operação anterior até
    o primeiro bloco da nova operação ("operação corrente/anterior")?

### Outras seções (registradas antecipadamente)

14. **Seção 4.2:** quantos ciclos de clock do sistema o domínio deve permanecer
    em reset após a liberação do clock pelo PLL?
15. **Seção 4.1:** o número pseudoaleatório de ciclos até o lock tem faixa e
    semente definidas (para simulação reprodutível)?
16. **Seção 5:** na leitura, o valor retorna em `DATA[31:0]` da segunda
    transação? Que valor é enviado nos bits 39:32 do MISO?
17. **Seção 5/6:** comportamento em escrita a endereço não mapeado ou somente
    leitura, e se `spi_cs_n` for desativado no meio de um quadro.
18. **Seção 6:** qual é o valor do registrador `VERSION`?

## 5. Problemas encontrados

- A especificação (Block Guide) foi disponibilizada apenas no fim de outubro, o
  que atrasou o início desta entrega.
- O `Makefile` da Semana 1 suportava um único testbench; foi reescrito para
  executar vários testbenches e o lint de vários módulos.

## 6. Próximos passos (Semana 3)

- Documento de microarquitetura v1.0 (`docs/architecture/`).
- MixColumns, AddRoundKey e InvMixColumns.
- Testes unitários com o Apêndice B (cifragem) e o Apêndice C.1 (cifragem
  inversa).
- Apresentação da microarquitetura ao verificador parceiro (06/11).
