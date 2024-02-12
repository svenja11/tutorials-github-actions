markdown_file="$1"
json_schema=".github/scripts-metadata/schema.json"
output_file=".github/scripts-metadata/meta-converted.json"
validate_file=".github/scripts-metadata/validation_result.txt"
variables=".github/scripts-metadata/variables.txt"
new_variables=".github/scripts-metadata/new-variables.txt"
updated_variables=".github/scripts-metadata/updated-variables.txt"

echo $markdown_file

# Extract YAML front matter from Markdown file
metadata=$(awk '/^---$/{f=!f;next}f' "$markdown_file" | yq eval -o=json -)

# Turn the metadata into a JSON file
echo "$metadata" > "$output_file"

# Validate metadata against the JSON schema
npx ajv-cli validate -s "$json_schema" -d "$output_file" --all-errors > "$validate_file" 2>&1

# Extract error messages from "validate_file"
awk -F"[ ':]+" '/instancePath/ {key=substr($3, 2); next} /message/ {message=""; for(i=3;i<=NF;i++) message=message $i " "; print key "=" message}' "$validate_file" > "$new_variables"

# Check if any keys are missing
for key in SPDX-License-Identifier path slug date title short_description tags author author_link author_img author_description language available_languages header_img cta; do
  if ! jq -e ".[\"$key\"]" $output_file > /dev/null; then
    echo "$key=Not found" >> $new_variables
  fi
done

# Replace the original variable messages with error messages
awk -F'=' 'NR==FNR{a[$1]=$2; next} {if($1 in a) {$2=a[$1]} print}' OFS='=' "$new_variables" "$variables" > "$updated_variables"

echo "$updated_variables"
