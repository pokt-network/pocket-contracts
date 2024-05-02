import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createWeb3Modal } from "@web3modal/wagmi/react";

import { config } from "./config";
import { Bridge } from "./components/Bridge";
import { Navbar } from "./components/Navbar";
import { Layout } from "./components/Layout";

const queryClient = new QueryClient();

// id of walletconnect project
const projectId = "b3831478c9a8b250e80dce8f8ca29631";

createWeb3Modal({
  projectId,
  wagmiConfig: config,
  enableAnalytics: false, // Optional - defaults to your Cloud configuration
  enableOnramp: false, // Optional - false as default
});

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <Layout>
          <Navbar />
          <div className="flex-none w-full lg:w-96 space-y-14 visible text-secondary">
            <div style={{ opacity: 1, transform: "none" }}>
              <div className="space-y-2 p-4 rounded-2xl border border-box shadow bg-box">
                <Bridge />
              </div>
            </div>
          </div>
        </Layout>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
