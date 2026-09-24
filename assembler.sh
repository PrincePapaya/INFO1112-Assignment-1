#!/bin/bash
# zero args provided
if [ $# -eq 0 ]; then
    echo -e "usage: no arg is provided\n"
    exit 1
fi
real=0
if [ "$1" == "-real" ]; then
    real=1
    shift
fi
# more than 1 arg provided
if [ $# -gt 1 ]; then
    echo -e "usage: more than one arguments are provided\n"
    exit 1
fi
# check to see if input is a file, store it as "file"
if [ -f "$1" ]; then
    file="$1"
else 
    echo -e "usage: input is not a file or it does not exist\n"
    exit 1
fi
# check to see the file ends with vsc past the period
if [[ "${file##*.}" != vsc ]]; then
    echo -e "usage: input does not have the extension .vsc\n"
    exit 1
fi
# if it is given empty.vsc, "usage: the file is empty – no .bin file is produced"
if [ ! -s "$file" ]; then
    echo -e "usage: the file is empty - no .bin file is produced\n"
    exit 1
fi

# I've done all the checks for invalid inputs now, time to actually parse the inputs
# if [[ read "$file" == 0 ]]; then
#     # this means the next line should be a QUIT line.
#     echo -e "It is a QUIT program\n"
# fi

readarray -t lines < "$file"
# I now have an array of all the lines in the file.

declare -A instructions=(
    ["LOAD"]="04"
    ["STORE"]="08"
    ["ADD"]="0C"
    ["SUB"]="10"
    ["QUIT"]="20"
    ["PRINT"]="24"
)
# this is a dictionary that can allow me to translate the instructions
# into their hex equivalents. Since the addition of the reg will shift ins 2
# to the right, I have multiplied each entry by 4.

parsecommand() {
    IFS=, read -r ins reg mem <<< "$1" 
    # use the instructions dict to turn the $ins into its corresponding hex value
    # then combine that with the register and memory address 
    # if ins is not in instructions, error and abort
    # heck, if anything wonky happens then error and abort
    if [[ -v instructions["$ins"] ]]; then output=${instructions["$ins"]}; else echo -e "invalid command $ins"; exit 1; fi
    # we now have a variable "output" containing the hex value of ins
    if [[ "$reg" =~ ^[0-9]+$ && "$reg" -gt -1 && "$reg" -lt 4 ]]; then 
        output=$(printf "%02X" $((0x$output + 0x$reg))),
    else 
        # reg is invalid, throw a fit
        echo -e "$output"
        echo -e "The reg. part of $1 is empty."
        exit 1
    fi
    #TODO read mem as a second byte of hex, append its string to output
    if [[ "$mem" =~ ^[0-9]+$ && "$mem" -gt -1 && "$mem" -lt 256 ]]; then
        output=$output$(printf "%02X" $mem)
        # a bit scuffed probably
    else 
        # mem is invalid, throw a fit
        echo -e "The mem. part of $1 is empty."
        exit 1
    fi
    #TODO return output somehow?
    echo $output
}

# now armed with the handy parsecommand, I can go through the file and... parse each command.
# afterwards, I need to print whether the file is a quit file or an add/sub file.
# the first two bin outputs of an add/sub file will simply be the variables written to memory.

# things to check for:
# file ends with quit
# quit is correct
# max char length of a line is 11
# line 1 is either a 0 or 2
# if 0, line 2 is the only other line, and it is a valid quit
# idk what else

hexcodes=""
whatline=-1
firstcommand=0
while IFS= read -r line; do
    if [[ "$whatline" -eq -1 ]]; then
        # this should either be zero or two, probably
        if [[ "$line" -eq 0 ]]; then
            # this is a quit file!
            # the second and final line better be QUIT,0,0
            if [ $real == 1 ]; then hexcodes+=$line,; fi
        elif [[ "$line" -eq 2 ]]; then
            # this is an add/sub file!
            firstcommand=2
            if [ $real == 1 ]; then hexcodes+=$line,; fi
        else 
            # dude... you messed up
            echo -e "this wasn't in the script\n"
            # I guess we can continue now, it's still an add/sub file?
            firstcommand="$line"
            if [ $real == 1 ]; then hexcodes+=$line,; fi
        fi
    else 
        # we're past the first line, but are we at the commands yet?
        if [[ "$whatline" -lt $firstcommand ]]; then
            # we're still looking at the memory adds.
            # first, convert it to hex, then add it to dataArray
            hexcodes+=$(printf "%02X" $line),
        else 
            # time to parse some commands, baybee!
            cmd=$(parsecommand "$line")
            # if we're on line 0, this should be a quit file and the output should be "20,00"
            if [[ "$whatline" -eq 0 && ! "$cmd" -eq "20,00" ]]; then echo -e "QUIT is the only valid command, you tried $line"; exit 1; fi
            # add the parsed command to dataArray
            hexcodes+=$cmd,
        fi
    fi
    # cool things go here
    whatline=$(($whatline+1))
done < "$file"

# if firstcommand is still zero, it was a quit file
# otherwise, it was an add/sub file
# do the print now, since all the possible errors have errored
# then, make the bin file and populate it with all the entries from dataArray

if [[ $firstcommand -eq 0 ]]; then echo -e "It is a QUIT program"
else echo -e "It is an ADD/SUB program"; fi

binfile="${file%.*}.bin"
rm $binfile
# echo $hexcodes
IFS=, read -r -a hexes <<< "$hexcodes"
for hex in "${hexes[@]}"; do 
    printf "\x$hex" >> $binfile
done

echo The content of the .bin file is:
for hex in "${hexes[@]}"; do 
    echo $hex
done

# regtobin() {
#     # this function is unused.
#     if [[ "$1" -eq 0 ]]; then
#         echo "00"
#     else if [[ "$1" -eq 1 ]]; then
#         echo "01"
#     else if [[ "$1" -eq 2 ]]; then
#         echo "10"
#     else if [[ "$1" -eq 3 ]]; then
#         echo "11"
#     else 
        
# }

# dectobin() {
#     numbin=""
#     tmp="$1"
#     for weight in 128 64 32 16 8 4 2 1
#     do
#         if (( $tmp >= $weight )); then
#             bit=1
#             tmp=$(($tmp - $weight))
#         else 
#             bit=0
#         fi
#         numbin="$numbin$bit"
#         #echo $bit
#     done
#     echo $numbin
#     # this code is mostly just copied from the ed
# }

# type_dec= sed '{1}q;d' "$file"
# if [ "$type_dec" =~ 0 ]; then
#     if [ sed '{2}q;d' "$file" =~ QUIT,0,0 ]; then
#         echo -e "It is a QUIT program\n"
#         exit 0
#     fi
# fi

