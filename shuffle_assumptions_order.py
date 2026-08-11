import random
import re

INPUT_FILE = "assumptions_template.sv"
OUTPUT_FILE = "assumptions.sv"

with open(INPUT_FILE, "r") as f:
    lines = f.readlines()

header = []
comparisons = []
footer = []

i = 0

# Copy everything before assumptions =
while i < len(lines):
    header.append(lines[i])
    if "assumptions =" in lines[i]:
        i += 1
        break
    i += 1

# Read comparison pairs
while i < len(lines):
    if lines[i].strip().startswith("endfunction"):
        footer = lines[i:]
        break

    if i + 1 >= len(lines):
        break

    pair = [lines[i], lines[i + 1]]
    comparisons.append(pair)
    i += 2

# Fix the last comparison so it ends with ';'
last_pair = comparisons[-1]
last_pair[1] = re.sub(r"&&\s*$", ";", last_pair[1])

# Shuffle comparison pairs
random.shuffle(comparisons)

# Restore correct terminators
for idx, pair in enumerate(comparisons):
    if idx == len(comparisons) - 1:
        pair[1] = re.sub(r"&&\s*$", ";", pair[1])
    else:
        pair[1] = re.sub(r";\s*$", " &&\n", pair[1])

with open(OUTPUT_FILE, "w") as f:
    f.writelines(header)
    for pair in comparisons:
        f.writelines(pair)
    f.writelines(footer)

print(f"Shuffled {len(comparisons)} comparisons into {OUTPUT_FILE}")