// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReceiveLocker {
    constructor(address king) payable {
        (bool result, ) = king.call{value: msg.value}("");
        require(result);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}
