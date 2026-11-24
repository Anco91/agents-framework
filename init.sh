#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
FRAMEWORK_DIR="$SCRIPT_DIR/framework"
START_MARKER='<!-- agents-fw:start -->'
END_MARKER='<!-- agents-fw:end -->'
PROJECT=''
MANIFEST_TMP=''
HOSTS=''
OLD_HOSTS=''
NORMALIZED_HOSTS=''
HOSTS_SPECIFIED=0
HOST_STAGE_DIR=''
APPLY=0
ADOPT_ITEMS=''

error() {
  printf '%s\n' "$*" >&2
}

usage() {
  error "usage: init.sh install|update <project> [--force] [--host <list>] | init.sh adopt <project> [--host <list>] [--apply] | init.sh hosts"
}

normalize_host_list() {
  host_input=$1
  normalized_hosts=''
  [ -n "$host_input" ] || return 1
  remaining_hosts=$host_input
  while :; do
    host_name=${remaining_hosts%%,*}
    case "$host_name" in
      claude|kilo|aider|skills) ;;
      *) return 1 ;;
    esac
    case " $normalized_hosts " in
      *" $host_name "*) return 1 ;;
    esac
    if [ -n "$normalized_hosts" ]; then
      normalized_hosts="$normalized_hosts $host_name"
    else
      normalized_hosts=$host_name
    fi
    [ "$remaining_hosts" != "$host_name" ] || break
    remaining_hosts=${remaining_hosts#*,}
  done
  NORMALIZED_HOSTS=$normalized_hosts
}

host_is_selected() {
  case " $HOSTS " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

host_list_csv() {
  csv_hosts=''
  remaining_hosts=$HOSTS
  while [ -n "$remaining_hosts" ]; do
    host_name=${remaining_hosts%% *}
    if [ -n "$csv_hosts" ]; then
      csv_hosts="$csv_hosts,$host_name"
    else
      csv_hosts=$host_name
    fi
    [ "$remaining_hosts" != "$host_name" ] || break
    remaining_hosts=${remaining_hosts#* }
  done
  printf '%s\n' "$csv_hosts"
}

extract_procedure_description() {
  awk '
    /^Use when: / {
      value = substr($0, 11)
      sub(/\. Role:.*/, "", value)
      print value
      found = 1
      exit
    }
    END { if (!found) exit 1 }
  ' "$1"
}

sha256() {
  file=$1
  [ -r "$file" ] || {
    error "cannot read file: $file"
    return 1
  }
  if command -v sha256sum >/dev/null 2>&1; then
    result=$(sha256sum "$file" 2>/dev/null) || {
      error "cannot hash file: $file"
      return 1
    }
  elif command -v shasum >/dev/null 2>&1; then
    result=$(shasum -a 256 "$file" 2>/dev/null) || {
      error "cannot hash file: $file"
      return 1
    }
  else
    error "sha256sum or shasum is required"
    return 1
  fi
  printf '%s\n' "${result%% *}"
}

resolve_project() {
  project_arg=$1
  [ -n "$project_arg" ] || {
    error "project path is required"
    return 1
  }
  [ -d "$project_arg" ] || {
    error "project directory does not exist: $project_arg"
    return 1
  }
  PROJECT=$(CDPATH='' cd -- "$project_arg" 2>/dev/null && pwd -P) || {
    error "cannot resolve project directory: $project_arg"
    return 1
  }
  home_path=''
  if [ -d "${HOME:-}" ]; then
    home_path=$(CDPATH='' cd -- "$HOME" 2>/dev/null && pwd -P) || home_path=''
  fi
  if [ "$PROJECT" = '/' ] || { [ -n "$home_path" ] && [ "$PROJECT" = "$home_path" ]; }; then
    error "refusing unsafe project directory: $PROJECT"
    return 1
  fi
}

safe_relative_path() {
  case "$1" in
    ''|/*|..|../*|*/..|*/../*) return 1 ;;
  esac
  return 0
}

check_path_links() {
  relative_path=$1
  current_path=$PROJECT
  remaining_path=$relative_path
  while [ -n "$remaining_path" ]; do
    component=${remaining_path%%/*}
    if [ "$remaining_path" = "$component" ]; then
      remaining_path=''
    else
      remaining_path=${remaining_path#*/}
    fi
    current_path="$current_path/$component"
    if [ -L "$current_path" ]; then
      error "refusing symlinked project path: $relative_path"
      return 1
    fi
  done
}

list_framework_pairs() {
  find "$FRAMEWORK_DIR" -type f -print 2>/dev/null | LC_ALL=C sort |
    while IFS= read -r source_file; do
      relative_file=${source_file#"$FRAMEWORK_DIR"/}
      printf '%s\t.agents-fw/%s\n' "$source_file" "$relative_file"
    done
}

list_static_host_pairs() {
  remaining_hosts=$HOSTS
  while [ -n "$remaining_hosts" ]; do
    host_name=${remaining_hosts%% *}
    case "$host_name" in
      claude)
        printf '%s\tCLAUDE.md\n' "$SCRIPT_DIR/adapters/claude/CLAUDE.md"
        for claude_agent in agents-fw-executor agents-fw-executor-small agents-fw-reviewer agents-fw-pm; do
          printf '%s\t.claude/agents/%s.md\n' "$SCRIPT_DIR/adapters/claude/agents/$claude_agent.md" "$claude_agent"
        done
        printf '%s\t.agents-fw/adapters/claude/settings.example.json\n' "$SCRIPT_DIR/adapters/claude/settings.example.json"
        printf '%s\t.agents-fw/adapters/claude/mcp.example.json\n' "$SCRIPT_DIR/adapters/claude/mcp.example.json"
        ;;
      kilo)
        printf '%s\t.kilo/agents/agents-fw-advisor.md\n' "$SCRIPT_DIR/adapters/kilo/agents-fw-advisor.md"
        printf '%s\t.kilo/agents/agents-fw-executor.md\n' "$SCRIPT_DIR/adapters/kilo/agents-fw-executor.md"
        printf '%s\t.agents-fw/adapters/kilo/kilo.jsonc.example\n' "$SCRIPT_DIR/adapters/kilo/kilo.jsonc.example"
        ;;
      aider)
        printf '%s\t.aider.conf.yml\n' "$SCRIPT_DIR/adapters/aider/.aider.conf.yml"
        ;;
    esac
    [ "$remaining_hosts" != "$host_name" ] || break
    remaining_hosts=${remaining_hosts#* }
  done
}

