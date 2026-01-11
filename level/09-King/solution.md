# Solution for Ethernaut Level 09: King

## Goal

The primary goal is to take kingship of the `King` contract. The secondary goal is to prevent any other player from becoming the next king, effectively locking the contract with you as the final ruler.

## Vulnerability Analysis

The vulnerability lies in the `receive()` function of the `King` contract, which does not safely handle payments to the previous king.

```solidity
// King.sol
receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value); // <-- Vulnerable line
    king = msg.sender;
    prize = msg.value;
}
```

When a new player attempts to become king, the contract first tries to refund the new prize amount (`msg.value`) to the old king using `payable(king).transfer(msg.value)`. The `transfer` function reverts if the recipient is a contract whose fallback/receive function reverts (i.e., it's designed to reject incoming Ether).

If the current `king` is such a contract, the `transfer` will fail. This failure will cause the entire transaction to revert, making it impossible for a new king to be crowned. This creates a permanent Denial of Service (DoS) vulnerability, allowing the malicious contract to remain king forever.

## The Exploit

The `exploit.ts` script leverages this DoS vulnerability by deploying a malicious contract, `ReceiveLocker.sol`, to become the new king and then block all future claimants.

### Step 1: The `ReceiveLocker` Attack Contract

The script uses a purpose-built contract, `ReceiveLocker`, as the attack vehicle. This contract has two key features:
1.  A mechanism to become the new king by sending the required prize money to the `King` contract.
2.  A `receive()` and `fallback()` function that always reverts, ensuring it will reject any Ether sent to it once it has become king.

```solidity
// ReceiveLocker.sol
contract ReceiveLocker {
    constructor(address king) payable {
        payable(king).transfer(msg.value);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}
```

### Step 2: Taking the Throne and Locking the Contract

The `exploit.ts` script initiates the attack by deploying the `ReceiveLocker` contract and, within the same deployment transaction, funding it to take over the kingship.

```typescript
const currentPrize = await king.prize();
const ReceiveLocker = new ReceiveLocker__factory(player);
const receiveLocker = await ReceiveLocker.deploy(kingAddress, {
  value: currentPrize + 1n,
});
await receiveLocker.waitForDeployment();
```

The script performs the following sequence:
1.  It deploys the `ReceiveLocker` contract.
2.  The `ReceiveLocker`'s constructor is executed, which immediately calls the `King` contract, sending an amount greater than the current `prize`.
3.  The `King` contract's `receive()` function is triggered. It successfully pays the old king, then sets the new `king` to be the address of our newly deployed `ReceiveLocker` contract.

Once the `ReceiveLocker` contract is the king, any future attempt to claim the throne will fail. When another player sends Ether to `King`, the `King` contract will try to `transfer` the prize to `ReceiveLocker`. However, `ReceiveLocker`'s `receive()` function will revert, causing the entire takeover attempt to fail and forever locking you as the king.