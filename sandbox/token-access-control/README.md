# Drosera Trap Foundry Template

For quickly bootstrapping a new Drosera project.

[![view - Documentation](https://img.shields.io/badge/view-Documentation-blue?style=for-the-badge)](https://dev.drosera.io "Project documentation")

## Overview
This template shows an example of monitoring a Uniswap V3 liquidity pool. The UniswapV3PoolTrap smart contract checks to see if the balance of the pool has changed by more than 20% from the previous block.

## Features
- example trap contract 
- example trap test

## Getting Started

```bash
mkdir my-drosera-trap
cd my-drosera-trap
forge init trap-foundry-template
```

## Testing
```bash
forge test
```
