import {CoinFlip} from "./CoinFlip.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlipWrapper {
    CoinFlip public coinFlip;

    constructor(address _coinFlip) {
        coinFlip = CoinFlip(_coinFlip);
    }

    function onlySuccessFlip(bool guess) public {
        coinFlip.flip(guess);
        require(coinFlip.consecutiveWins() > 0);
    }
}
