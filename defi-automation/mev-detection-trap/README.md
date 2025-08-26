# MEV Detection Trap

A comprehensive system of smart contract traps for detecting and responding to MEV (Maximal Extractable Value) activities on Ethereum and other EVM-compatible chains.


Common MEV activities include:
- **Sandwich Attacks**: Front-running and back-running large trades
- **Arbitrage**: Exploiting price differences across DEXs
- **Liquidation**: Profiting from liquidated positions
- **Front-running**: Executing trades before others based on pending transactions

## 🚀 Features

### 1. **MEVDetectionTrap** - General MEV Detection
- **Multi-DEX Monitoring**: Tracks multiple decentralized exchanges simultaneously
- **Pattern Recognition**: Identifies various MEV patterns using time-series analysis
- **Configurable Thresholds**: Adjustable parameters for different detection sensitivity
- **Real-time Alerts**: Immediate notification when MEV activities are detected

### 2. **SandwichAttackTrap** - Specialized Sandwich Detection
- **Advanced Pattern Recognition**: Sophisticated algorithms for detecting sandwich attacks
- **Historical Data Analysis**: Uses historical trading data for pattern validation
- **Volume Analysis**: Monitors unusual volume spikes and ratios
- **Timing Analysis**: Detects transactions that are suspiciously close together

### 3. **MEVResponse** - Automated Response System
- **Multi-Strategy Responses**: Different response strategies for different MEV types
- **Rate Limiting**: Configurable cooldown periods and execution limits
- **Emergency Controls**: Ability to pause responses in emergency situations
- **Event Logging**: Comprehensive logging of all detected activities and responses

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   MEV Traps     │    │  Drosera        │    │   Response      │
│                 │    │  Protocol       │    │   Contracts     │
│ • Collect Data  │───▶│ • Run Logic     │───▶│ • Execute       │
│ • Analyze       │    │ • Monitor       │    │ • Alert         │
│ • Detect        │    │ • Trigger       │    │ • Respond       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📊 Detection Capabilities

### Sandwich Attack Detection
- **Volume Pattern Analysis**: Detects small → large → small trade patterns
- **Price Impact Monitoring**: Tracks significant price movements
- **Timing Analysis**: Identifies transactions executed in rapid succession
- **Gas Price Spikes**: Monitors for unusual gas price increases

### Arbitrage Opportunity Detection
- **Cross-DEX Price Monitoring**: Tracks price differences across exchanges
- **Threshold-Based Alerts**: Configurable profit thresholds
- **Real-time Analysis**: Continuous monitoring of arbitrage opportunities

### MEV Bot Activity Detection
- **Gas Price Anomalies**: Detects unusually high gas prices
- **Transaction Timing**: Identifies rapid successive transactions
- **Pattern Recognition**: Recognizes typical MEV bot behavior

### Suspicious Pattern Detection
- **Volume Anomalies**: Detects unusual trading volume patterns
- **Statistical Analysis**: Uses statistical methods to identify outliers
- **Multi-Factor Analysis**: Combines multiple indicators for detection

## 🛠️ Installation & Setup

### Prerequisites
- [Foundry](https://getfoundry.sh/) (latest version)
- Node.js 16+ and npm/yarn
- Access to Ethereum RPC endpoints

### Quick Start

1. **Install Dependencies**
```bash
forge install
```

2. **Build Contracts**
```bash
forge build
```

3. **Run Tests**
```bash
forge test
```

### Threshold Configuration

The traps use configurable thresholds that can be adjusted based on your needs:

```solidity
// MEVDetectionTrap thresholds
uint256 constant MIN_SANDWICH_THRESHOLD = 0.5e18;      // 50% price impact
uint256 constant MAX_ARBITRAGE_THRESHOLD = 0.02e18;    // 2% arbitrage threshold
uint256 constant MIN_MEV_PROFIT_THRESHOLD = 0.1e18;    // 0.1 ETH minimum profit
uint256 constant SUSPICIOUS_GAS_THRESHOLD = 1000;      // 1000 gwei gas price

// SandwichAttackTrap thresholds
uint256 constant MIN_PRICE_IMPACT = 0.1e18;            // 10% minimum price impact
uint256 constant MAX_TIME_BETWEEN_TXS = 3;             // 3 seconds max between transactions
uint256 constant MIN_VOLUME_RATIO = 5;                 // 5x volume ratio threshold
uint256 constant SUSPICIOUS_GAS_MULTIPLIER = 2;        // 2x gas price multiplier
```

## 🔧 Usage Examples

### Adding Monitored DEXs

```solidity
// Add a new DEX to monitor
mevTrap.addMonitoredDEX(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap V2
mevTrap.addMonitoredDEX(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Uniswap V3
```

### Adding Known MEV Bots

```solidity
// Add known MEV bot addresses for tracking
mevTrap.addKnownMEVBot(0x1234567890123456789012345678901234567890);
```

### Event Logging

All activities are logged with comprehensive events:

```solidity
event SandwichAttackDetected(
    uint256 indexed blockNumber,
    uint256 timestamp,
    address[] involvedAddresses,
    uint256 estimatedProfit
);

event ResponseExecuted(
    uint256 indexed blockNumber,
    MEVType mevType,
    bytes responseData
);
```