# Fluxo mínimo: lint (SpyGlass) + compilação e simulação (VCS)
#
# Uso: make test
# Antes, carregar o ambiente Synopsys: source /Tools/synopsys-scripts/snps.sh

SHELL       := /bin/bash
.SHELLFLAGS := -o pipefail -c

VCS      = vcs
SPYGLASS = spyglass

RTL_F    = scripts/rtl.f
TB_F     = scripts/tb.f
SIMV     = simv
LOG_DIR  = docs/reports/logs

.PHONY: all check-env lint compile sim test clean

all: test

check-env:
	@for t in $(VCS) $(SPYGLASS); do \
		command -v $$t >/dev/null || { \
			echo "ERRO: '$$t' nao encontrado. Execute: source /Tools/synopsys-scripts/snps.sh"; \
			exit 1; }; \
	done

lint: check-env
	@echo "=== SpyGlass Lint ==="
	@mkdir -p $(LOG_DIR)
	$(SPYGLASS) -batch -project scripts/lint.prj -goals "lint/lint_rtl" | tee $(LOG_DIR)/lint.log

compile: check-env
	@echo "=== VCS Compile ==="
	@mkdir -p $(LOG_DIR)
	$(VCS) -full64 -sverilog -f $(RTL_F) -f $(TB_F) -o $(SIMV) | tee $(LOG_DIR)/compile.log

sim: compile
	@echo "=== VCS Simulation ==="
	./$(SIMV) -no_save | tee $(LOG_DIR)/sim.log

test: lint sim
	@echo "=== Fluxo concluido com sucesso ==="

clean:
	@echo "=== Cleaning generated files ==="
	rm -rf simv simv.daidir csrc ucli.key
	rm -rf scripts/lint
	rm -f spyglass.out
