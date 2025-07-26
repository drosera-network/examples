// src/LiveBoard.tsx
import React, { useEffect, useState } from 'react';
import { JsonRpcProvider, Contract } from 'ethers';

const LiveBoard: React.FC = () => {
  const [names, setNames] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const pageSize = 25;

  useEffect(() => {
    const fetchNames = async () => {
      try {
        const provider = new JsonRpcProvider("https://ethereum-holesky-rpc.publicnode.com/");
        const abi = [
          "function getDiscordNamesBatch(uint256 start, uint256 end) view returns (string[])"
        ];
        const contract = new Contract(
          "0x4608Afa7f277C8E0BE232232265850d1cDeB600E",
          abi,
          provider
        );

        const result = await contract.getDiscordNamesBatch(0, 2000);
        const filtered = result.filter((name: string) => name && name !== "DISCORD_USERNAME");
        setNames(filtered);
      } catch (err) {
        console.error("Failed to fetch names", err);
      } finally {
        setLoading(false);
      }
    };

    fetchNames();
  }, []);

  const filtered = names.filter(name => name.toLowerCase().includes(search.toLowerCase()));
  const paginated = filtered.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="bg-gray-800 p-6 rounded">
      <h2 className="text-2xl mb-4">🏅 Proof-of-Trap – Cadet LiveBoard</h2>

      <input
        type="text"
        placeholder="Search Discord usernames..."
        value={search}
        onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        className="mb-4 w-full p-2 rounded bg-gray-700 text-white"
      />

      {loading ? (
        <p className="text-gray-400">Loading real-time data from Drosera testnet...</p>
      ) : (
        filtered.length > 0 ? (
          <>
            <ul className="text-gray-200 list-disc list-inside max-h-64 overflow-y-auto mb-4">
              {paginated.map((name, idx) => (
                <li key={idx}>{name}</li>
              ))}
            </ul>
            <div className="flex justify-between text-sm text-gray-400">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="px-3 py-1 bg-gray-700 rounded disabled:opacity-50"
              >
                Previous
              </button>
              <span>Page {page} of {Math.ceil(filtered.length / pageSize)}</span>
              <button
                onClick={() => setPage((p) => p + 1)}
                disabled={page * pageSize >= filtered.length}
                className="px-3 py-1 bg-gray-700 rounded disabled:opacity-50"
              >
                Next
              </button>
            </div>
          </>
        ) : (
          <p className="text-gray-400">No active responders found.</p>
        )
      )}
    </div>
  );
};

export default LiveBoard;
