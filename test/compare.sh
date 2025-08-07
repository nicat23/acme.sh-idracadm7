#!/bin/sh

# Temp files
only_defaults="$(mktemp)"
only_acme="$(mktemp)"
diff_files="$(mktemp)"

# Flags
quiet=0
show_diff=0

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --quiet) quiet=1 ;;
        --diff) show_diff=1 ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) break ;;
    esac
    shift
done

# Positional args
defaults="${1:-/defaults}"
acme="${2:-/acme}"

print_comparison_tree() {
    defaults_dir="$1"
    acme_dir="$2"
    rel_path="$3"
    prefix="$4"

    full_defaults="$defaults_dir/$rel_path"
    full_acme="$acme_dir/$rel_path"

    tmpfile="$(mktemp)"
    [ -d "$full_defaults" ] && ls -1 "$full_defaults" >> "$tmpfile"
    [ -d "$full_acme" ] && ls -1 "$full_acme" >> "$tmpfile"

    sort -u "$tmpfile" > "$tmpfile.sorted"

    while IFS= read -r entry; do
        sub_rel="$rel_path/$entry"
        path_defaults="$defaults_dir/$sub_rel"
        path_acme="$acme_dir/$sub_rel"

        marker=""
        if [ -L "$path_defaults" ] || [ -L "$path_acme" ]; then
            marker="🔗"
        elif [ -e "$path_defaults" ] && [ -e "$path_acme" ]; then
            if [ -f "$path_defaults" ] && [ -f "$path_acme" ]; then
                if cmp -s "$path_defaults" "$path_acme"; then
                    marker="✅"
                else
                    marker="❗"
                    echo "$sub_rel" >> "$diff_files"
                fi
            else
                marker="✅"
            fi
        elif [ -e "$path_defaults" ]; then
            marker="➕"
            echo "$sub_rel" >> "$only_defaults"
        elif [ -e "$path_acme" ]; then
            marker="⚠️"
            echo "$sub_rel" >> "$only_acme"
        fi

        # Show symlink target if applicable
        if [ "$marker" = "🔗" ]; then
            target=""
            [ -L "$path_defaults" ] && target="$(readlink "$path_defaults")"
            [ -z "$target" ] && [ -L "$path_acme" ] && target="$(readlink "$path_acme")"
            [ "$quiet" -eq 0 ] && echo "${prefix}├── $entry $marker → $target"
        else
            [ "$quiet" -eq 0 ] && echo "${prefix}├── $entry $marker"
        fi

        # Recurse into directories
        if [ -d "$path_defaults" ] || [ -d "$path_acme" ]; then
            print_comparison_tree "$defaults_dir" "$acme_dir" "$sub_rel" "${prefix}│   "
        fi
    done < "$tmpfile.sorted"

    rm -f "$tmpfile" "$tmpfile.sorted"
}

# Header
[ "$quiet" -eq 0 ] && {
    echo "Comparing:"
    echo "  Golden tree: $defaults"
    echo "  Mounted tree: $acme"
    echo ""
    echo "$(basename "$defaults") vs $(basename "$acme")"
}

print_comparison_tree "$defaults" "$acme" "" ""

# Summary
echo ""
echo "📋 Summary Report"
echo "-----------------"

count_only_defaults=$(wc -l < "$only_defaults")
count_only_acme=$(wc -l < "$only_acme")
count_diff_files=$(wc -l < "$diff_files")

[ "$count_only_defaults" -gt 0 ] && {
    echo "➕ Only in $defaults ($count_only_defaults):"
    sort "$only_defaults"
    echo ""
}

[ "$count_only_acme" -gt 0 ] && {
    echo "⚠️ Only in $acme ($count_only_acme):"
    sort "$only_acme"
    echo ""
}

[ "$count_diff_files" -gt 0 ] && {
    echo "❗ Differing files ($count_diff_files):"
    sort "$diff_files"
    echo ""
}

# Show diffs
if [ "$show_diff" -eq 1 ] && [ "$count_diff_files" -gt 0 ]; then
    echo "🔍 Unified Diffs"
    echo "----------------"
    while IFS= read -r rel; do
        echo "Diff: $rel"
        diff -u "$defaults/$rel" "$acme/$rel" || true
        echo ""
    done < "$diff_files"
fi

# Cleanup
rm -f "$only_defaults" "$only_acme" "$diff_files"
