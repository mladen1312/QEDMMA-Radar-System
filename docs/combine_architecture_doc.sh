#!/bin/bash
# Combine the split architecture document
cat PART_aa PART_ab PART_ac > QEDMMA_System_Architecture_v1.3.md
rm -f PART_aa PART_ab PART_ac
echo "Combined into QEDMMA_System_Architecture_v1.3.md"
