# Solution for Ethernaut Level 07: Force

## Goal

The objective of this level is to force Ether into a contract that has no `payable` functions, so that its balance is greater than zero.

## Vulnerability Analysis

The target `Force.sol` contract is completely empty.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {
    /* ... MEOW ... */
}
```

Without a `payable` constructor, `receive()` function, or any other `payable` function, it is impossible to send Ether to this contract through normal transactions.

However, there is a way to forcibly send Ether to any address: by using `selfdestruct`. When a contract is destroyed via `selfdestruct(address)`, its entire Ether balance is transferred to the specified address. This happens at the EVM level and bypasses any checks in the receiving contract.

To exploit this, we need a separate contract that can be funded and then self-destructed, sending its funds to the target `Force` contract.

## The Exploit

The `exploit.ts` script uses a helper contract, `ForceSender.sol`, to perform this attack.

### Step 1: The `ForceSender` Contract

The `ForceSender` contract is designed for a single purpose: to receive Ether and immediately forward it to a target address upon its creation by self-destructing.

```solidity
// ForceSender.sol
contract ForceSender {
    constructor(address payable receiver) payable {
        selfdestruct(receiver);
    }
}
```
Its constructor is `payable`, allowing it to receive funds during deployment. The `selfdestruct(receiver)` call immediately executes the core of the attack.

### Step 2: Deploying `ForceSender` to Send Funds

The exploit script deploys the `ForceSender` contract. During deployment, it provides the `Force` contract's address as the `receiver` argument and sends a small amount of Ether (1 wei) along with the transaction using the `value` field.

```typescript
const ForceSender = new ForceSender__factory(player);
const forceSender = await ForceSender.deploy(forceAddress, {
  value: 1n,
});
await forceSender.waitForDeployment();
```

This single transaction triggers the following sequence:
1.  The `ForceSender` contract is deployed to the blockchain, and its constructor receives the 1 wei sent with the transaction.
2.  The constructor immediately executes `selfdestruct(forceAddress)`.
3.  The `ForceSender` contract is destroyed, and its entire balance of 1 wei is forcibly sent to the `forceAddress`.

After the transaction is complete, the `Force` contract's balance is greater than zero, and the level is solved.