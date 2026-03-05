#!/bin/bash
set -e

DEFAULT_LIST="orphan_list.txt"

prompt_dir () {
  local label="$1"
  local def="$2"
  local v=""
  while true; do
    read -p "$label [$def]: " v
    v="${v:-$def}"
    if [ -d "$v" ]; then
      echo "$v"
      return 0
    else
      echo "Not a directory: $v"
    fi
  done
}

prompt_file () {
  local label="$1"
  local def="$2"
  local v=""
  while true; do
    read -p "$label [$def]: " v
    v="${v:-$def}"
    if [ -f "$v" ]; then
      echo "$v"
      return 0
    else
      echo "Not a file: $v"
    fi
  done
}

scan_orphans () {
  local ABC="$1"
  local XYZ="$2"
  local OUT="$3"

  echo "Scanning XYZ for candidates (files with links=1) and filtering those whose inode is absent in ABC..."
  : > "$OUT"

  # 注意：这版对每个候选都会在 ABC 内 find 一次 inode，文件多会慢，但最直观易用。
  find "$XYZ" -type f -links 1 | while IFS= read -r f; do
    inode=$(stat -c %i "$f") || continue
    if ! find "$ABC" -inum "$inode" -print -quit 2>/dev/null | grep -q .; then
      echo "$f" >> "$OUT"
    fi
  done

  echo "Scan done. List saved to: $OUT"
  echo -n "Total lines: "
  wc -l "$OUT" | awk '{print $1}'
}

view_list () {
  local LIST="$1"
  echo "---- First 50 lines of $LIST ----"
  nl -ba "$LIST" | head -n 50
  echo "--------------------------------"
}

process_list () {
  local ABC="$1"
  local LIST="$2"

  echo
  echo "Choose process mode:"
  echo "1) interactive (逐条处理：delete/keep/link/quit)"
  echo "2) delete ALL"
  echo "3) keep ALL"
  echo "4) create hardlink for ALL (to a directory you specify)"
  echo "5) back"

  read -p "Select: " mode
  [ -z "$mode" ] && return 0
  [ "$mode" = "5" ] && return 0

  local bulk_dir=""
  if [ "$mode" = "4" ]; then
    echo
    echo "Batch link needs a destination directory (will create links as DESTDIR/<basename>)."
    bulk_dir=$(prompt_dir "Enter destination directory for new links" "$ABC/recovered")
  fi

  while IFS= read -r file; do
    [ -z "$file" ] && continue

    if [ ! -e "$file" ]; then
      echo "SKIP (missing now): $file"
      continue
    fi

    action="$mode"
    if [ "$mode" = "1" ]; then
      echo "--------------------------------"
      echo "File: $file"
      echo "1) delete"
      echo "2) keep"
      echo "3) create hardlink (you type full dest path)"
      echo "4) quit"

      read -p "Select: " action
    fi

    if [ "$action" = "1" ]; then
      rm -v -- "$file"

    elif [ "$action" = "2" ] || [ "$action" = "3" ]; then
      if [ "$action" = "2" ]; then
        echo "KEEP: $file"
      else
        read -p "Enter full destination path for new hardlink: " dest
        if [ -z "$dest" ]; then
          echo "No dest, keep."
          continue
        fi
        mkdir -p "$(dirname "$dest")"
        ln -v -- "$file" "$dest"
      fi

    elif [ "$action" = "4" ]; then
      # interactive quit
      return 0

    elif [ "$action" = "4" ] && [ "$mode" != "1" ]; then
      # unreachable
      :

    elif [ "$action" = "4" ] && [ "$mode" = "4" ]; then
      # unreachable
      :

    elif [ "$action" = "4" ]; then
      # unreachable
      :

    elif [ "$action" = "4" ]; then
      # noop
      :

    elif [ "$action" = "4" ]; then
      :

    elif [ "$action" = "4" ]; then
      :

    elif [ "$action" = "4" ]; then
      :

    else
      # batch modes 2/3/4
      if [ "$mode" = "2" ]; then
        rm -v -- "$file"
      elif [ "$mode" = "3" ]; then
        echo "KEEP: $file"
      elif [ "$mode" = "4" ]; then
        bn="$(basename "$file")"
        dest="$bulk_dir/$bn"
        if [ -e "$dest" ]; then
          echo "SKIP (dest exists): $dest"
        else
          mkdir -p "$bulk_dir"
          ln -v -- "$file" "$dest"
        fi
      fi
    fi

  done < "$LIST"

  echo "Process done."
}

main_menu () {
  echo
  echo "========== Hardlink Orphan Tool =========="
  echo "1) Scan and create orphan list"
  echo "2) Process an existing list file"
  echo "3) View a list file"
  echo "4) Quit"
  read -p "Select: " c
  echo "$c"
}

# ---- main ----
echo "This tool identifies files in XYZ with links=1 whose inode is absent in ABC."
echo "Then you can delete/keep/recreate another hardlink."

ABC=$(prompt_dir "Enter ABC (source dir)" "/volume/abc")
XYZ=$(prompt_dir "Enter XYZ (target dir)" "/volume/xyz")

LIST_PATH="$DEFAULT_LIST"

while true; do
  c=$(main_menu)
  case "$c" in
    1)
      read -p "Output list file path [$LIST_PATH]: " out
      LIST_PATH="${out:-$LIST_PATH}"
      scan_orphans "$ABC" "$XYZ" "$LIST_PATH"
      echo
      echo "Next action:"
      echo "1) View list"
      echo "2) Process list now"
      echo "3) Back to main menu"
      read -p "Select: " nxt
      if [ "$nxt" = "1" ]; then
        view_list "$LIST_PATH"
      elif [ "$nxt" = "2" ]; then
        process_list "$ABC" "$LIST_PATH"
      fi
      ;;
    2)
      LIST_PATH=$(prompt_file "Enter list file to process" "$LIST_PATH")
      process_list "$ABC" "$LIST_PATH"
      ;;
    3)
      LIST_PATH=$(prompt_file "Enter list file to view" "$LIST_PATH")
      view_list "$LIST_PATH"
      ;;
    4)
      exit 0
      ;;
    *)
      echo "Unknown option."
      ;;
  esac
done
