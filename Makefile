VCS      = vcs
SPYGLASS = spyglass

RTL      = rtl/simple_and.sv
TB       = tb/tb_simple_and.sv
SIMV     = simv

.PHONY: all lint compile sim test clean

all: test

lint:
	@echo "=== SpyGlass Lint ==="
	$(SPYGLASS) -batch -project scripts/lint.prj -goals "lint/lint_rtl"

compile:
	@echo "=== VCS Compile ==="
	$(VCS) -full64 -sverilog $(RTL) $(TB) -o $(SIMV)

sim: compile
	@echo "=== VCS Simulation ==="
	./$(SIMV)

test: lint sim
	@echo "=== Fluxo concluido com sucesso ==="

clean:
	@echo "=== Cleaning generated files ==="
	rm -rf simv simv.daidir csrc ucli.key
	rm -rf scripts/lint
	rm -f spyglass.out