list_host_pairs() {
  list_static_host_pairs
  if host_is_selected skills; then
    while IFS= read -r source_file; do
      relative_file=${source_file#"$HOST_STAGE_DIR"/}
      printf '%s\t.agents/%s\n' "$source_file" "$relative_file"
    done < <(find "$HOST_STAGE_DIR/skills" -type f -name SKILL.md -print 2>/dev/null | LC_ALL=C sort)
  fi
}

list_managed_pairs() {
  {
    list_framework_pairs
    list_host_pairs
  } | LC_ALL=C sort -t "$(printf '\t')" -k 2,2
}

print_hosts() {
  printf 'claude: CLAUDE.md, .claude/agents/agents-fw-executor.md, .claude/agents/agents-fw-executor-small.md, .claude/agents/agents-fw-reviewer.md, .claude/agents/agents-fw-pm.md, .agents-fw/adapters/claude/settings.example.json, .agents-fw/adapters/claude/mcp.example.json\n'
  printf 'kilo: .kilo/agents/agents-fw-advisor.md, .kilo/agents/agents-fw-executor.md, .agents-fw/adapters/kilo/kilo.jsonc.example\n'
  printf 'aider: .aider.conf.yml\n'
  for procedure_file in "$FRAMEWORK_DIR"/procedures/*.md; do
    [ -f "$procedure_file" ] || continue
    procedure_name=${procedure_file##*/}
    procedure_name=${procedure_name%.md}
    printf 'skills: .agents/skills/agents-fw-%s/SKILL.md\n' "$procedure_name"
  done
}

