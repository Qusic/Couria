#!/usr/bin/env bash
output_dir=$1
strings_file=$(dirname "${BASH_SOURCE[0]}")/strings.txt
languages=($(twine generate-report "$strings_file" | grep '^\w\+: \d\+$' | sed -E 's/: [[:digit:]]+$//g'))
for language in "${languages[@]}"; do
    mkdir "$output_dir/$language.lproj"
done
twine generate-all-string-files "$strings_file" "$output_dir"
