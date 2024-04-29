# Analyzing the Inverse Finance Attack: Detecting Price Manipulation Using a TWAP Oracle Trap

## Introduction

In this post, we will explore the Inverse Finance attack that occurred on April 2, 2022, and demonstrate how using a Drosera Trap can be used to detect and prevent such attacks. The attack exploited a vulnerability in the price oracle used by Inverse Finance, resulting in a significant loss of funds. We will dive into the details of the attack, the response from the Inverse Finance team, and present a proof-of-concept implementation of a TWAP oracle trap that could have detected the price manipulation.

## The Attack

On April 2, 2022, at 11:04:09 AM UTC, an attacker executed a [malicious transaction](https://etherscan.io/tx/0x20a6dcff06a791a7f8be9f423053ce8caee3f9eecc31df32445fc98d4ccd8365) that manipulated the price of the INV/WETH trading pair on the Sushiswap decentralized exchange. The attacker exploited a vulnerability in the price oracle used by Inverse Finance which was a `Keep3rV2Oracle` TWAP contract internally deployed [here](https://etherscan.io/address/0x39b1df026010b5aea781f90542ee19e900f2db15), which relied on the `SushiSwap INV/WETH` pool to determine the price of the INV token.

The attacker's transaction involved selling a large amount of WETH for INV tokens, causing a significant imbalance in the pool's reserves and artificially inflating the price of INV relative to WETH. This manipulated price was then used by Inverse Finance's lending protocol, allowing the attacker to borrow funds at an advantageous rate.

## Inverse Finance's Response

The Inverse Finance team responded to the attack by pausing the affected contracts at block `14506987` ([transactions](https://etherscan.io/txs?a=0x3fcb35a1cbfb6007f9bc638d388958bc4550cb28&p=5)), which occurred approximately 2 hours, 26 minutes, and 18 seconds after the initial exploit.

## TWAP Oracle Trap

To detect and prevent such price manipulation attacks, we propose the use of Drosera's trap concept. The idea is to continuously monitor the price data from the oracle and compare it against a predefined threshold to identify any sudden and significant price deviations.

We have implemented a proof-of-concept TWAP oracle trap in Solidity, and a simulated test contract to demonstrate its effectiveness in detecting the price manipulation that occurred during the Inverse Finance attack:

1. The `InverseFinanceTrap` contract:

- This contract interacts with the Keep3rV2Oracle, the oracle used by Inverse Finance, to retrieve price data points.
- It provides a `collect` function to fetch the current price and timestamp from the oracle.
- The `isValid` function analyzes an array of price data points and checks for any price deviations that exceed the specified threshold (PRICE_DEVIATION_THRESHOLD). If a deviation is detected, it returns `false`, indicating a potential price manipulation.

2. The `TWAPTrapTest` contract:

- This is a Forge test contract that demonstrates how the TWAP oracle trap can be used to detect the Inverse Finance attack.
- It creates two fork instances of the Ethereum mainnet: one at block `14506358` (before the exploit) and another at block `14506359` (during the exploit).
- The `test_twapTrap` function collects price data points from both forks using the `InverseFinanceTrap` contract and passes them to the `isValid` function.
- If the `isValid` function returns `false`, indicating a price manipulation, the test passes.

## Results

Running the `InverseFinanceTrapTest` yields the following results:

```bash
[PASS] test_twapTrap() (gas: 982809)
Traces:
  [982809] TWAPTrapTest::test_twapTrap()
    ├─ [0] VM::selectFork(0)
    │   └─ ← [Return]
    ├─ [273441] → new InverseFinanceAttackSimulation@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   └─ ← [Return] 1034 bytes of code
    ├─ [28304] InverseFinanceAttackSimulation::collect() [staticcall]
    │   ├─ [24656] 0x39b1dF026010b5aEA781f90542EE19E900F2Db15::current(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68, 1000000000000000000 [1e18], 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) [staticcall]
    │   │   ├─ [2387] 0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821::price0CumulativeLast() [staticcall]
    │   │   │   └─ ← [Return] 0x00000000000000000000000000000062d32f53f2f7afe532c0372fd0cacdbd4b
    │   │   ├─ [2409] 0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821::price1CumulativeLast() [staticcall]
    │   │   │   └─ ← [Return] 0x000000000000000000000000000012d5e533107a3e9659278cb49bb1e692524d
    │   │   ├─ [2517] 0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821::getReserves() [staticcall]
    │   │   │   └─ ← [Return] 57699697019214999123 [5.769e19], 346096818479249535454 [3.46e20], 1648897434 [1.648e9]
    │   │   └─ ← [Return] 112898782017006089 [1.128e17], 509434 [5.094e5]
    │   └─ ← [Return] PriceDataPoint({ price: 112898782017006089 [1.128e17], timestamp: 509434 [5.094e5] })
    ├─ [0] VM::selectFork(1)
    │   └─ ← [Return]
    ├─ [273441] → new InverseFinanceAttackSimulation@0x2e234DAe75C793f67A35089C9d99245E1C58470b
    │   └─ ← [Return] 1034 bytes of code
    ├─ [25812] InverseFinanceAttackSimulation::collect() [staticcall]
    │   ├─ [22164] 0x39b1dF026010b5aEA781f90542EE19E900F2Db15::current(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68, 1000000000000000000 [1e18], 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) [staticcall]
    │   │   ├─ [2387] 0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821::price0CumulativeLast() [staticcall]
    │   │   │   └─ ← [Return] 0x00000000000000000000000000000062d3894d340469613c4358329edb42ef3e
    │   │   ├─ [2409] 0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821::price1CumulativeLast() [staticcall]
    │   │   │   └─ ← [Return] 0x000000000000000000000000000012d5e53590aa3ab82b1aad794db942e56b05
    │   │   ├─ [2517] 0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821::getReserves() [staticcall]
    │   │   │   └─ ← [Return] 303375213766854747866 [3.033e20], 65985333011771397510 [6.598e19], 1648897449 [1.648e9]
    │   │   └─ ← [Return] 5998243255315418667 [5.998e18], 15
    │   └─ ← [Return] PriceDataPoint({ price: 5998243255315418667 [5.998e18], timestamp: 15 })
    ├─ [273441] → new InverseFinanceAttackSimulation@0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
    │   └─ ← [Return] 1034 bytes of code
    ├─ [1491] InverseFinanceAttackSimulation::isValid([PriceDataPoint({ price: 112898782017006089 [1.128e17], timestamp: 509434 [5.094e5] }), PriceDataPoint({ price: 5998243255315418667 [5.998e18], timestamp: 15 })]) [staticcall]
    │   └─ ← [Return] false
    ├─ [0] VM::assertTrue(true) [staticcall]
    │   └─ ← [Return]
    └─ ← [Stop]
```

The test passes, confirming that the TWAP oracle trap successfully detects the price manipulation that occurred during the Inverse Finance attack. By analyzing the price data points before and during the exploit, the trap identifies a significant price deviation exceeding the specified threshold, triggering an alert for potential manipulation.

## Conclusion

The Inverse Finance attack highlights the importance of robust price oracles and the need for effective monitoring and detection mechanisms in DeFi protocols. By implementing a Drosera Trap, projects can proactively detect and prevent price manipulation attacks, enhancing the security and integrity of their systems.

At Drosera, we are pioneering the concept of "traps" as part of our automated real-time monitoring system. Our trap concepts, such as the TWAP oracle trap, are designed to continuously monitor critical data points and trigger functions or alerts when suspicious activities or anomalies are detected. By integrating these traps into DeFi protocols, we aim to provide an additional layer of security and help projects identify and respond to potential threats instantly.

While the proposed TWAP oracle trap serves as a proof-of-concept, it is important to note that a comprehensive security strategy should encompass multiple layers of defense. Drosera's automated real-time monitoring system complements other essential security measures, such as thorough smart contract audits.

By leveraging innovative solutions like Drosera's traps and learning from past incidents like the Inverse Finance attack, the DeFi community can continue to build a more resilient and trustworthy ecosystem.