validate_sources() {
  [ -d "$FRAMEWORK_DIR" ] || {
    error "framework source directory is missing"
    return 1
  }
  for source_file in "$SCRIPT_DIR/VERSION" "$FRAMEWORK_DIR/core.md" \
    "$FRAMEWORK_DIR/templates/ARCHITECTURE.md" "$FRAMEWORK_DIR/templates/SPEC_MASTER.md"; do
    if [ ! -f "$source_file" ] || [ ! -r "$source_file" ]; then
      error "required source file is missing or unreadable: $source_file"
      return 1
    fi
  done
  [ -r "$SCRIPT_DIR/VERSION" ] || {
    error "cannot read version file"
    return 1
  }
  framework_pairs=$(list_framework_pairs)
  [ -n "$framework_pairs" ] || {
    error "framework contains no managed files"
    return 1
  }
  while IFS="$(printf '\t')" read -r source_file destination; do
    if [ ! -f "$source_file" ] || [ ! -r "$source_file" ]; then
      error "framework source is missing or unreadable: $source_file"
      return 1
    fi
  done <<< "$framework_pairs"
}

validate_old_manifest() {
  OLD_HOSTS=''
  manifest_path="$PROJECT/.agents-fw/MANIFEST"
  [ -e "$manifest_path" ] || return 0
  if [ ! -f "$manifest_path" ] || [ ! -r "$manifest_path" ]; then
    error "manifest is not a readable file"
    return 1
  fi
  manifest_data=$(cat "$manifest_path" 2>/dev/null) || {
    error "cannot read manifest"
    return 1
  }
  first_line=1
  manifest_line_number=0
  has_version=0
  while IFS= read -r manifest_line || [ -n "$manifest_line" ]; do
    manifest_line_number=$((manifest_line_number + 1))
    if [ "$first_line" -eq 1 ]; then
      first_line=0
      case "$manifest_line" in
        'version '*) has_version=1 ;;
        *) error "invalid manifest version line"; return 1 ;;
      esac
      continue
    fi
    if [ "$manifest_line_number" -eq 2 ]; then
      case "$manifest_line" in
        'hosts '*)
          host_input=${manifest_line#hosts }
          if ! normalize_host_list "$host_input"; then
            error "invalid manifest hosts line"
            return 1
          fi
          OLD_HOSTS=$NORMALIZED_HOSTS
          continue
          ;;
      esac
    fi
    [ -n "$manifest_line" ] || continue
    case "$manifest_line" in
      *'  '*) old_path=${manifest_line#*  } ;;
      *) error "invalid manifest entry"; return 1 ;;
    esac
    safe_relative_path "$old_path" || {
      error "unsafe path in manifest: $old_path"
      return 1
    }
    check_path_links "$old_path" || return 1
  done <<< "$manifest_data"
  [ "$has_version" -eq 1 ] || {
    error "manifest version is missing"
    return 1
  }
}

validate_host_sources() {
  host_pairs=$(list_static_host_pairs)
  while IFS="$(printf '\t')" read -r source_file relative_path; do
    [ -n "$source_file" ] || continue
    if [ ! -f "$source_file" ] || [ ! -r "$source_file" ]; then
      error "host source is missing or unreadable: $source_file"
      return 1
    fi
    check_path_links "$relative_path" || return 1
  done <<< "$host_pairs"
  if host_is_selected skills; then
    procedure_count=0
    for procedure_file in "$FRAMEWORK_DIR"/procedures/*.md; do
      [ -f "$procedure_file" ] || continue
      if [ ! -r "$procedure_file" ]; then
        error "procedure source is unreadable: $procedure_file"
        return 1
      fi
      if ! extract_procedure_description "$procedure_file" >/dev/null; then
        error "procedure is missing a Use when line: $procedure_file"
        return 1
      fi
      procedure_name=${procedure_file##*/}
      procedure_name=${procedure_name%.md}
      check_path_links ".agents/skills/agents-fw-$procedure_name/SKILL.md" || return 1
      procedure_count=$((procedure_count + 1))
    done
    [ "$procedure_count" -gt 0 ] || {
      error "framework contains no procedures for skills"
      return 1
    }
  fi
}

