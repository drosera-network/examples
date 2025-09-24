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
    {
        "constant": True,
        "inputs": [],
        "name": "owner",
        "outputs": [{"name": "", "type": "address"}],
        "type": "function",
    },
    {
        "constant": True,
        "inputs": [],
        "name": "totalSupply",
        "outputs": [{"name": "", "type": "uint256"}],
        "type": "function",
    },
]

def scan_contract(address):
    """
    Scans an ERC-20 contract for owner and totalSupply.

    Parameters:
        address (str): The ERC-20 token contract address.

    Returns:
        dict: Contains 'owner' and 'totalSupply' or None if data cannot be fetched.
    """
    try:
        contract = w3.eth.contract(address=address, abi=erc20_abi)

        # Check owner
        try:
            owner = contract.functions.owner().call()
            print(f"Owner address: {owner}")
        except Exception:
            owner = None
            print("⚠️ Could not fetch owner (might be hidden or renounced)")

        # Check total supply
        try:
            supply = contract.functions.totalSupply().call()
            print(f"Total Supply: {supply}")
        except Exception:
            supply = None
            print("⚠️ Could not fetch total supply")

        print("✅ Rug Radar scan completed (PoC)")
        return {"owner": owner, "totalSupply": supply}

    except Exception as e:
        print("Error connecting to contract:", e)
        return None


# Run scan
if __name__ == "__main__":
    scan_contract(token_address)
