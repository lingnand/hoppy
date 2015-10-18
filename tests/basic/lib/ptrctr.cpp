// This file is part of Hoppy.
//
// Copyright 2015 Bryan Gardiner <bog@khumba.net>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License version 3
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include "ptrctr.hpp"

int PtrCtr::constructions_ = 0;

int PtrCtr::destructions_ = 0;

PtrCtr::PtrCtr() {
    ++constructions_;
}

PtrCtr::PtrCtr(const PtrCtr&) {
    ++constructions_;
}

PtrCtr::PtrCtr(PtrCtr&&) {
    ++constructions_;
}

PtrCtr::~PtrCtr() {
    ++destructions_;
}

int PtrCtr::resetCounters() {
    constructions_ = 0;
    destructions_ = 0;
}

int PtrCtr::getConstructionCount() {
    return constructions_;
}

int PtrCtr::getDestructionCount() {
    return destructions_;
}