prepare_generated_skills() {
  host_is_selected skills || return 0
  stage_candidate="$PROJECT/.agents-fw/.host-stage.$$"
  if [ -e "$stage_candidate" ] || [ -L "$stage_candidate" ]; then
    error "host staging path already exists"
    return 1
  fi
  HOST_STAGE_DIR=$stage_candidate
  mkdir -p "$HOST_STAGE_DIR/skills" 2>/dev/null || {
    error "cannot create host staging directory"
    return 1
  }
  for procedure_file in "$FRAMEWORK_DIR"/procedures/*.md; do
    [ -f "$procedure_file" ] || continue
    procedure_description=$(extract_procedure_description "$procedure_file") || {
      error "procedure is missing a Use when line: $procedure_file"
      return 1
    }
    procedure_name=${procedure_file##*/}
    procedure_name=${procedure_name%.md}
    stage_file="$HOST_STAGE_DIR/skills/agents-fw-$procedure_name/SKILL.md"
    mkdir -p "$(dirname "$stage_file")" 2>/dev/null || {
      error "cannot create generated skill directory"
      return 1
    }
    {
      printf '%s\n' '---'
      printf 'name: agents-fw-%s\n' "$procedure_name"
      printf 'description: %s\n' "$procedure_description"
      printf '%s\n\n' '---'
      cat "$procedure_file"
    } >"$stage_file" || {
      error "cannot stage generated skill: $stage_file"
      return 1
    }
  done
}

validate_managed_block() {
  agents_file="$PROJECT/AGENTS.md"
  [ -e "$agents_file" ] || return 0
  [ -f "$agents_file" ] || {
    error "AGENTS.md is not a regular file"
    return 1
  }
  start_count=$(grep -Fxc "$START_MARKER" "$agents_file" 2>/dev/null || true)
  end_count=$(grep -Fxc "$END_MARKER" "$agents_file" 2>/dev/null || true)
  if [ "$start_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    return 0
  fi
  if [ "$start_count" -ne 1 ] || [ "$end_count" -ne 1 ]; then
    error "AGENTS.md has malformed agents-fw markers"
    return 1
  fi
  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { if (state != 0) exit 1; state = 1; next }
    $0 == end { if (state != 1) exit 1; state = 2; next }
    END { if (state != 2) exit 1 }
  ' "$agents_file" || {
    error "AGENTS.md has misordered agents-fw markers"
    return 1
  }
}

cleanup() {
  if [ -n "$MANIFEST_TMP" ]; then
    rm -f "$MANIFEST_TMP" 2>/dev/null || true
  fi
  if [ -n "$HOST_STAGE_DIR" ]; then
    rm -rf "$HOST_STAGE_DIR" 2>/dev/null || true
  fi
}

copy_atomic() {
  source_file=$1
  destination=$2
  destination_dir=$(dirname "$destination")
  mkdir -p "$destination_dir" 2>/dev/null || {
    error "cannot create directory: $destination_dir"
    return 1
  }
  temporary_file="$destination.tmp.$$"
  cp -p "$source_file" "$temporary_file" 2>/dev/null || {
    rm -f "$temporary_file" 2>/dev/null || true
    error "cannot copy file: $source_file"
    return 1
  }
  mv -f "$temporary_file" "$destination" 2>/dev/null || {
    rm -f "$temporary_file" 2>/dev/null || true
    error "cannot replace file: $destination"
    return 1
  }
}

manifest_hash_for() {
  manifest_path="$PROJECT/.agents-fw/MANIFEST"
  [ -f "$manifest_path" ] || return 0
  awk -v wanted="$1" '
    index($0, "  ") {
      separator = index($0, "  ")
      if (substr($0, separator + 2) == wanted) {
        print substr($0, 1, separator - 1)
        exit
      }
    }
  ' "$manifest_path"
}

pair_is_current() {
  wanted=$1
  while IFS="$(printf '\t')" read -r source_file destination; do
    [ "$destination" = "$wanted" ] && return 0
  done <<< "$pairs"
  return 1
}

