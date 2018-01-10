# cpu-riscv

2017 Computer Architecture @ SJTU ACM Class - xxxxxyt

## instruction set

### special

- 1 LUI
- 2 AUIPC
- 0 FENCE
- 0 FENCE.I

### jal and branch

- 1 JAL
- 1 JALR
- 1 BEQ/BNE
- 1 BLT/BGE/BLTU/BGEU

### load and store

- 2 LB/LH/LW/LBU/LHU
- 2 SB/SH/SW

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

- branch predictor
- i-cache and d-cache
- memory manager

## questions

- branch
  - id阶段确定target → 无气泡 → unbalance
  - ex阶段确定target → control hazard(本质类load造成的间隔1拍RAW)
    - from ex forwarding to if
    - branch prediction
- `always @(*)`的敏感性
- data hazard的情况下修改pc_reg为branch_target

## reference

- 自己动手写CPU by 雷思磊