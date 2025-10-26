# ContagionTrap

**Trap Name:** ContagionTrap  
**Author:** Bindoskii (MUJI)  
**License:** MIT  

##  Description
ContagionTrap monitors liquidity levels of a neighboring DEX pool to detect sharp liquidity drains that may indicate contagion or instability.  
It acts as an early warning mechanism that triggers a response when the newest liquidity snapshot drops below 50% of the recent average.

##  Trigger Logic
Collects reserve data (`reserve0 + reserve1`) from a UniswapV2 compatible pool.
Maintains a history of liquidity snapshots.
Compares the latest liquidity value to the average of previous snapshots.
- **Triggers** if:  
  `newest_liquidity * 2 < average_previous_liquidity` 

##  Action on Trigger
When triggered, the trap emits a response intended for Drosera responders  typically to **pause** the affected protocol or activate a containment mechanism.

##  Deployment Details
- **Network:** Hoodi Testnet (or simulated Foundry localnet)
- **Parameters:**  
  Replace `NEIGHBOR_DEX_POOL` with the target DEX pool address you want to monitor.
- **Setup:**  
  1. Deploy the contract using Foundry or Drosera’s CLI.  
  2. Register the trap on Drosera.  
  3. Define response logic for containment.

##  Testing
You can simulate falling liquidity by adjusting mock pool reserves in your Foundry tests.

##  License
MIT