build_managed_block() {
  block_file=$1
  {
    printf '%s\n' "$START_MARKER"
    cat "$FRAMEWORK_DIR/core.md"
    if [ -s "$FRAMEWORK_DIR/core.md" ]; then
      final_newline=$(tail -c 1 "$FRAMEWORK_DIR/core.md" | wc -l | tr -d ' ')
      [ "$final_newline" -gt 0 ] || printf '\n'
    fi
    printf '%s\n' "$END_MARKER"
  } >"$block_file" || {
    rm -f "$block_file"
    error "cannot prepare managed block"
    return 1
  }
}

replace_managed_content() {
  agents_file=$1
  block_file=$2
  output_file=$3
  awk -v start="$START_MARKER" -v end="$END_MARKER" -v block_file="$block_file" '
    BEGIN {
      while ((getline line < block_file) > 0) block = block line "\n"
      close(block_file)
    }
    $0 == start { printf "%s", block; inside = 1; next }
    $0 == end { inside = 0; next }
    !inside { print }
  ' "$agents_file" >"$output_file" || {
    error "cannot update managed block"
    return 1
  }
}

append_managed_content() {
  agents_file=$1
  block_file=$2
  output_file=$3
  cp "$agents_file" "$output_file" 2>/dev/null || {
    error "cannot read AGENTS.md"
    return 1
  }
  final_newline=$(tail -c 1 "$agents_file" | wc -l | tr -d ' ')
  [ "$final_newline" -gt 0 ] || printf '\n' >>"$output_file"
  printf '\n' >>"$output_file"
  cat "$block_file" >>"$output_file" || {
    error "cannot append managed block"
    return 1
  }
}

render_managed_content() {
  agents_file=$1
  block_file=$2
  output_file=$3
  start_count=$(grep -Fxc "$START_MARKER" "$agents_file" 2>/dev/null || true)
  end_count=$(grep -Fxc "$END_MARKER" "$agents_file" 2>/dev/null || true)
  if [ "$start_count" -eq 1 ] && [ "$end_count" -eq 1 ]; then
    replace_managed_content "$agents_file" "$block_file" "$output_file"
  else
    append_managed_content "$agents_file" "$block_file" "$output_file"
  fi
}

write_managed_block() {
  block_file="$PROJECT/.agents-fw/.managed-block.$$"
  output_file="$PROJECT/AGENTS.md.tmp.$$"
  build_managed_block "$block_file" || return 1
  agents_file="$PROJECT/AGENTS.md"
  if [ ! -e "$agents_file" ]; then
    cp "$block_file" "$output_file" 2>/dev/null || {
      rm -f "$block_file" "$output_file"
      error "cannot create AGENTS.md"
      return 1
    }
    status=created
  else
    render_managed_content "$agents_file" "$block_file" "$output_file" || {
      rm -f "$block_file" "$output_file"
      return 1
    }
    if cmp -s "$agents_file" "$output_file"; then
      status=unchanged
    else
      status=updated
    fi
  fi
  if [ "$status" = created ] || [ "$status" = updated ]; then
    mv -f "$output_file" "$agents_file" 2>/dev/null || {
      rm -f "$block_file" "$output_file"
      error "cannot write AGENTS.md"
      return 1
    }
  else
    rm -f "$output_file"
  fi
  rm -f "$block_file"
  printf '%s  AGENTS.md\n' "$status"
}

create_project_file() {
  source_file=$1
  relative_path=$2
  destination="$PROJECT/$relative_path"
  if [ -e "$destination" ]; then
    printf 'unchanged  %s\n' "$relative_path"
    return 0
  fi
  copy_atomic "$source_file" "$destination" || return 1
  printf 'created  %s\n' "$relative_path"
}

create_project_files() {
  mkdir -p "$PROJECT/specs" "$PROJECT/docs/handoffs" 2>/dev/null || {
    error "cannot create project directories"
    return 1
  }
  create_project_file "$FRAMEWORK_DIR/templates/ARCHITECTURE.md" "ARCHITECTURE.md" || return 1
  create_project_file "$FRAMEWORK_DIR/templates/SPEC_MASTER.md" "specs/SPEC_MASTER.md" || return 1
  if [ -e "$PROJECT/docs/handoffs/.gitkeep" ]; then
    printf 'unchanged  docs/handoffs/.gitkeep\n'
  else
    : >"$PROJECT/docs/handoffs/.gitkeep" || {
      error "cannot create docs/handoffs/.gitkeep"
      return 1
    }
    printf 'created  docs/handoffs/.gitkeep\n'
  fi
}

