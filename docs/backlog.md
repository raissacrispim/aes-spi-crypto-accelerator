# Backlog — AES SPI Crypto Accelerator

## Semana 1 — Setup e Planejamento

- [x] Criar estrutura inicial do repositório.
- [x] Configurar ambiente Synopsys.
- [x] Validar compilação SystemVerilog com VCS.
- [x] Validar simulação com VCS.
- [x] Configurar lint com SpyGlass.
- [x] Criar fluxo automatizado com Makefile.
- [x] Documentar ambiente e execução no README.
- [x] Estudar fundamentos do AES.
- [x] Estudar protocolo SPI.
- [x] Elaborar relatório da Semana 1.

## Semana 2 — Especificação e Arquitetura

- [ ] Definir requisitos funcionais.
- [ ] Definir mapa de registradores.
- [ ] Definir protocolo de comandos SPI.
- [ ] Definir arquitetura de alto nível.
- [ ] Definir interfaces entre blocos.
- [ ] Documentar decisões arquiteturais.

## Semanas 3–4 — Interface SPI

- [ ] Implementar SPI slave.
- [ ] Implementar recepção de comandos.
- [ ] Implementar transmissão de respostas.
- [ ] Desenvolver testbench da interface SPI.
- [ ] Executar lint e simulação.
- [ ] Integrar interface SPI ao banco de registradores.

## Semanas 5–6 — AES Core

- [ ] Implementar datapath AES.
- [ ] Implementar controle do AES.
- [ ] Implementar expansão de chave.
- [ ] Criar testes com vetores conhecidos.
- [ ] Executar lint e simulação do AES.
- [ ] Integrar AES ao banco de registradores.

## Semana 7 — Integração

- [ ] Integrar SPI, banco de registradores e AES.
- [ ] Implementar sinais de controle e status.
- [ ] Executar testes end-to-end.
- [ ] Corrigir problemas de integração.

## Semanas 8–9 — Síntese e Verificação

- [ ] Preparar scripts de síntese.
- [ ] Executar síntese lógica.
- [ ] Analisar área.
- [ ] Analisar timing.
- [ ] Executar verificações formais previstas.
- [ ] Corrigir problemas encontrados.

## Semanas 10–14 — Low Power

- [ ] Definir estratégia de baixo consumo.
- [ ] Desenvolver especificação UPF.
- [ ] Implementar mecanismos de controle de potência.
- [ ] Aplicar técnicas de low power previstas.
- [ ] Verificar comportamento funcional com low power.
- [ ] Avaliar impacto em área, timing e potência.

## Semana 15 — Fechamento

- [ ] Executar regressão final.
- [ ] Consolidar resultados.
- [ ] Organizar documentação.
- [ ] Revisar scripts e reprodutibilidade do fluxo.
- [ ] Preparar entrega final.
