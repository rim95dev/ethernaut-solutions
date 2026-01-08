# Solution for Ethernaut Level 02: Fallout

## Goal

The goal of this level is to claim ownership of the `Fallout` contract.

## Vulnerability Analysis

The vulnerability lies in a typo within the contract's constructor function.

```solidity
/* constructor */
function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
}
```

In older versions of Solidity (prior to 0.4.22), constructors were defined as functions with the same name as the contract. However, in this contract, the constructor is named `Fal1out` instead of `Fallout` (the 'l' is a '1').

Because of this typo, the function is not treated as a constructor. Instead, it is a regular `public` function that can be called by anyone at any time. This function sets the `owner` of the contract to the `msg.sender`.

## The Exploit

The solution is a single step, as implemented in the `exploit.ts` script: simply call the misnamed `Fal1out` function.

### Step 1: Call `Fal1out()` to Take Ownership

We make a direct call to the `public` function `Fal1out()`.

```typescript
// Call Fal1out function
console.log("Call Fal1out function");
await (await fallout.Fal1out()).wait();
console.log("New owner:", await fallout.owner());
```

When this transaction is executed, the contract's `owner` state variable is updated to our address (`msg.sender`). This grants us ownership of the contract, completing the level's objective.