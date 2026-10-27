# Input: array of spec results; $breaking_level: "error", or "warning" when breaking changes don't fail the check.
# Output: workflow-command lines. GitHub shows at most 10 error and 10 warning annotations per step: the rest is
# in the report.
def esc_data: gsub("%"; "%25") | gsub("\r"; "%0D") | gsub("\n"; "%0A");
def esc_prop: esc_data | gsub(":"; "%3A") | gsub(","; "%2C");
def cmd($level; $file; $line; $title; $msg):
  "::\($level) file=\($file | esc_prop)\(if $line then ",line=\($line)" else "" end),title=\($title | esc_prop)::\($msg | esc_data)";

(
  [ .[] | .file as $f | .diff.changes[]? | select(.severity == "breaking" or .severity == "warning")
    | {level: (if .severity == "breaking" then $breaking_level else "warning" end), rank: (if .severity == "breaking" then 0 else 1 end),
       file: $f, line, title: "\(if .severity == "breaking" then "Breaking change" else "Possibly breaking" end): \(.kind)",
       msg: .message} ]
  + [ .[] | .file as $f | .validate.errors[]?
    | {level: "error", rank: 0, file: $f, line, title: "Invalid OpenAPI\(if .keyword then " (\(.keyword))" else "" end)",
       msg: "\(.message) at \(if .pointer == "" then "/" else .pointer end)"} ]
)
| sort_by(.rank)
| group_by(.level) | map(.[:10]) | flatten | sort_by(.rank)
| .[]
| cmd(.level; .file; .line; .title; .msg)
