# Input: a diff response; $m[0]: {"<path segments joined by NUL>": line} for the spec in this branch.
# Adds `line` to every change: where its JSON Pointer is in this branch's file, or the nearest parent that is
# (a removed operation points at its path, a change behind a $ref at the $ref). null when nothing matches.
def segs: if . == "" then [] else ltrimstr("/") | split("/") | map(gsub("~1"; "/") | gsub("~0"; "~")) end;
def line_in($m): segs as $s
  | [range($s | length; 0; -1) as $n | $m[$s[0:$n] | join("\u0000")] | select(. != null)] | first // null;
.changes |= map(. + {line: (.pointer | line_in($m[0]))})
