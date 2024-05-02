import {
  Token,
  WPOKT_CONTRACT,
  PROXY_LOCKBOX,
  PROXY_WORMHOLE,
  ROUTER_WPOKT,
  networks,
  Network,
} from "./config";
import { WPoktRouterAbi, WormholeBridgeAbi, LockboxAbi } from "./abi";
import { Address, Abi } from "viem";
import {
  sepolia,
  baseSepolia,
  arbitrumSepolia,
  optimismSepolia,
} from "wagmi/chains";

export enum BridgeRouteType {
  LOCKBOX_DEPOSIT = "LOCKBOX_DEPOSIT",
  LOCKBOX_WITHDRAW = "LOCKBOX_WITHDRAW",
  WPOKT_ROUTER = "WPOKT_ROUTER",
  WORMHOLE_BRIDGE = "WORMHOLE_BRIDGE",
}

export type BridgeRoute = {
  network: Network;
  destChainId: number;
  destChainWormholeId: number;
  contract: Address;
  contractAbi: Abi;
  feeRequired: boolean;
  type: BridgeRouteType;
};

const wormholeChainIds: Record<number, number> = {
  [sepolia.id]: 10002,
  [baseSepolia.id]: 10004,
  [optimismSepolia.id]: 10005,
  [arbitrumSepolia.id]: 10003,
};

// directions
// WPOKT -> XPOKT (same chain using lockbox)
// XPOKT -> WPOKT (same chain using lockbox)
// WPOKT -> XPOKT (multi-chain using router)
// XPOKT -> XPOKT (multi-chain direct bridge)

export const bridgeRoute = (from: Token, to: Token): BridgeRoute => {
  if (!wormholeChainIds[to.chainId]) {
    throw new Error("Unsupported destination chain");
  }

  console.log("formatters", sepolia.nativeCurrency);

  const base = {
    network: networks[from.network],
    destChainId: to.chainId,
    destChainWormholeId: wormholeChainIds[to.chainId],
  };

  // multichain bridge using same token address (XERC20)
  if (from.contract === to.contract) {
    return {
      ...base,
      contract: PROXY_WORMHOLE,
      contractAbi: WormholeBridgeAbi,
      feeRequired: true,
      type: BridgeRouteType.WORMHOLE_BRIDGE,
    };
  }

  // wPOKT to XERC20 on the same chain
  if (from.contract === WPOKT_CONTRACT && from.chainId === to.chainId) {
    return {
      ...base,
      contract: PROXY_LOCKBOX,
      contractAbi: LockboxAbi,
      feeRequired: false,
      type: BridgeRouteType.LOCKBOX_DEPOSIT,
    };
  }

  // XERC20 to wPOKT on the same chain
  if (to.contract === WPOKT_CONTRACT && from.chainId === to.chainId) {
    return {
      ...base,
      contract: PROXY_LOCKBOX,
      contractAbi: LockboxAbi,
      feeRequired: false,
      type: BridgeRouteType.LOCKBOX_WITHDRAW,
    };
  }

  // wPOKT to external chain, using router contract
  if (from.contract === WPOKT_CONTRACT) {
    return {
      ...base,
      contract: ROUTER_WPOKT,
      contractAbi: WPoktRouterAbi,
      feeRequired: true,
      type: BridgeRouteType.WPOKT_ROUTER,
    };
  }

  throw new Error("No such route");
};
