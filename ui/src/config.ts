import { http, createConfig } from "wagmi";
import {
  sepolia,
  baseSepolia,
  arbitrumSepolia,
  optimismSepolia,
} from "wagmi/chains";
import {
  EthereumCircleColorful,
  OptimismCircleColorful,
  ArbitrumCircleColorful,
  BaseCircleColorful,
} from "@ant-design/web3-icons";
import { Address } from "viem";

export const config = createConfig({
  chains: [sepolia, baseSepolia, arbitrumSepolia, optimismSepolia],
  transports: {
    [sepolia.id]: http('https://sepolia.rpc.grove.city/v1/62582485981a020039584cdd'),
    [baseSepolia.id]: http(),
    [arbitrumSepolia.id]: http('https://arbitrum-sepolia-archival.rpc.grove.city/v1/62582485981a020039584cdd'),
    [optimismSepolia.id]: http('https://optimism-sepolia-archival.rpc.grove.city/v1/62582485981a020039584cdd'),
  },
});

const explorers: Record<number, string> = {
    [sepolia.id]: "https://sepolia.etherscan.io",
    [baseSepolia.id]: "https://sepolia.basescan.org",
    [arbitrumSepolia.id]: "https://sepolia.arbiscan.io",
    [optimismSepolia.id]: "https://sepolia-optimism.etherscan.io",
}

export const getTxDetailUrl = (chainId: number, tx: string) => {
    if (!explorers[chainId]) {
        throw new Error("Unsupported chain");
    }

    return `${explorers[chainId]}/tx/${tx}`;
};

export type ChainNativeCurrency = {
    name: string
    /** 2-6 characters long */
    symbol: string
    decimals: number
  }


export type Network = {
    nativeCurrency: ChainNativeCurrency;
    chainId: number;
    logo: string;
    icon: any;
    name: string;
}
export const networks: Record<string, Network> = {
  sepolia: {
    logo: "/networks/ethereum3.svg",
    icon: EthereumCircleColorful,
    name: "Ethereum Sepolia",
    chainId: sepolia.id,
    nativeCurrency: sepolia.nativeCurrency,
  },
  optimismSepolia: {
    logo: "/networks/optimism.svg",
    name: "Optimism Sepolia",
    icon: OptimismCircleColorful,
    chainId: optimismSepolia.id,
    nativeCurrency: optimismSepolia.nativeCurrency,
  },
  arbitrumSepolia: {
    logo: "/networks/arbitrum.svg",
    name: "Arbitrum Sepolia",
    icon: ArbitrumCircleColorful,
    chainId: arbitrumSepolia.id,
    nativeCurrency: arbitrumSepolia.nativeCurrency,
  },
  baseSepolia: {
    logo: "/networks/base.svg",
    name: "Base Sepolia",
    icon: BaseCircleColorful,
    chainId: baseSepolia.id,
    nativeCurrency: baseSepolia.nativeCurrency,
  },
};

export type NetworkName = keyof typeof networks;

export type Token = {
  symbol: string;
  contract: Address;
  network: NetworkName;
  chainId: number;
};

export const WPOKT_CONTRACT: Address = "0x50AcB08D20d91B08A443b762cE8Ab50ad00a0635";
export const XERC20_CONTRACT: Address = "0xf751E222C75462342748Dd68b3463a14C1E23555";
export const PROXY_WORMHOLE: Address = "0x48B02a246861Abb10166D383787689793b1A51a6";
export const PROXY_LOCKBOX: Address = "0xA4e8d8A848b51F3464B3E55d3eD329E4C19631b9";
export const ROUTER_WPOKT: Address = "0x0339F6e6dec5a13d8D60eb18a46a8AF4e5Ad12AD";

export const tokens = [
  {
    symbol: "WPOKT",
    network: "sepolia" as NetworkName,
    contract: WPOKT_CONTRACT ,
    chainId: sepolia.id as number,
  },
].concat(
  ...Object.entries(networks).map(
    ([network, cfg]) =>
      ({
        symbol: "POKT",
        // POKT has same address across all networks
        contract: XERC20_CONTRACT,
        network,
        chainId: cfg.chainId,
      } as Token)
  )
);
