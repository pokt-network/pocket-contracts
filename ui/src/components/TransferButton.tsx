import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useSwitchChain,
} from "wagmi";
import { parseUnits, Address } from "viem";
import { Spinner } from "./Spinner";
import { useCallback } from "react";
import { BridgeRouteType, BridgeRoute } from "../bridgeRoute";
import { useEffect } from "react";
import { SetSuccessfulReceiptAction } from "./Bridge";
import { useState } from "react";

type TransferButtonProps = {
  address: Address;
  token: Address;
  chainId: number;
  amount: string;
  route: BridgeRoute;
  setSuccessfulReceipt: SetSuccessfulReceiptAction;
  bridgeCost: bigint | null;
};

const defaultButtonState = {
  isLoading: false,
  text: "Transfer",
  error: null as null | string,
};

export const TransferButton = ({
  amount,
  address,
  chainId,
  route,
  setSuccessfulReceipt,
  bridgeCost,
}: TransferButtonProps) => {
  const { switchChainAsync } = useSwitchChain();

  const [buttonState, setButtonState] = useState(defaultButtonState);

  const { data, writeContractAsync } = useWriteContract();

  const { data: receiptData, isLoading } = useWaitForTransactionReceipt({
    hash: data,
    chainId,
    confirmations: 1,
  });

  useEffect(() => {
    if (receiptData) {
      setSuccessfulReceipt(receiptData);
    }
  }, [receiptData]);

  const onButtonClick = useCallback(async () => {
    setButtonState({
      isLoading: true,
      text: "Switching chain...",
      error: null,
    });

    try {
      await switchChainAsync({ chainId });
    } catch (e) {
      setButtonState({
        ...defaultButtonState,
        error: `Unable to switch chain to Chain ID: ${chainId}.`,
      });
      return;
    }

    setButtonState({
      isLoading: true,
      text: "Waiting on signature...",
      error: null,
    });

    // POKT has 6 decimals!
    const parsedAmount = parseUnits(amount, 6);

    try {
      switch (route.type) {
        case BridgeRouteType.WORMHOLE_BRIDGE:
          await writeContractAsync({
            address: route.contract,
            abi: route.contractAbi,
            functionName: "bridge",
            args: [route.destChainWormholeId, parsedAmount, address],
            chainId,
            value: bridgeCost!,
          });
          break;
        case BridgeRouteType.LOCKBOX_DEPOSIT:
          await writeContractAsync({
            address: route.contract,
            abi: route.contractAbi,
            functionName: "deposit",
            args: [parsedAmount],
            chainId,
          });
          break;
        case BridgeRouteType.LOCKBOX_WITHDRAW:
          await writeContractAsync({
            address: route.contract,
            abi: route.contractAbi,
            functionName: "withdraw",
            args: [parsedAmount],
            chainId,
          });
          break;
        case BridgeRouteType.WPOKT_ROUTER:
          await writeContractAsync({
            address: route.contract,
            abi: route.contractAbi,
            functionName: "bridgeTo",
            args: [route.destChainWormholeId, parsedAmount],
            chainId,
            value: bridgeCost!,
          });
          break;
      }

      setButtonState(defaultButtonState);
    } catch (e: any) {
      setButtonState({
        ...defaultButtonState,
        error: (e && e.shortMessage) || e.message,
      });
    }
  }, [address, chainId, route, amount, bridgeCost]);

  const text = isLoading ? "Waiting for tx confirmation..." : buttonState.text;

  return (
    <>
      {buttonState.error ? (
        <div className="rounded-md mb-5">
          <div className="flex">
            <div className="text-sm text-red-300">
              <p className="break-all">Error: {buttonState.error}</p>
            </div>
          </div>
        </div>
      ) : null}
      <button
        onClick={onButtonClick}
        className="inline-flex items-center justify-center center py-3 px-4 text-lg font-bold whitespace-nowrap rounded bg-indigo-500 px-2 py-1 font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
      >
        {isLoading || buttonState.isLoading ? <Spinner /> : null}
        {text}
      </button>
    </>
  );
};
