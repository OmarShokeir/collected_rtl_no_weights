# Summary: This script processes a list of true signals from an input file, 
# replaces slashes with dots, sorts them based on a custom key, 
# and writes the sorted signals to an output file.

import sys

if len(sys.argv) < 3:
    print("Usage: python3 process_true_signals.py <input> <output>")
    sys.exit(1)

inp = sys.argv[1]
out = sys.argv[2]

with open(inp, "r") as f:
    signals = [line.strip() for line in f if line.strip()]

# replace / with .
signals = [s.replace("/", ".") for s in signals]

# custom sort: ignore prefix before first "."
def sort_key(sig):
    parts = sig.split(".", 1)
    if len(parts) == 2:
        return (parts[1], parts[0])  # suffix first, then dutX
    return ("", sig)

signals_sorted = sorted(signals, key=sort_key)

with open(out, "w") as f:
    for s in signals_sorted:
        f.write(s + "\n")

print(f"Processed {len(signals_sorted)} signals → {out}")