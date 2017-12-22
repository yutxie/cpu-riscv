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

- check op(-imm)
- check stall
- check jump and branch

## questions

- delay_slot

## reference

- 自己动手写CPU by 雷思磊