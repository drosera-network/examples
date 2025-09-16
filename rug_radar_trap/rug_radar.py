# rug_radar.py
# Rug Radar Trap PoC for Drosera
#
# This script is a simple proof-of-concept to detect possible rug-pull risks
# in ERC-20 token contracts.

from web3 import Web3

# Connect to Ethereum RPC (you can change this to another RPC if you like)
w3 = Web3(Web3.HTTPProvider("https://rpc.ankr.com/eth"))

# Example token contract (replace with any ERC-20 address you want to test)
token_address = Web3.to_checksum_address("0x0000000000000000000000000000000000000000")

# Minimal ABI to check ERC-20 details
erc20_abi = [
    {"constant": True, "inputs": [], "name": "owner", "outputs": [{"name": "", "type": "address"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "totalSupply", "outputs": [{"name": "", "type": "uint256"}], "type": "function"},
]

try:
    contract = w3.eth.contract(address=token_address, abi=erc20_abi)

    # Check owner
    try:
        owner = contract.functions.owner().call()
        print(f"Owner address: {owner}")
    except Exception:
        print("⚠️ Could not fetch owner (might be hidden or renounced)")

    # Check total supply
    try:
        supply = contract.functions.totalSupply().call()
        print(f"Total Supply: {supply}")
    except Exception:
        print("⚠️ Could not fetch total supply")

    print("✅ Rug Radar scan completed (PoC)")

except Exception as e:
    print("Error connecting to contract:", e)
