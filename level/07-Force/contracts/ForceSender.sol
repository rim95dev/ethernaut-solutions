// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceSender {
    constructor(address payable receiver) payable {
        selfdestruct(receiver);
    }
}