update_managed_files() {
  while IFS="$(printf '\t')" read -r source_file relative_path; do
    update_managed_pair "$source_file" "$relative_path" || return 1
  done <<< "$pairs"
}

update_existing_pair() {
  source_file=$1
  relative_path=$2
  destination=$3
  source_hash=$(sha256 "$source_file") || return 1
  destination_hash=$(sha256 "$destination") || return 1
  if [ "$destination_hash" = "$source_hash" ]; then
    status=unchanged
  elif [ "$force" -eq 1 ]; then
    copy_atomic "$source_file" "$destination" || return 1
    status=updated
  else
    previous_hash=$(manifest_hash_for "$relative_path")
    if [ -n "$previous_hash" ] && [ "$destination_hash" = "$previous_hash" ]; then
      copy_atomic "$source_file" "$destination" || return 1
      status=updated
    else
      copy_atomic "$source_file" "$destination.new" || return 1
      status='kept (.new)'
    fi
  fi
  if [ "$force" -eq 1 ]; then
    rm -f "$destination.new" 2>/dev/null || {
      error "cannot remove stale update file: $destination.new"
      return 1
    }
  fi
}

update_managed_pair() {
  source_file=$1
  relative_path=$2
  safe_relative_path "$relative_path" || {
    error "unsafe managed destination: $relative_path"
    return 1
  }
  check_path_links "$relative_path" || return 1
  destination="$PROJECT/$relative_path"
  mkdir -p "$(dirname "$destination")" 2>/dev/null || {
    error "cannot create directory for: $relative_path"
    return 1
  }
  if [ ! -e "$destination" ]; then
    copy_atomic "$source_file" "$destination" || return 1
    status=created
  else
    update_existing_pair "$source_file" "$relative_path" "$destination" || return 1
  fi
  printf '%s  %s\n' "$status" "$relative_path"
}

remove_upstream_files() {
  manifest_path="$PROJECT/.agents-fw/MANIFEST"
  [ -f "$manifest_path" ] || return 0
  while IFS= read -r manifest_line; do
    case "$manifest_line" in
      version\ *) continue ;;
      *'  '*) old_hash=${manifest_line%%  *}; old_path=${manifest_line#*  } ;;
      *) continue ;;
    esac
    pair_is_current "$old_path" && continue
    destination="$PROJECT/$old_path"
    [ -e "$destination" ] || continue
    destination_hash=$(sha256 "$destination") || return 1
    if [ "$destination_hash" = "$old_hash" ]; then
      rm -f "$destination" 2>/dev/null || {
        error "cannot remove upstream file: $old_path"
        return 1
      }
      printf 'removed  %s\n' "$old_path"
    else
      printf 'kept (modified, removed upstream)  %s\n' "$old_path"
    fi
  done <"$manifest_path"
}

write_manifest() {
  version=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null) || {
    error "cannot read version file"
    return 1
  }
  MANIFEST_TMP="$PROJECT/.agents-fw/MANIFEST.tmp.$$"
  printf 'version %s\n' "$version" >"$MANIFEST_TMP" || {
    error "cannot prepare manifest"
    return 1
  }
  if [ -n "$HOSTS" ]; then
    hosts_csv=$(host_list_csv)
    printf 'hosts %s\n' "$hosts_csv" >>"$MANIFEST_TMP" || {
      error "cannot update manifest hosts"
      return 1
    }
  fi
  while IFS="$(printf '\t')" read -r source_file relative_path; do
    destination="$PROJECT/$relative_path"
    source_hash=$(sha256 "$source_file") || return 1
    destination_hash=$(sha256 "$destination") || return 1
    previous_hash=$(manifest_hash_for "$relative_path")
    if [ "$force" -eq 1 ] || [ "$destination_hash" = "$source_hash" ]; then
      manifest_hash=$source_hash
    elif [ -n "$previous_hash" ]; then
      manifest_hash=$previous_hash
    else
      continue
    fi
    printf '%s  %s\n' "$manifest_hash" "$relative_path" >>"$MANIFEST_TMP" || {
      error "cannot update manifest"
      return 1
    }
  done <<< "$pairs"
  mv -f "$MANIFEST_TMP" "$PROJECT/.agents-fw/MANIFEST" 2>/dev/null || {
    error "cannot replace manifest"
    return 1
  }
  MANIFEST_TMP=''
}

