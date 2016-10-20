#!/usr/bin/env bash

#------------------------------------------------------------------------------
# This script is needed because Grinder or Analyzer is not
# able handle subdirs - at least I could not figure out how...
#

cd $1
dartanalyzer $2
