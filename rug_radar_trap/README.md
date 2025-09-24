# UniqueRug Radar Trap (PoC)

## Overview  
This is a **proof of concept trap** idea for the Drosera ecosystem.  
This trap monitors unusual changes in the **total supply** of an ERC-20 token.  
A sudden drop in supply can be a red flag for manipulations or hidden risks.  

## How It Works  
- `collect()` → Reads `totalSupply()` from the token contract.  
- `shouldRespond()` → Compares consecutive values.  
   - If supply decreases by **15%**, it triggers a response.  

## Example Test Log
collect() #1 → totalSupply: 1,000,000
collect() #2 → totalSupply: 850,000
shouldRespond([#1, #2]) → true (drop 15%)

⚠️ *These logs are test/example values only — no live tokens were used.*  

## Why It Matters  
- Sudden supply drops may indicate **burn exploits, hidden logic, or rug-pull patterns**.  
- Helps illustrate how Drosera traps can highlight **token integrity risks**.  

## Benefits  
- **Developers:** Quick detection of abnormal token behavior.  
- **Auditors:** Structured on-chain data for analysis.  
- **Users:** Early warning of potential manipulations.
