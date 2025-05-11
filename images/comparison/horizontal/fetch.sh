#!/usr/bin/env bash
set -euo pipefail

# 1) List your remote "copies" folders exactly as on vision11:
folders=(
  "/nfs_share3/om/coco/sorted/horizontal/copies/000000005992"
  "/nfs_share3/om/coco/sorted/horizontal/copies/000000007108"
  "/nfs_share3/om/coco/sorted/horizontal/copies/000000054123"
  "/nfs_share3/om/coco/sorted/horizontal/copies/000000116206"
  "/nfs_share3/om/coco/sorted/horizontal/copies/000000134096"
  "/nfs_share3/om/dram/sorted/horizontal/unseen/rococo/anne-vallayer-coster/copies/still-life-with-round-bottle-1770"
  "/nfs_share3/om/dram/sorted/horizontal/expressionism/franz-marc-wiki/copies/Franz-marc-the-fear-of-the-hare"
  "/nfs_share3/om/dram/sorted/horizontal/expressionism/rudolf-lang/copies/9223372032559843421"
  "/nfs_share3/om/dram/sorted/horizontal/impressionism/anna-ancher/copies/1905_9223372032559822572"
  "/nfs_share3/om/dram/sorted/horizontal/unseen/rococo/george-morland/copies/47588"
  "/nfs_share2/code/om/pidray/sorted/horizontal/copies/xray_easy02713"
  "/nfs_share3/om/ishape_dataset/concat/wire/copies/99"
)

# 2) Shuffle the folder list
mapfile -t shuffled < <(printf "%s\n" "${folders[@]}" | shuf)

# 3) Fetch & rename
counter=2
for remote_path in "${shuffled[@]}"; do
  base="$(basename "$remote_path")"
  echo "[$counter] Fetching $remote_path → ./$base/"
  scp -r om@vision11.idav.ucdavis.edu:"$remote_path" ./

  local_dir="./$base"

  # Verify exactly 4 files (optional sanity check)
  file_count=$(find "$local_dir" -maxdepth 1 -type f | wc -l)
  if [[ $file_count -ne 4 ]]; then
    echo "ERROR: Expected 4 files in $local_dir, found $file_count" >&2
    exit 1
  fi

  # Rename each file according to its content and the folder index
  for file in "$local_dir"/*; do
    fname="$(basename "$file")"
    ext="${fname##*.}"
    lower_fname="${fname,,}"  # lowercase to match patterns
    newname="${counter}"

    if [[ "$lower_fname" == *"mae"* ]]; then
      newname+="_mae.png"
    elif [[ "$lower_fname" == *"sam"* ]]; then
      newname+="_sam.png"
    elif [[ "$lower_fname" == *"sd"* ]] || [[ "$lower_fname" == *"fixed"* ]]; then
      newname+="_sd.png"
    else
      newname+=".${ext}"
    fi

    echo "    Renaming '$fname' → '$newname'"
    mv -- "$file" "$local_dir/$newname"
  done

  ((counter++))
done

echo "All done — fetched and renamed folders in random order."
