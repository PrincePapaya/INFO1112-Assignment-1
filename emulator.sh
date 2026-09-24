# hello there.
# General Kenobi.

# take a bin file, with the -real initial input length given

binfile="$1"

# we need to track registers (of which there are four) and memory,
# for which there are 256 possibilities

# then, we take instructions from the binfile. The first n lines
# (where n is the number given by the first line, not counting the first
# line in n) are to be simply written to memory bytes in order, with 
# the second line at mem[0], third at mem[1], and so on. After the first 
# n+1 lines, we get to commands. 

# load: transfers data from a mem address to a register
# store: transfers data from a register to a mem address
# add: store register data + memory address data in register
# sub: store register data - memory address data in register
# quit: end the program
# print: echo specified register

declare -A registers=(
    ["00"]=00
    ["01"]=00
    ["10"]=00
    ["11"]=00
)