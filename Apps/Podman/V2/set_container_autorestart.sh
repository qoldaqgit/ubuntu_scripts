#!/bin/bash

OUTPUT_FILE="/home/podman/.podman/containers-manager-up.sh"
PREFIX="/usr/bin/podman-compose -f "
SUFFIX=" up -d"

echo "#!/bin/bash"> "$OUTPUT_FILE"

find "/home/podman/dockge" -type f -name "compose.yaml" \
  | sed "s|^|$PREFIX|" \
  | sed "s|$|$SUFFIX|" \
  >> "$OUTPUT_FILE"
