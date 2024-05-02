import {
  useWriteContract,
  useWaitForTransactionReceipt,
  useSwitchChain,
} from "wagmi";
import { Address, erc20Abi, maxUint256 } from "viem";
import { Spinner } from "./Spinner";
import { useCallback } from "react";
import { useEffect } from "react";
import { useState } from "react";

type ApproveButtonProps = {
  refetchAllowance: () => void;
  address: Address;
  token: Address;
  spender: Address;
  chainId: number;
};

const defaultButtonState = {
  isLoading: false,
  text: "Approve",
  error: null as null | string,
};

export const ApproveButton = ({
  token,
  address,
  chainId,
  spender,
  refetchAllowance,
}: ApproveButtonProps) => {
  const { switchChainAsync } = useSwitchChain();
  const { data, writeContractAsync } = useWriteContract();

  const [buttonState, setButtonState] = useState(defaultButtonState);

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

    try {
      await writeContractAsync({
        address: token,
        abi: erc20Abi,
        functionName: "approve",
        args: [spender, maxUint256],
        chainId,
      });
      setButtonState(defaultButtonState);
    } catch (e: any) {
      setButtonState({
        ...defaultButtonState,
        error: (e && e.shortMessage) || e.message,
      });
    }
  }, [token, address, chainId, spender]);

  const { data: receiptData, isLoading } = useWaitForTransactionReceipt({
    hash: data,
    confirmations: 2,
    chainId,
  });

  useEffect(() => {
    if (receiptData) {
      refetchAllowance();
    }
  }, [receiptData]);

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
        className="inline-flex items-center justify-center center py-3 px-4 text-lg font-bold whitespace-nowrap rounded bg-indigo-500 px-2 py-1 font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500 disabled:cursor-not-allowed disabled:bg-gray-400"
      >
        {isLoading || buttonState.isLoading ? <Spinner /> : null}
        {text}
      </button>
    </>
  );
};
