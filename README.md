## Module & Interface
 
### Decoder
- currently without condition prediction

### LSB
- strictly follow the order


## Optimize
- [1] there are a lot of conditions can be merge into one wire, like popable 
- [2] some reset is useless for we can just set valid bit to 0 alternatively 
- [3] in the cycle rob_clear, we can still read instruction, which saves one cycle,
now we need at least 2 cycles to read an instruction