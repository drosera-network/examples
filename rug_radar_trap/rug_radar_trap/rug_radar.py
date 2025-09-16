# rug_radar.py
# Rug Radar Trap PoC for Drosera

from web3 import Web3

w3 = Web3(Web3.HTTPProvider("https://rpc.ankr.com/eth"))
token_address = Web3.to_checksum_address("0x0000000000000000000000000000000000000000")

erc20_abi = [
    {"constant": True, "inputs": [], "name": "owner", "outputs": [{"name": "", "type": "address"}], "type": "function"},
    {"constant": True, "inputs": [], "name": "totalSupply", "outputs": [{"name": "", "type": "uint256"}], "type": "function"},
]

try:
    contract = w3.eth.contract(address=token_address, abi=erc20_abi)

    try:
        owner = contract.functions.owner().call()
        print(f"Owner address: {owner}")
    except Exception:
        print("⚠️ Could not fetch owner")

    try:
        supply = contract.functions.totalSupply().call()
        print(f"Total Supply: {supply}")
    except Exception:
        print("⚠️ Could not fetch total supply")

    print("✅ Rug Radar scan completed (PoC)")

except Exception as e:
    print("Error connecting to contract:", e)