list_adopt_children() {
  child_dir=$1
  [ -d "$PROJECT/$child_dir" ] || return 0
  find "$PROJECT/$child_dir" -mindepth 1 -maxdepth 1 -print 2>/dev/null | LC_ALL=C sort |
    while IFS= read -r child_path; do
      child_name=${child_path##*/}
      case "$child_name" in
        agents-fw-*) continue ;;
      esac
      printf '%s/%s\n' "$child_dir" "$child_name"
    done
}

list_adopt_items() {
  ADOPT_ITEMS=''
  adopt_found=''
  if [ -f "$PROJECT/CLAUDE.md" ] && ! cmp -s "$PROJECT/CLAUDE.md" "$SCRIPT_DIR/adapters/claude/CLAUDE.md"; then
    adopt_found=CLAUDE.md
  fi
  for adopt_dir in .claude/rules .claude/agents .claude/skills; do
    adopt_found="$adopt_found
$(list_adopt_children "$adopt_dir")"
  done
  if [ -e "$PROJECT/.cursorrules" ]; then
    adopt_found="$adopt_found
.cursorrules"
  fi
  for adopt_dir in .cursor/rules .kilocode/rules; do
    adopt_found="$adopt_found
$(list_adopt_children "$adopt_dir")"
  done
  for adopt_file in .github/copilot-instructions.md CONVENTIONS.md; do
    [ -e "$PROJECT/$adopt_file" ] && adopt_found="$adopt_found
$adopt_file"
  done
  ADOPT_ITEMS=$(printf '%s\n' "$adopt_found" | sed '/^$/d')
  while IFS= read -r adopt_item; do
    [ -n "$adopt_item" ] || continue
    safe_relative_path "$adopt_item" || return 1
    check_path_links "$adopt_item" || return 1
  done <<< "$ADOPT_ITEMS"
}

print_adopt_plan() {
  while IFS= read -r adopt_item; do
    [ -n "$adopt_item" ] || continue
    printf 'would move  %s\n' "$adopt_item"
  done <<< "$ADOPT_ITEMS"
  for adopt_file in .claude/settings.json .mcp.json; do
    [ -e "$PROJECT/$adopt_file" ] && printf 'left alone  %s\n' "$adopt_file"
  done
  while IFS= read -r adopt_item; do
    [ -n "$adopt_item" ] || continue
    while IFS= read -r adopt_path; do
      printf '\n--- %s ---\n' "${adopt_path#"$PROJECT"/}"
      cat "$adopt_path"
    done < <(find "$PROJECT/$adopt_item" -type f -print 2>/dev/null | LC_ALL=C sort)
  done <<< "$ADOPT_ITEMS"
  printf '\nRe-run with --apply to back up these files and install the framework.\n'
}

apply_adopt() {
  adopt_stamp=$(date +%Y%m%d-%H%M%S)
  adopt_backup="$PROJECT/.agents-fw/backup/$adopt_stamp"
  adopt_suffix=0
  while [ -e "$adopt_backup" ]; do
    adopt_suffix=$((adopt_suffix + 1))
    adopt_backup="$PROJECT/.agents-fw/backup/$adopt_stamp-$adopt_suffix"
  done
  while IFS= read -r adopt_item; do
    [ -n "$adopt_item" ] || continue
    mkdir -p "$(dirname "$adopt_backup/$adopt_item")" 2>/dev/null || {
      error "cannot create backup directory for: $adopt_item"
      return 1
    }
    mv "$PROJECT/$adopt_item" "$adopt_backup/$adopt_item" 2>/dev/null || {
      error "cannot move to backup: $adopt_item"
      return 1
    }
    printf 'moved  %s\n' "$adopt_item"
  done <<< "$ADOPT_ITEMS"
  printf 'backup  %s\n' "${adopt_backup#"$PROJECT"/}"
}

