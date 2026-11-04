# Fluxo: lint (SpyGlass) + compilacao e simulacao (VCS) de todos os testbenches
#
# Uso:
#   make test                      lint de todos os modulos + todos os testbenches
#   make lint                      somente lint
#   make sim                       somente simulacao
#   make lint-<modulo>             lint de um modulo (ex.: make lint-minisoc_aes_sub_bytes)
#   make sim-<testbench>           um testbench (ex.: make sim-minisoc_aes_sbox_tb)
#   make clean                     remove os arquivos gerados
#
# Antes, carregar o ambiente Synopsys: source /Tools/synopsys-scripts/snps.sh

SHELL       := /bin/bash
.SHELLFLAGS := -o pipefail -c

VCS      = vcs
SPYGLASS = spyglass

RTL_F    = scripts/rtl.f
BUILD    = build
LOG_DIR  = docs/reports/logs

# Testbenches: tb/<nome>.sv, com modulo de topo de mesmo nome
TESTS = minisoc_aes_sbox_tb \
        minisoc_aes_sub_shift_tb \
        minisoc_aes_round_tb

# Modulos analisados pelo lint (cada um como topo)
LINT_TOPS = minisoc_aes_sub_bytes \
            minisoc_aes_inv_sub_bytes \
            minisoc_aes_shift_rows \
            minisoc_aes_inv_shift_rows \
            minisoc_aes_mix_columns \
            minisoc_aes_inv_mix_columns \
            minisoc_aes_add_round_key

LINT_TARGETS = $(addprefix lint-,$(LINT_TOPS))
SIM_TARGETS  = $(addprefix sim-,$(TESTS))

.PHONY: all check-env lint sim test clean $(LINT_TARGETS) $(SIM_TARGETS)

all: test

check-env:
	@for t in $(VCS) $(SPYGLASS); do \
		command -v $$t >/dev/null || { \
			echo "ERRO: '$$t' nao encontrado. Execute: source /Tools/synopsys-scripts/snps.sh"; \
			exit 1; }; \
	done

lint: $(LINT_TARGETS)

$(LINT_TARGETS): lint-%: check-env
	@echo "=== SpyGlass Lint: $* ==="
	@mkdir -p $(BUILD)/lint $(LOG_DIR)
	@printf 'read_file -type sourcelist $(RTL_F)\nset_option enableSV yes\nset_option top $*\n' > $(BUILD)/lint/$*.prj
	$(SPYGLASS) -batch -project $(BUILD)/lint/$*.prj -goals "lint/lint_rtl" | tee $(LOG_DIR)/lint_$*.log

sim: $(SIM_TARGETS)

$(SIM_TARGETS): sim-%: check-env
	@echo "=== VCS: $* ==="
	@mkdir -p $(BUILD)/$* $(LOG_DIR)
	$(VCS) -full64 -sverilog -f $(RTL_F) tb/$*.sv -top $* \
		-o $(BUILD)/$*/simv -Mdir=$(BUILD)/$*/csrc | tee $(LOG_DIR)/compile_$*.log
	$(BUILD)/$*/simv -no_save | tee $(LOG_DIR)/sim_$*.log

test: lint sim
	@echo "=== Fluxo concluido com sucesso ==="

clean:
	@echo "=== Cleaning generated files ==="
	rm -rf $(BUILD) csrc simv simv.daidir ucli.key
	rm -rf scripts/lint
	rm -f spyglass.out
