# cpu-riscv

2017 Computer Architecture @ SJTU ACM Class by xxxxxyt

## instruction set

### special

- 1 LUI
- 0 AUIPC
- 0 FENCE
- 0 FENCE.I

### jal and branch

- 0 JAL
- 0 JALR
- 0 BEQ/BNE
- 0 BLT/BGE/BLTU/BGEU

### load and store

- 0 LB/LH/LW/LBU/LHU
- 0 SB/SH/SW

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

- 指令check
- stall check

## reference

- 自己动手写CPU by 雷思磊