main() {
  if [ "$#" -eq 1 ] && [ "$1" = hosts ]; then
    print_hosts
    return 0
  fi
  [ "$#" -ge 2 ] || {
    usage
    return 1
  }
  action=$1
  project_arg=$2
  shift 2
  force=0
  HOSTS=''
  OLD_HOSTS=''
  HOSTS_SPECIFIED=0
  APPLY=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --force)
        [ "$force" -eq 0 ] || {
          usage
          return 1
        }
        force=1
        shift
        ;;
      --host)
        if [ "$#" -lt 2 ] || [ "$HOSTS_SPECIFIED" -ne 0 ]; then
          usage
          return 1
        fi
        if ! normalize_host_list "$2"; then
          usage
          return 1
        fi
        HOSTS=$NORMALIZED_HOSTS
        HOSTS_SPECIFIED=1
        shift 2
        ;;
      --apply)
        [ "$action" = adopt ] && [ "$APPLY" -eq 0 ] || {
          usage
          return 1
        }
        APPLY=1
        shift
        ;;
      *)
        usage
        return 1
        ;;
    esac
  done
  case "$action" in
    install|update|adopt) ;;
    *) usage; return 1 ;;
  esac
  resolve_project "$project_arg" || return 1
  if [ "$action" = adopt ]; then
    list_adopt_items || return 1
    if [ -z "$ADOPT_ITEMS" ]; then
      printf 'nothing to adopt\n'
    elif [ "$APPLY" -eq 0 ]; then
      print_adopt_plan
    else
      apply_adopt || return 1
    fi
    [ "$APPLY" -eq 1 ] || return 0
  fi
  validate_sources || return 1
  for relative_path in .agents-fw AGENTS.md ARCHITECTURE.md specs specs/SPEC_MASTER.md docs docs/handoffs docs/handoffs/.gitkeep; do
    check_path_links "$relative_path" || return 1
  done
  [ -d "$PROJECT/.agents-fw" ] || [ ! -e "$PROJECT/.agents-fw" ] || {
    error ".agents-fw is not a directory"
    return 1
  }
  if [ -d "$PROJECT/.agents-fw" ] && [ -n "$(find "$PROJECT/.agents-fw" -type l -print -quit 2>/dev/null)" ]; then
    error "refusing symlink inside .agents-fw"
    return 1
  fi
  validate_old_manifest || return 1
  if [ "$HOSTS_SPECIFIED" -eq 0 ]; then
    HOSTS=$OLD_HOSTS
  fi
  validate_host_sources || return 1
  validate_managed_block || return 1
  mkdir -p "$PROJECT/.agents-fw" 2>/dev/null || {
    error "cannot create .agents-fw"
    return 1
  }
  trap cleanup EXIT
  prepare_generated_skills || return 1
  pairs=$(list_managed_pairs)
  while IFS="$(printf '\t')" read -r source_file relative_path; do
    [ -n "$relative_path" ] || continue
    check_path_links "$relative_path" || return 1
  done <<< "$pairs"
  while IFS= read -r source_directory; do
    relative_directory=${source_directory#"$FRAMEWORK_DIR"/}
    [ "$relative_directory" = "$source_directory" ] && continue
    mkdir -p "$PROJECT/.agents-fw/$relative_directory" 2>/dev/null || {
      error "cannot create framework directory: $relative_directory"
      return 1
    }
  done < <(find "$FRAMEWORK_DIR" -type d -print 2>/dev/null)
  update_managed_files || return 1
  remove_upstream_files || return 1
  write_managed_block || return 1
  create_project_files || return 1
  write_manifest || return 1
  if host_is_selected kilo; then
    printf 'Kilo model configuration example: .agents-fw/adapters/kilo/kilo.jsonc.example\n'
  fi
}

main "$@"
