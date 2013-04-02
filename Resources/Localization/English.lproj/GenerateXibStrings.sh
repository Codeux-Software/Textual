#!/bin/sh

for XIB in "$(dirname $0)/"*.xib; do
	ibtool --generate-strings-file "${XIB%.xib}.strings" "${XIB}"
done
