#!/bin/bash
set -e  # Exit on errors

# Parameter validation
artifact_dir="$1"
if [ -z "$artifact_dir" ]; then
  echo "Usage: $0 <artifact_name>" >&2
  echo "Example: $0 sdk" >&2
  exit 1
fi

# Function to generate maven-metadata.xml with all discovered versions
generate_maven_metadata() {
  local artifact_name="$1"
  local artifact_path="repository/com/salesforce/personalization/${artifact_name}"

  # Ensure directory exists
  mkdir -p "$artifact_path"

  # Find all version directories (directories that start with a number)
  local versions=$(find "$artifact_path" -maxdepth 1 -type d -name "[0-9]*" | sed "s|$artifact_path/||" | sort -V)

  # Skip if no versions found (shouldn't happen, but be defensive)
  if [ -z "$versions" ]; then
    echo "Warning: No version directories found for $artifact_name" >&2
    return 0
  fi

  # Get latest version (last in sorted list)
  local latest_version=$(echo "$versions" | tail -n 1)

  # Generate timestamp in Maven format (YYYYMMDDhhmmss)
  local timestamp=$(date -u +"%Y%m%d%H%M%S")

  # Generate maven-metadata.xml
  cat > "$artifact_path/maven-metadata.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<metadata>
  <groupId>com.salesforce.personalization</groupId>
  <artifactId>$artifact_name</artifactId>
  <versioning>
    <latest>$latest_version</latest>
    <release>$latest_version</release>
    <versions>
EOF

  # Add each version
  for version in $versions; do
    echo "      <version>$version</version>" >> "$artifact_path/maven-metadata.xml"
  done

  # Close the XML
  cat >> "$artifact_path/maven-metadata.xml" <<EOF
    </versions>
    <lastUpdated>$timestamp</lastUpdated>
  </versioning>
</metadata>
EOF

  echo "Generated maven-metadata.xml for $artifact_name with $(echo "$versions" | wc -l | tr -d ' ') version(s): $(echo $versions | tr '\n' ' ')"
}

# Step 1: Generate/regenerate maven-metadata.xml
generate_maven_metadata "$artifact_dir"

# Step 2: Generate HTML indexes for directory browsing (existing functionality)
for DIR in $(find ./repository -type d); do
  (
    echo -e "<html>\n<body>\n<h1>Directory listing</h1>\n<hr/>\n<pre>"
    ls -1pa "${DIR}" | grep -v "^\./$" | grep -v "^index\.html$" | grep -v "^\.DS\_Store$" | awk '{ printf "<a href=\"%s\">%s</a>\n",$1,$1 }'
    echo -e "</pre>\n</body>\n</html>"
  ) > "${DIR}/index.html"
done