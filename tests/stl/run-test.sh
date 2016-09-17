#!/usr/bin/env bash

# This file is part of Hoppy.
#
# Copyright 2015-2016 Bryan Gardiner <bog@khumba.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Builds and runs the unit test suite in this directory.  Testing is done within
# a Cabal sandbox for isolation.

# Bash strict mode.
set -euo pipefail

# Go to this file's directory.
myDir=$(greadlink -f "$0")
myDir=$(dirname "$myDir")
cd "$myDir"

filesToClean="cpp/std.?pp"

. ../test-runner.sh
