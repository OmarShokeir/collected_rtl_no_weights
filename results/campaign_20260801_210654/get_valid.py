import re

LOG_FILE = "whole_log.txt"
OUTPUT_FILE = "whole_correct.txt"

with open(LOG_FILE, "r", errors="ignore") as f:
    lines = f.readlines()

results = []

current_fault = None
current_signal = None

i = 0
while i < len(lines):

    line = lines[i].rstrip()

    # --------------------------------------------------
    # Detect:
    # Fault #123
    # --------------------------------------------------
    m = re.match(r"Fault #(\d+)", line)
    if m:
        current_fault = m.group(1)

        # Next non-empty line is the signal
        j = i + 1
        while j < len(lines):
            if lines[j].strip():
                current_signal = lines[j].rstrip()
                break
            j += 1

    # --------------------------------------------------
    # Check Reloading... block
    # --------------------------------------------------
    if line == "Reloading...":

        has_output = False
        j = i + 1

        while j < len(lines):

            if lines[j].strip() == "Reload finished.":
                break

            if lines[j].strip():
                has_output = True

            j += 1

        # Store only if there was output between the markers
        if has_output:
            results.append((current_fault, current_signal))

        i = j

    i += 1

# --------------------------------------------------
# Write results
# --------------------------------------------------

with open(OUTPUT_FILE, "w") as f:

    f.write(f"Found {len(results)} matching faults.\n\n")

    for fault, signal in results:
        f.write(f"Fault #{fault}\n")
        f.write(f"{signal}\n\n")

print(f"Done. Results written to '{OUTPUT_FILE}'.")