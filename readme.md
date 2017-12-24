# cpu-riscv

2017 Computer Architecture @ SJTU ACM Class by xxxxxyt

## instruction set

### special

- 1 LUI
- 0 AUIPC
- 0 FENCE
- 0 FENCE.I

### jal and branch

- 1 JAL
- 1 JALR
- 1 BEQ/BNE
- 1 BLT/BGE/BLTU/BGEU

### load and store

- 1 LB/LH/LW/LBU/LHU
- 1 SB/SH/SW

### imm-op

- 1 ADDI
- 2 SLTI/SLTIU
- 1 XORI
- 2 ORI/ANDI
- 2 SLLI/SRLI/SRAI

### op

- 2 ADD/SUB
- 2 SLT/SLTU
- 1 XOR/AND
- 2 AND
- 1 SLL/SRL/SRA

## to-do

- check op(-imm)
- check stall
- check jump and branch
- check load and store
- branch predictor
- i-cache and d-cache
- memory manager

## questions

- delay_slot
- branch
  - id阶段确定target → 无气泡 → unbalance
  - ex阶段确定target → control hazard(本质类load造成的间隔1拍RAW)
    - from ex forwarding to if
    - branch prediction

## reference

- 自己动手写CPU by 雷思磊