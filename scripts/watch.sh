#!/bin/sh

while true; do
  find ./example ./test ./sqlite -type f | entr -dnc make test
done
