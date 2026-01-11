# Solution for Ethernaut Level 05: Token

## Goal

The goal of this level is to acquire a large number of tokens, starting with a small initial balance.

## Vulnerability Analysis

The vulnerability is an integer underflow in the `transfer` function of the `Token.sol` contract. The contract was written using a version of Solidity (`^0.6.0`) that does not have built-in protection against arithmetic overflows and underflows, which became standard in version `0.8.0`.

```solidity
function transfer(address _to, uint256 _value) public returns (bool) {
    require(balances[msg.sender] - _value >= 0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    return true;
}
```

The check `require(balances[msg.sender] - _value >= 0)` is insufficient. If a user tries to transfer more tokens (`_value`) than they own (`balances[msg.sender]`), the subtraction `balances[msg.sender] - _value` will underflow. For example, if a user has 20 tokens and tries to send 21, the result will not be -1 but will wrap around to `2**256 - 1`, a very large positive integer.

This large number passes the `require` check, and the subsequent line `balances[msg.sender] -= _value` also underflows, setting the sender's balance to a massive value.

## The Exploit

The `exploit.ts` script is designed to trigger this precise underflow condition.

### Step 1: Check Initial Balance

The script first queries the contract to determine the player's starting token balance.

```typescript
const initialBalances = await token.balanceOf(player.address);
console.log("Initial balances:", initialBalances);
```

### Step 2: Trigger the Underflow with an Invalid Transfer

The core of the exploit is to call the `transfer` function with a `_value` that is slightly larger than the player's current balance. The script attempts to transfer `initialBalances + 1` tokens.

```typescript
console.log("Call transfer function");
await (await token.transfer(tokenAddress, initialBalances + 1n)).wait();
console.log(
  "After transfer balances:",
  await token.balanceOf(player.address)
);
```

This action causes the player's balance, which is stored as a `uint256`, to underflow. Instead of becoming a negative value (which is impossible for a `uint`), it wraps around to a very large number. By sending just one more token than available, the player's balance becomes immensely large, thus achieving the level's objective.