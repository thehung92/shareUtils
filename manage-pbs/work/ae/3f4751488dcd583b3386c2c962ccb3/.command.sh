#!/bin/bash -ue
awk '{print toupper($0)}' output1 > output2
