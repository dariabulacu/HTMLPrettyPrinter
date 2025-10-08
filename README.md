# HTMLPrettyPrinter

A small shell script that formats (pretty-prints) a single-file HTML input so that each tag and text node appears on its own line and the document is properly indented. The script validates basic HTML structure (DOCTYPE check and matching opening/closing tags) and writes the formatted output to a `pretty_printer` file.

## Features

- Splits tags and text onto separate lines
- Detects and respects common self-closing tags (img, br, meta, etc.)
- Validates that the file starts with `<!DOCTYPE html>`
- Checks that opening and closing tag counts match
- Produces an indented, human-readable HTML file

## Requirements

- Bash (the script is a Bash script)
- GNU utilities: `sed`, `grep` (with PCRE support `-P`), `wc`

Notes for Windows users: this is a Bash script. On Windows run it under WSL, Git Bash (MSYS2), or any POSIX-compatible shell. `grep -P` requires GNU grep with PCRE support; macOS default grep may not support `-P`.

## Files in this repository

- `HtmlPrettyPrinter.sh` — the main shell script. Run it with one argument: the path to an HTML file. It produces a `pretty_printer` file in the repository root.
- `ceva.html` — a small example HTML input included for quick testing.
- `pretty_printer` — the script's output file (created when you run the script).
- `new_tags` — a temporary/intermediate file created by the script while processing (the script removes it when finished).
- `new_tags` and `tmp_file` are used internally by the script and are removed after a successful run.

## Usage

Basic usage from a POSIX shell:

```bash
./HtmlPrettyPrinter.sh path/to/input.html
```

Example using the included sample:

```bash
./HtmlPrettyPrinter.sh ceva.html
# -> creates ./pretty_printer with formatted HTML
```

On Windows (PowerShell), run inside WSL or Git Bash. Example using WSL:

```powershell
wsl ./HtmlPrettyPrinter.sh /mnt/c/Users/User/HTMLPrettyPrinter/ceva.html
```

Or open Git Bash in the repo folder and run the Bash command above.

## Behavior and error handling

- If no argument is given, the script will prompt for a single path interactively.
- The script verifies the file exists and is not empty.
- It checks that the first non-empty line is `<!DOCTYPE html>`; otherwise it exits with an error.
- It counts opening and closing tags (ignoring recognized self-closing tags). If counts differ, it exits with an error reporting unbalanced tags.

## Example

Given the input `ceva.html` (compact HTML):

```html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Document</title></head><body><p>Titlu</p></body></html>
```

The script produces `pretty_printer` containing a neatly indented, multiline HTML representation where tags and text are each on their own line.

## Limitations & notes

- The script uses simple text processing (sed/grep) and is not a full HTML parser. It handles many common cases but may fail on pathological or malformed HTML (scripts/styles with `>` inside strings, unusual attributes, comments, CDATA, or embedded template syntax).
- `grep -oP` (PCRE) is used; if your environment lacks `-P` support, install GNU grep or modify the script to use a different approach (e.g., Perl-based extraction).