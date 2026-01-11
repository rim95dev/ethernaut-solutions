# Solution for Ethernaut Level 08: Vault

## Goal

The goal of this level is to unlock the `Vault` by finding its secret password.

## Vulnerability Analysis

The vulnerability stems from a common misconception about the `private` keyword in Solidity. The `Vault` contract stores its password in a `private` state variable, assuming this will keep it secret.

```solidity
contract Vault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }
    // ...
}
```

However, on a public blockchain, all data stored in a contract is publicly visible, regardless of visibility keywords like `private` or `internal`. These keywords only control read access *between contracts on the EVM*, not from the outside world via an RPC client. Anyone can query a node to read the raw data from a contract's storage slots.

In this contract, the state variables are stored in sequential slots:
-   **Slot 0**: `bool public locked`
-   **Slot 1**: `bytes32 private password`

By reading the contents of storage slot 1, we can retrieve the password.

## The Exploit

The `exploit.ts` script uses a direct RPC call to read the contract's private storage and then uses the retrieved value to unlock the vault.

### Step 1: Read the Private Password from Storage

The script uses the `getStorage` method from an Ethers.js provider to directly read the contents of storage slot 1 of the deployed `Vault` contract.

```typescript
const password = await rpc.getStorage(vaultAddress, 1);
console.log("password:", password);
```

This command communicates with an Ethereum node and requests the data at a specific storage position (`1`) for the given contract address (`vaultAddress`), completely bypassing the `private` visibility restriction. The node returns the `bytes32` value of the password.

### Step 2: Call `unlock()` with the Retrieved Password

With the password now known, the script simply calls the public `unlock` function, passing the retrieved password as the argument.

```typescript
await (await vault.unlock(password)).wait();
console.log("After Locked:", await vault.locked());
```

The `unlock` function's check `if (password == _password)` now passes, `locked` is set to `false`, and the level is completed.