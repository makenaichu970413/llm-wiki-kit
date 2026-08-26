#!/usr/bin/env bash
# dashboard.sh - compute vault stats from disk and render wiki/dashboard.html.
# Usage: ./scripts/dashboard.sh   (or bind it to a cron job)
# Requires: jq (only used if wiki-state.json / code-sync is present). Run from anywhere;
# paths resolve from this script's location. Read-only: never writes to log.md/index.md.
# Written portably (indexed arrays only, no bash-4-only associative arrays/mapfile) so it
# also runs under macOS's default bash 3.2, not just a modern bash.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vault="$(dirname "$script_dir")"
wiki_dir="$vault/wiki"
state_path="$vault/wiki-state.json"
template_path="$vault/scripts/dashboard.template.html"
out_path="$wiki_dir/dashboard.html"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

html_escape() {
    printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# --- Project name (best-effort: from CLAUDE.md's title line, else the folder name) ---
project_name="$(basename "$vault")"
claude_md_path="$vault/CLAUDE.md"
if [[ -f "$claude_md_path" ]]; then
    title_line="$(grep -m1 -E '^# .+ — LLM Wiki Schema' "$claude_md_path" || true)"
    if [[ -n "$title_line" ]]; then
        project_name="$(printf '%s' "$title_line" | sed -E 's/^# (.+) — LLM Wiki Schema.*$/\1/')"
    fi
fi

# --- Installed modules ---
is_code_sync=0
if [[ -f "$state_path" ]]; then is_code_sync=1; fi
is_decisions=0
if [[ -d "$wiki_dir/decisions" ]]; then is_decisions=1; fi
is_roadmap=0
if [[ -f "$wiki_dir/plan.md" ]]; then is_roadmap=1; fi
is_tickets=0
if [[ -d "$wiki_dir/tickets" ]]; then is_tickets=1; fi

# --- Log stats ---
log_path="$wiki_dir/log.md"
total_entries=0
archived_count=0
op_names=()     # unique ops, in order of first appearance (mirrors dashboard.ps1's ordered map)
op_counts_arr=()
entries=()          # "date<TAB>op<TAB>archived<TAB>subject"
query_subjects=()
answer_subjects=()

increment_op() {
    local op="$1" i
    for i in "${!op_names[@]}"; do
        if [[ "${op_names[$i]}" == "$op" ]]; then
            op_counts_arr[$i]=$((op_counts_arr[$i] + 1))
            return
        fi
    done
    op_names+=("$op")
    op_counts_arr+=(1)
}

if [[ -f "$log_path" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^##\ \[([0-9]{4}-[0-9]{2}-[0-9]{2})\]\ ([^ ]+)\ \|\ (.*)$ ]]; then
            date="${BASH_REMATCH[1]}"
            op="${BASH_REMATCH[2]}"
            subject="${BASH_REMATCH[3]}"
            archived=0
            if [[ "$subject" =~ ^(.*)\ —\ ⚠️\ Archived\ [0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*$ ]]; then
                archived=1
                subject="${BASH_REMATCH[1]}"
                archived_count=$((archived_count + 1))
            fi
            total_entries=$((total_entries + 1))
            increment_op "$op"
            entries+=("$date"$'\t'"$op"$'\t'"$archived"$'\t'"$subject")

            normalized="$(printf '%s' "$subject" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            normalized="${normalized%\"}"
            normalized="${normalized#\"}"
            normalized_lc="$(printf '%s' "$normalized" | tr '[:upper:]' '[:lower:]')"
            if [[ "$op" == "query" ]]; then
                query_subjects+=("$normalized_lc")
            elif [[ "$op" == "answer" ]]; then
                answer_subjects+=("$normalized_lc")
            fi
        fi
    done < "$log_path"
fi

matched_answers=0
for q in "${query_subjects[@]:-}"; do
    [[ -z "$q" ]] && continue
    for a in "${answer_subjects[@]:-}"; do
        if [[ "$q" == "$a" ]]; then
            matched_answers=$((matched_answers + 1))
            break
        fi
    done
done
conversion_ratio="$matched_answers/${#query_subjects[@]}"

# last 10 entries, most recent first
recent=()
entry_count=${#entries[@]}
start=0
if (( entry_count > 10 )); then start=$((entry_count - 10)); fi
for (( i = entry_count - 1; i >= start; i-- )); do
    recent+=("${entries[$i]}")
done

# --- Health check: wikilinks, red links, orphans, superseded ---
tmp_targets="$tmp_dir/targets.txt"
tmp_pagenames="$tmp_dir/pagenames.txt"
tmp_target_counts="$tmp_dir/target_counts.txt"
tmp_pageinfo="$tmp_dir/pageinfo.txt"     # id<TAB>label<TAB>group, for the knowledge-graph nodes
tmp_edges_raw="$tmp_dir/edges_raw.txt"   # source<TAB>target, undeduped
: > "$tmp_targets"
: > "$tmp_pagenames"
: > "$tmp_pageinfo"
: > "$tmp_edges_raw"

superseded_count=0
if [[ -d "$wiki_dir" ]]; then
    md_files=()
    while IFS= read -r -d '' f; do md_files+=("$f"); done < <(find "$wiki_dir" -type f -name '*.md' -print0)
    md_files_sorted=()
    while IFS= read -r f; do md_files_sorted+=("$f"); done < <(printf '%s\n' "${md_files[@]}" | LC_ALL=C sort)

    for f in "${md_files_sorted[@]}"; do
        base="$(basename "$f" .md)"
        id_lc="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
        printf '%s\n' "$id_lc" >> "$tmp_pagenames"

        rel="${f#"$wiki_dir"/}"
        group="root"
        case "$rel" in
            */*) group="${rel%%/*}" ;;
        esac
        printf '%s\t%s\t%s\n' "$id_lc" "$base" "$group" >> "$tmp_pageinfo"

        superseded_matches="$(grep -o '⚠️ Superseded' "$f" 2>/dev/null | wc -l | tr -d ' ')" || true
        superseded_count=$((superseded_count + superseded_matches))
        file_targets="$(grep -ohE '\[\[[^]|#]+' "$f" 2>/dev/null | sed -e 's/^\[\[//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')" || true
        if [[ -n "$file_targets" ]]; then
            printf '%s\n' "$file_targets" >> "$tmp_targets"
            while IFS= read -r target; do
                [[ -z "$target" || "$target" == "$id_lc" ]] && continue
                printf '%s\t%s\n' "$id_lc" "$target" >> "$tmp_edges_raw"
            done <<< "$file_targets"
        fi
    done
fi

sort "$tmp_pagenames" -o "$tmp_pagenames"
if [[ -s "$tmp_targets" ]]; then
    sort "$tmp_targets" | uniq -c | sort -rn > "$tmp_target_counts"
else
    : > "$tmp_target_counts"
fi

# mention counts per target, as parallel arrays (mirrors dashboard.ps1's $linkMentions) -
# used both for red-link detection above and node degree in the knowledge graph below.
target_names=()
target_counts_arr=()
if [[ -s "$tmp_target_counts" ]]; then
    while read -r cnt tgt; do
        [[ -z "$tgt" ]] && continue
        target_names+=("$tgt")
        target_counts_arr+=("$cnt")
    done < "$tmp_target_counts"
fi

get_mention_count() {
    local target="$1" i
    for i in "${!target_names[@]}"; do
        if [[ "${target_names[$i]}" == "$target" ]]; then
            echo "${target_counts_arr[$i]}"
            return
        fi
    done
    echo 0
}

# knowledge-graph edges: dedupe unordered pairs, keep only edges between two real pages
tmp_edges="$tmp_dir/edges.txt"
: > "$tmp_edges"
if [[ -s "$tmp_edges_raw" ]]; then
    while IFS=$'\t' read -r e_src e_tgt; do
        [[ -z "$e_src" || -z "$e_tgt" ]] && continue
        grep -Fxq "$e_tgt" "$tmp_pagenames" 2>/dev/null || continue
        if [[ "$e_src" < "$e_tgt" ]]; then
            printf '%s\t%s\n' "$e_src" "$e_tgt" >> "$tmp_edges"
        else
            printf '%s\t%s\n' "$e_tgt" "$e_src" >> "$tmp_edges"
        fi
    done < "$tmp_edges_raw"
    LC_ALL=C sort -u "$tmp_edges" -o "$tmp_edges"
fi

red_links=()       # "count<TAB>target"
overdue_red_links=0
if [[ -s "$tmp_target_counts" ]]; then
    while read -r count target; do
        [[ -z "$target" ]] && continue
        if ! grep -Fxq "$target" "$tmp_pagenames" 2>/dev/null; then
            red_links+=("$count"$'\t'"$target")
            if (( count >= 3 )); then overdue_red_links=$((overdue_red_links + 1)); fi
        fi
    done < "$tmp_target_counts"
fi

orphans=()
if [[ -s "$tmp_pagenames" ]]; then
    while read -r name; do
        [[ -z "$name" ]] && continue
        case "$name" in overview|index|log|question) continue;; esac
        if ! grep -Fxq "$name" "$tmp_targets" 2>/dev/null; then
            orphans+=("$name")
        fi
    done < <(sort -u "$tmp_pagenames")
fi

# --- Health banner rollup ---
if (( overdue_red_links > 0 )); then
    health_emoji="🔴"
    health_text="$overdue_red_links red link(s) at or above the ≥3-mention threshold - worth filling"
elif (( ${#red_links[@]} > 0 || ${#orphans[@]} > 0 )); then
    health_emoji="🟡"
    parts=()
    (( ${#red_links[@]} > 0 )) && parts+=("${#red_links[@]} red link(s)")
    (( ${#orphans[@]} > 0 )) && parts+=("${#orphans[@]} orphan page(s)")
    health_text="$(IFS=', '; echo "${parts[*]}")"
else
    health_emoji="🟢"
    health_text="No red links or orphan pages"
fi

# --- Sync status (code-sync only) ---
sync_card_file="$tmp_dir/sync_card.html"
: > "$sync_card_file"
if (( is_code_sync )); then
    repo="$(jq -r '.project_repo' "$state_path")"
    branch="$(jq -r '.branch' "$state_path")"
    last_synced="$(jq -r '.last_synced_sha' "$state_path")"
    if [[ "$repo" != /* ]]; then repo="$vault/$repo"; fi

    sync_rows=""
    if [[ -d "$repo" ]]; then
        repo="$(cd "$repo" && pwd)"
        fetch_warning=""
        if ! git -C "$repo" fetch origin 2>/dev/null; then
            fetch_warning='<div class="muted">warning: git fetch failed - using locally-cached ref</div>'
        fi
        head="$(git -C "$repo" rev-parse "origin/$branch" 2>/dev/null || true)"
        if [[ "$last_synced" == "null" ]]; then
            sync_rows='<div class="stat-row"><span>status</span><span class="n">not bootstrapped yet</span></div>'
        elif [[ -n "$head" ]]; then
            short_last="${last_synced:0:8}"
            short_head="${head:0:8}"
            behind="$(git -C "$repo" rev-list --count "$last_synced..$head" 2>/dev/null || echo "?")"
            # wiki-state.json stores no sync-run timestamp, so show the commit date of
            # last_synced_sha instead: "the wiki covers the code as of this moment".
            synced_up_to_row=""
            synced_up_to="$(git -C "$repo" show -s --format=%cd --date=format:'%Y-%m-%d %H:%M' "$last_synced" 2>/dev/null || true)"
            if [[ -n "$synced_up_to" ]]; then
                synced_up_to_row="<div class=\"stat-row\"><span>synced up to</span><span class=\"n\">$synced_up_to</span></div>"
            fi
            head_date_row=""
            head_date="$(git -C "$repo" show -s --format=%cd --date=format:'%Y-%m-%d %H:%M' "$head" 2>/dev/null || true)"
            if [[ -n "$head_date" ]]; then
                head_date_row="<div class=\"stat-row\"><span>latest commit</span><span class=\"n\">$head_date</span></div>"
            fi
            sync_rows="<div class=\"stat-row\"><span>branch</span><span class=\"n\"><code>origin/$(html_escape "$branch")</code></span></div>
<div class=\"stat-row\"><span>last_synced_sha</span><span class=\"n\"><code>$short_last</code></span></div>
$synced_up_to_row
<div class=\"stat-row\"><span>remote head</span><span class=\"n\"><code>$short_head</code></span></div>
$head_date_row
<div class=\"stat-row\"><span>commits behind</span><span class=\"n\">$behind</span></div>
$fetch_warning"
        fi
    else
        sync_rows='<div class="stat-row"><span class="muted">project_repo not found on disk</span></div>'
    fi

    cat > "$sync_card_file" <<EOF
<div class="card">
  <h2>🔄 Sync status</h2>
  $sync_rows
</div>
EOF
fi

# --- Log stats card ---
log_stats_card_file="$tmp_dir/log_stats_card.html"
op_rows=""
for i in "${!op_names[@]}"; do
    op_rows="$op_rows<div class=\"stat-row\"><span>${op_names[$i]}</span><span class=\"n\">${op_counts_arr[$i]}</span></div>"$'\n'
done

cat > "$log_stats_card_file" <<EOF
<div class="card">
  <h2>📊 Log stats</h2>
  <div class="stat-row"><span>total entries</span><span class="n">$total_entries</span></div>
  $op_rows
  <div class="stat-row"><span>archived</span><span class="n">$archived_count</span></div>
  <div class="stat-row"><span>query &rarr; answer conversion</span><span class="n">$conversion_ratio</span></div>
</div>
EOF

# --- Recent activity card ---
recent_card_file="$tmp_dir/recent_card.html"
recent_items=""
if (( ${#recent[@]} == 0 )); then
    recent_items='<li class="empty">no log entries yet</li>'
else
    for rec in "${recent[@]}"; do
        IFS=$'\t' read -r r_date r_op r_archived r_subject <<< "$rec"
        tag=""
        if [[ "$r_archived" == "1" ]]; then tag=' <span class="muted">(archived)</span>'; fi
        recent_items="$recent_items<li><code>[$r_date] $(html_escape "$r_op")</code> &mdash; $(html_escape "$r_subject")$tag</li>"$'\n'
    done
fi
cat > "$recent_card_file" <<EOF
<div class="card wide">
  <h2>🕒 Recent activity</h2>
  <ul class="plain">
  $recent_items
  </ul>
</div>
EOF

# --- Health card ---
health_card_file="$tmp_dir/health_card.html"
red_links_html=""
if (( ${#red_links[@]} == 0 )); then
    red_links_html='<li class="empty">none</li>'
else
    for rl in "${red_links[@]}"; do
        IFS=$'\t' read -r rl_count rl_target <<< "$rl"
        if (( rl_count >= 3 )); then
            red_links_html="$red_links_html<li class=\"overdue\"><span class=\"redlink\">&#9888; [[$(html_escape "$rl_target")]]</span><span class=\"overdue-flag\">overdue</span><span class=\"mentions\">$rl_count</span></li>"$'\n'
        else
            red_links_html="$red_links_html<li><span class=\"redlink\">[[$(html_escape "$rl_target")]]</span><span class=\"mentions\">$rl_count</span></li>"$'\n'
        fi
    done
fi
orphans_html=""
if (( ${#orphans[@]} == 0 )); then
    orphans_html='<li class="empty">none</li>'
else
    for o in "${orphans[@]}"; do
        orphans_html="$orphans_html<li>$(html_escape "$o")</li>"$'\n'
    done
fi
health_state_class=""
if (( overdue_red_links > 0 )); then
    health_state_class=" state-danger"
elif (( ${#red_links[@]} > 0 || ${#orphans[@]} > 0 )); then
    health_state_class=" state-warn"
fi
cat > "$health_card_file" <<EOF
<div class="card wide$health_state_class">
  <h2>🩺 Health check</h2>
  <table>
    <tr><th>Missing pages <span class="th-count">(red links &middot; ${#red_links[@]})</span></th><th>Orphan pages <span class="th-count">(${#orphans[@]})</span></th></tr>
    <tr>
      <td><ul class="plain redlinks">$red_links_html</ul></td>
      <td><ul class="plain">$orphans_html</ul></td>
    </tr>
  </table>
  <div class="stat-row"><span>⚠️ Superseded markers (history annotations, informational)</span><span class="n">$superseded_count</span></div>
</div>
EOF

# --- Knowledge graph data + card ---
graph_data_file="$tmp_dir/graph_data.js"
graph_card_file="$tmp_dir/graph_card.html"

graph_nodes_json=""
node_count=0
if [[ -s "$tmp_pageinfo" ]]; then
    while IFS=$'\t' read -r p_id p_label p_group; do
        [[ -z "$p_id" ]] && continue
        deg="$(get_mention_count "$p_id")"
        node_json="{\"id\":\"$(json_escape "$p_id")\",\"label\":\"$(json_escape "$p_label")\",\"group\":\"$(json_escape "$p_group")\",\"degree\":$deg}"
        if (( node_count == 0 )); then graph_nodes_json="$node_json"; else graph_nodes_json="$graph_nodes_json,$node_json"; fi
        node_count=$((node_count + 1))
    done < "$tmp_pageinfo"
fi

graph_edges_json=""
edge_count=0
if [[ -s "$tmp_edges" ]]; then
    while IFS=$'\t' read -r e_a e_b; do
        [[ -z "$e_a" || -z "$e_b" ]] && continue
        edge_json="{\"source\":\"$(json_escape "$e_a")\",\"target\":\"$(json_escape "$e_b")\"}"
        if (( edge_count == 0 )); then graph_edges_json="$edge_json"; else graph_edges_json="$graph_edges_json,$edge_json"; fi
        edge_count=$((edge_count + 1))
    done < "$tmp_edges"
fi

printf 'const graphData = {"nodes":[%s],"edges":[%s]};\n' "$graph_nodes_json" "$graph_edges_json" > "$graph_data_file"

cat > "$graph_card_file" <<'EOF'
<div class="card wide graph-card">
  <h2>🕸️ Knowledge graph</h2>
  <div class="graph-controls muted">drag nodes &middot; scroll to zoom &middot; drag background to pan &middot; double-click to reset</div>
  <div id="graph-legend" class="graph-legend"></div>
  <canvas id="graph-canvas"></canvas>
</div>
EOF

# --- Installed modules card ---
modules_card_file="$tmp_dir/modules_card.html"
modules_html="<li>dashboard</li>"
if (( is_code_sync )); then modules_html="<li>code-sync</li>$modules_html"; fi
if (( is_decisions )); then modules_html="$modules_html<li>decisions</li>"; fi
if (( is_roadmap )); then modules_html="$modules_html<li>roadmap</li>"; fi
if (( is_tickets )); then modules_html="$modules_html<li>tickets</li>"; fi
cat > "$modules_card_file" <<EOF
<div class="card">
  <h2>🧩 Installed modules</h2>
  <ul class="plain">$modules_html</ul>
</div>
EOF

# --- Daily Use buttons card ---
buttons_card_file="$tmp_dir/buttons_card.html"
buttons_html='<button class="copy-btn" data-copy="process it">process it</button>
<button class="copy-btn" data-copy="archive this">archive this</button>
<button class="copy-btn" data-copy="run lint">run lint</button>'
if (( is_code_sync )); then
    buttons_html="$buttons_html
<button class=\"copy-btn\" data-copy=\"run sync\">run sync</button>
<button class=\"copy-btn\" data-copy=\"set commit noise\">set commit noise</button>"
fi
if (( is_decisions )); then
    buttons_html="$buttons_html
<button class=\"copy-btn\" data-copy=\"record decision\">record decision</button>"
fi
if (( is_tickets )); then
    buttons_html="$buttons_html
<button class=\"copy-btn\" data-copy=\"create ticket\">create ticket</button>"
fi
cat > "$buttons_card_file" <<EOF
<div class="card">
  <h2>📋 Daily Use</h2>
  $buttons_html
  <div class="muted" style="margin-top:8px;">Click to copy a trigger phrase, then paste it into a Claude Code chat inside the vault. Query has no fixed phrase &mdash; just ask.</div>
</div>
EOF

# --- Assemble ---
generated_at="$(date '+%Y-%m-%d %H:%M')"
project_name_esc="$(html_escape "$project_name")"

mkdir -p "$wiki_dir"

awk -v project_name="$project_name_esc" -v generated_at="$generated_at" -v health_banner="$health_emoji $health_text" \
    -v sync_f="$sync_card_file" -v log_f="$log_stats_card_file" -v recent_f="$recent_card_file" \
    -v health_f="$health_card_file" -v graph_card_f="$graph_card_file" -v graph_data_f="$graph_data_file" \
    -v modules_f="$modules_card_file" -v buttons_f="$buttons_card_file" '
function print_file(f,    l) { while ((getline l < f) > 0) print l; close(f) }
function replace_token(line, token, value,    idx, result) {
  idx = index(line, token)
  if (idx == 0) return line
  return substr(line, 1, idx - 1) value substr(line, idx + length(token))
}
{
  line = $0
  if (line == "%%SYNC_CARD%%")            { print_file(sync_f); next }
  if (line == "%%LOG_STATS_CARD%%")       { print_file(log_f); next }
  if (line == "%%RECENT_ACTIVITY_CARD%%") { print_file(recent_f); next }
  if (line == "%%HEALTH_CARD%%")          { print_file(health_f); next }
  if (line == "%%GRAPH_CARD%%")           { print_file(graph_card_f); next }
  if (line == "%%GRAPH_DATA%%")           { print_file(graph_data_f); next }
  if (line == "%%MODULES_CARD%%")         { print_file(modules_f); next }
  if (line == "%%BUTTONS_CARD%%")         { print_file(buttons_f); next }
  line = replace_token(line, "%%PROJECT_NAME%%", project_name)
  line = replace_token(line, "%%GENERATED_AT%%", generated_at)
  line = replace_token(line, "%%HEALTH_BANNER%%", health_banner)
  print line
}
' "$template_path" > "$out_path"

echo "Dashboard written to $out_path"
echo "Health: $health_emoji $health_text"
echo "Log entries: $total_entries (archived: $archived_count, query->answer: $conversion_ratio)"
if (( ${#red_links[@]} > 0 )); then echo "Red links: ${#red_links[@]} (overdue: $overdue_red_links)"; fi
if (( ${#orphans[@]} > 0 )); then echo "Orphan pages: ${#orphans[@]}"; fi
echo "Knowledge graph: $node_count node(s), $edge_count edge(s)"

if command -v open >/dev/null 2>&1; then
    open "$out_path" 2>/dev/null || true
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$out_path" 2>/dev/null || true
else
    echo "Warning: could not open the dashboard automatically - open $out_path manually." >&2
fi
