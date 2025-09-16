# Rug Radar Trap (PoC)

This is a **proof of concept trap** idea for the Drosera ecosystem.  
It demonstrates how a tool could scan ERC-20 token contracts for potential rug-pull indicators.

## What it does
- Connects to Ethereum via RPC
- Checks who the contract `owner` is
- Fetches the total token supply
- Warns if certain info is missing (which could be a red flag)

## How to Run
1. Install Web3:
   ```bash
   pip install web3
   2. Run the script:
   python rug_radar.py

## Notes
- This is a minimal PoC, **not a full rug detector**.
- Future improvements could include:
  - Checking for mint/blacklist functions
  - Detecting high owner liquidity control
  - Monitoring sudden changes in trading settings
  - 
