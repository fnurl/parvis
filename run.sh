#!/bin/sh
if [[ "$#" -eq 1 ]] && [[ "$1" == "-p" ]]; then 
  processing-java --sketch=/Users/jodfo01/development/processing3/parvis_java --present
else
  processing-java --sketch=/Users/jodfo01/development/processing3/parvis_java --run
fi
