#!/bin/bash

echo "Creating chain1..."

# Delete existing chain1 if exists
/Users/cardene/bin/avalanche blockchain delete chain1 -y 2>/dev/null || true

# Create chain1 with inputs
/Users/cardene/bin/avalanche blockchain create chain1 --evm << EOF
1
1
1
EOF

echo "chain1 created successfully"