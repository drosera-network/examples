// Drosera Trap Simulator with Tabs for LiveBoard
import React, { useState, useRef } from 'react';
import Editor from '@monaco-editor/react';
import './index.css';
import LiveBoard from './LiveBoard';

function App() {
  const trapPresets = [
    {
      label: "🚨 Bridge Exploit",
      logic: `async function trap(event) {
  if (event.type === "bridge" && event.amount > 100000 && event.to === "0xdeadbeef") {
    return "🚨 Potential bridge exploit!";
  }
}`,
      event: `{
  "type": "bridge",
  "amount": 150000,
  "to": "0xdeadbeef",
  "timestamp": ${Date.now()}
}`
    },
    {
      label: "🌀 ETH High Slippage",
      logic: `async function trap(event) {
  if (event.token === "ETH" && event.amount > 1000 && event.slippage > 5) {
    return "🌀 Large ETH swap with high slippage!";
  }
}`,
      event: `{
  "type": "swap",
  "token": "ETH",
  "amount": 1200,
  "slippage": 7,
  "timestamp": ${Date.now()}
}`
    },
    {
      label: "🌒 Off-Hour Transaction",
      logic: `async function trap(event) {
  const hour = new Date(event.timestamp).getUTCHours();
  if (hour >= 0 && hour <= 3 && event.amount > 10000) {
    return "🌒 Suspicious large txn during off-hours!";
  }
}`,
      event: `{
  "amount": 12000,
  "timestamp": ${(() => {
    const d = new Date();
    d.setUTCHours(Math.floor(Math.random() * 4), 0, 0, 0);
    return d.getTime();
  })()}
}`
    },
    {
      label: "📉 Oracle Price Drop",
      logic: `async function trap(event) {
  if (event.asset === "BTC" && event.oraclePrice < 20000) {
    return "📉 Oracle price dropped significantly!";
  }
}`,
      event: `{
  "type": "oracle",
  "asset": "BTC",
  "oraclePrice": 19500,
  "timestamp": ${Date.now()}
}`
    },
    {
      label: "⚔️ AVS Slashing",
      logic: `async function trap(event) {
  if (event.avs === "staking" && event.slashAmount > 5000) {
    return "⚔️ AVS slashing triggered!";
  }
}`,
      event: `{
  "type": "slashing",
  "avs": "staking",
  "slashAmount": 6000,
  "timestamp": ${Date.now()}
}`
    },
    {
      label: "🛑 DEX Liquidity Drop",
      logic: `async function trap(event) {
  if (event.pool === "DEX-XYZ" && event.liquidityUSD < 1000000) {
    return "🛑 Liquidity has dropped dangerously low on DEX!";
  }
}`,
      event: `{
  "type": "liquidity",
  "pool": "DEX-XYZ",
  "liquidityUSD": 800000,
  "timestamp": ${Date.now()}
}`
    },
    {
      label: "🏦 Lending Collateral Event",
      logic: `async function trap(event) {
  if (event.collateralRatio < 1.2 && event.loanId) {
    return "🏦 Lending collateral ratio below threshold!";
  }
}`,
      event: `{
  "type": "loan",
  "loanId": "LN-1234",
  "collateralRatio": 1.1,
  "timestamp": ${Date.now()}
}`
    }
  ];

  const presetIndexRef = useRef(0);
  const [trapLogic, setTrapLogic] = useState(trapPresets[0].logic);
  const [simulatedEvent, setSimulatedEvent] = useState(trapPresets[0].event);
  const [output, setOutput] = useState<{ triggered: boolean; message: string } | null>(null);
  const [activeTab, setActiveTab] = useState<'simulator' | 'liveboard'>('simulator');

  const handleRunTrap = async () => {
    try {
      const event = JSON.parse(simulatedEvent);
      const fullCode = `(async () => { ${trapLogic}; return await trap(${JSON.stringify(event)}); })()`;
      const result = await eval(fullCode);

      if (result) {
        setOutput({ triggered: true, message: result });
      } else {
        setOutput({ triggered: false, message: "Trap NOT TRIGGERED" });
      }
    } catch (error: any) {
      setOutput({ triggered: false, message: `Error: ${error.message}` });
    }
  };

  const generateTrapAndEvent = () => {
    presetIndexRef.current = (presetIndexRef.current + 1) % trapPresets.length;
    const preset = trapPresets[presetIndexRef.current];
    setTrapLogic(preset.logic);
    setSimulatedEvent(preset.event);
    setOutput(null);
  };

  const handleDropdownChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const index = Number(e.target.value);
    const preset = trapPresets[index];
    presetIndexRef.current = index;
    setTrapLogic(preset.logic);
    setSimulatedEvent(preset.event);
    setOutput(null);
  };

  return (
    <div className="bg-gray-900 min-h-screen text-white p-6 font-mono">
      <div className="flex items-center justify-center mb-6">
        <img src="/drosera-logo.png" alt="Drosera Logo" className="w-8 h-8 mr-3" />
        <h1 className="text-3xl font-bold">Drosera Trap Simulator <span className="text-sm text-gray-400 ml-2">(Unofficial)</span></h1>
      </div>

      <div className="flex justify-center gap-4 mb-6">
        <button onClick={() => setActiveTab('simulator')} className={`px-4 py-2 rounded ${activeTab === 'simulator' ? 'bg-indigo-600' : 'bg-gray-700'}`}>Simulator</button>
        <button onClick={() => setActiveTab('liveboard')} className={`px-4 py-2 rounded ${activeTab === 'liveboard' ? 'bg-indigo-600' : 'bg-gray-700'}`}>Proof-of-Trap</button>
      </div>

      {activeTab === 'simulator' ? (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <h2 className="text-xl mb-2">🧠 Trap Logic</h2>
              <Editor
                height="300px"
                defaultLanguage="javascript"
                value={trapLogic}
                onChange={(val) => setTrapLogic(val || '')}
                theme="vs-dark"
              />
            </div>
            <div>
              <h2 className="text-xl mb-2">🧱 Simulated Event</h2>
              <Editor
                height="300px"
                defaultLanguage="json"
                value={simulatedEvent}
                onChange={(val) => setSimulatedEvent(val || '')}
                theme="vs-dark"
              />
            </div>
          </div>

          <div className="flex flex-col items-center mb-4">
            <select
              className="bg-gray-800 text-white p-2 rounded mb-1"
              onChange={handleDropdownChange}
              value={presetIndexRef.current}
            >
              {trapPresets.map((preset, index) => (
                <option key={index} value={index}>{preset.label}</option>
              ))}
            </select>
            <span className="text-gray-300">(or)</span>
          </div>

          <div className="flex flex-wrap gap-4 justify-center mb-4">
            <button
              onClick={generateTrapAndEvent}
              className="bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded text-white font-bold"
            >
              🧪 Generate Trap + Event
            </button>
            <button
              onClick={handleRunTrap}
              className="bg-green-600 hover:bg-green-700 px-4 py-2 rounded text-white font-bold"
            >
              🚀 Run Trap
            </button>
          </div>

          {output && (
            <div className="bg-gray-800 p-4 rounded text-lg">
              <span className="font-bold">Result:</span>
              <span className={output.triggered ? "text-green-400" : "text-pink-400"}> {output.message}</span>
            </div>
          )}
        </>
      ) : (
        <LiveBoard />
      )}

      <footer className="mt-8 text-center text-sm text-gray-400">
        Developed by <a href="https://x.com/xtestnet" className="underline text-blue-400">@xtestnet</a>
      </footer>
    </div>
  );
}

export default App;
