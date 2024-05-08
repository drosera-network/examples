# Proactive Price Manipulation Detection with a Drosera TWAP Oracle Trap

## Introduction

We dive into how a `TWAP Oracle Trap` can be used to detect and prevent price manipulation attacks in DeFi protocols using time-series data. We explore the concept of TWAP oracles, the vulnerabilities they face, and how a `TWAP Oracle Trap` can be implemented to safeguard against price manipulation on token pools with larger liquidity.

## Background

Price oracles play a crucial role in DeFi protocols, providing accurate and reliable price data for various assets. However, price oracles can be vulnerable to manipulation, where malicious actors attempt to artificially inflate or deflate asset prices for their own benefit.

This Drosera trap example showcases how it can continuously monitor price data from a TWAP oracle and compare it against predefined thresholds to identify sudden and significant price deviations, which may indicate potential manipulation attempts. This powerful time-series analysis tool can be integrated into DeFi protocols to detect and prevent price manipulation attacks.

[TWAP Oracle Attacks: Easier Done than Said](https://eprint.iacr.org/2022/445.pdf) is a great writeup about different types of Oracle attacks and how even with token pools with larger liquidity, it is still possible to multi-block MEV (MMEV) to manipulate the price of a token.

## The Attack

We will play out a scenario where an attacker manipulates the price of the `WETH/USDC` trading pair on Uniswap by executing a series of trades that artificially inflate the price of WETH relative to USDC. Because the pool has a large amount of liquidity, it becomes more difficult to manipulate the price, but the attacker uses a multi-block MEV (MMEV) strategy to achieve their goal. The article above goes into more detail about what would be needed to execute a `single-block` and `multi-block` MEV attack depending on the liquidity of the pool.

## TWAP Oracle Trap

To detect and prevent such price manipulation attacks, we can utilize Drosera's trap concept and create a trap to do time-series analysis on the price data from the TWAP oracle. The trap will continuously monitor the price data and compare it against predefined thresholds to identify any sudden and significant price deviations. If a deviation is detected, the trap will raise an alert, indicating a potential price manipulation attempt.

We have implemented a proof-of-concept TWAP oracle trap in Solidity, and a simulated test contract to demonstrate its effectiveness in detecting the price manipulation that occurred during this potential attack.

1. The `TWAPTrap.sol` contract:

- This contract interacts with a mock oracle to collect price data for each block.
- It provides a `collect` function that is used to retrieve mock oracle data.
- The `isValid` function analyzes an array of price data points and checks for any price deviations that exceed the specified threshold (deviationThreshold). If a deviation is detected, it returns `false`, indicating a potential price manipulation. We also provide the amount of blocks to do the time-series analysis on.

2. The `TWAPTrapTest` contract:

- This is a Foundry test contract that demonstrates how the TWAP oracle trap can be used to detect such manipulations.
- It creates a hundred block range to check over and mocks out a stable price average over the first 90 blocks.
- It then simulates a small manipulation in the last 10 blocks to show how the trap would detect the manipulation.
- If the `isValid` function returns `false`, indicating a price manipulation, the test passes.

## Results

The test passes during the initial 90 blocks and when the larger deviation starts to occur in the last 10 blocks, the test catches this and returns `isValid` to false.

To run the test, you can use the following command:

```bash
forge test -vvvvv
```

## Conclusion

The TWAP Oracle Trap demonstrates the effectiveness of proactive price manipulation detection in DeFi protocols. By continuously monitoring price data from TWAP oracles and performing time-series analysis, the trap can identify sudden and significant price deviations that may indicate potential manipulation attempts.
The example implementation and simulated test contract showcase how the TWAP Oracle Trap can be integrated into DeFi protocols to safeguard against price manipulation attacks, even in token pools with larger liquidity. The test results confirm that the trap successfully detects the simulated price manipulation, raising an alert when the price deviation exceeds the specified threshold.

The TWAP Oracle Trap is just one example of how Drosera's trap concept can be applied to enhance DeFi security. As we continue to explore and develop new trap implementations, we can further strengthen the defenses against various types of attacks and vulnerabilities.
