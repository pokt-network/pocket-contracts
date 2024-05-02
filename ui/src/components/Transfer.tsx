import React from "react";

import { useAccount } from "wagmi";

import { NetworkName } from "../config";
import { TokenBalanceRow } from "./TokenBalanceRow";
import { ActionBox } from "./ActionBox";
import { ConnectWalletButton } from "./ConnectWalletButton";
import { BridgeRoute } from "../bridgeRoute";
import { NetworkPicker } from "./NetworkPicker";
import {
  BalanceState,
  BridgeCostState,
  SelectingTokenState,
  TransferState,
  SetSuccessfulReceiptAction
} from "./Bridge";
import { Spinner } from "./Spinner";
import { formatUnits } from "viem";

export type NetworkProps = { network: NetworkName };

type TransferProps = {
  transferState: TransferState;
  setSelectingToken: (state: SelectingTokenState) => void;
  swapTransferState: () => void;
  setAmount: (amount: string) => void;
  amount: string;
  canSwapSides: boolean;
  bridgeCostState: BridgeCostState;
  balanceFromState: BalanceState;
  balanceToState: BalanceState;
  route: BridgeRoute;
  setSuccessfulReceipt: SetSuccessfulReceiptAction;
};

export function Transfer({
  transferState,
  setSelectingToken,
  amount,
  setAmount,
  swapTransferState,
  canSwapSides,
  balanceToState,
  balanceFromState,
  bridgeCostState,
  route,
  setSuccessfulReceipt,
}: TransferProps) {
  const { address, isDisconnected } = useAccount();

  const { nativeCurrency } = route.network;

  const updateAmount = (e: React.ChangeEvent<HTMLInputElement>) => {
    // match if value is valid decimal number with dot and maximum of 6 decimals
    if (e.target.value.match(/^\d+(\.\d{0,6})?$/)) {
      console.log("setting amount", e.target.value);
      setAmount(e.target.value);
    }

    if (e.target.value === "") {
      setAmount("");
    }
  };

  const setMaxAmount = () => {
    if (balanceFromState.balance) {
      setAmount(
        formatUnits(
          balanceFromState.balance.value,
          balanceFromState.balance.decimals
        )
      );
    }
  };

  return (
    <>
      <div className="flex flex-col pt-3">
        <div className="flex flex-col border border-box bg-inner rounded-lg">
          <div className="text-xs flex flex-col overflow-hidden text-grey-400">
            <div className="flex flex-row space-x-2 items-center py-2 border-b px-3  border-box">
              <span>From</span>
              <NetworkPicker
                network={transferState.from.network}
                onClick={() => setSelectingToken(SelectingTokenState.FROM)}
              />
            </div>
          </div>
          <h1 className="text-xs text-grey-400 px-3 pt-3">Amount</h1>
          <div
            className="flex items-center px-1
        false"
          >
            <input
              className="flex-grow w-full p-2 text-2xl text-primary font-mono font-extralight border-none rounded-lg outline-none placeholder-primary bg-transparent"
              autoCorrect="off"
              inputMode="decimal"
              min="0.00"
              step="0.01"
              pattern="[0-9,.]*"
              placeholder="0.00"
              spellCheck="false"
              type="text"
              value={amount || ""}
              onChange={updateAmount}
            />

            {balanceFromState.balance ? (
              <button
                onClick={setMaxAmount}
                className="center py-1 px-3 text-primary text-sm font-bold whitespace-nowrap rounded-lg disabled:cursor-not-allowed inline-flex px-3 py-1 mx-2 my-2 border rounded-[15px]  font-extralight"
              >
                MAX
              </button>
            ) : null}
          </div>

          <TokenBalanceRow
           symbol={transferState.from.symbol}
           state={balanceFromState}
          />
        </div>
        <div className="text-xs text-grey-400 mt-1 justify-between flex"></div>
        <span className="flex justify-center py-2">
          <span
            onClick={canSwapSides ? swapTransferState : undefined}
            title={
              canSwapSides ? undefined : "Cannot use WPOKT as destination."
            }
            className={`group transition-colors duration-300 p-1 hover:bg-inverted/5 rounded-full ${
              canSwapSides ? "cursor-pointer" : "cursor-not-allowed"
            }`}
          >
            <svg
              stroke="currentColor"
              fill="currentColor"
              stroke-width="0"
              viewBox="0 0 24 24"
              className="group-hover:hidden"
              height="30"
              width="30"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path fill="none" d="M0 0h24v24H0z"></path>
              <path d="M18 6.41L16.59 5 12 9.58 7.41 5 6 6.41l6 6z"></path>
              <path d="M18 13l-1.41-1.41L12 16.17l-4.59-4.58L6 13l6 6z"></path>
            </svg>
            <svg
              stroke="currentColor"
              fill="none"
              stroke-width="0"
              viewBox="0 0 24 24"
              className="hidden group-hover:flex"
              height="30"
              width="30"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M12.9841 4.99255C12.9841 4.44027 13.4318 3.99255 13.9841 3.99255C14.3415 3.99255 14.6551 4.18004 14.8319 4.46202L17.5195 7.14964C17.9101 7.54016 17.9101 8.17333 17.5195 8.56385C17.129 8.95438 16.4958 8.95438 16.1053 8.56385L14.9841 7.44263V14.9926C14.9841 15.5448 14.5364 15.9926 13.9841 15.9926C13.4318 15.9926 12.9841 15.5448 12.9841 14.9926V5.042C12.984 5.03288 12.984 5.02376 12.9841 5.01464V4.99255Z"
                fill="currentColor"
              ></path>
              <path
                d="M11.0159 19.0074C11.0159 19.5597 10.5682 20.0074 10.0159 20.0074C9.6585 20.0074 9.3449 19.82 9.16807 19.538L6.48045 16.8504C6.08993 16.4598 6.08993 15.8267 6.48045 15.4361C6.87098 15.0456 7.50414 15.0456 7.89467 15.4361L9.01589 16.5574V9.00745C9.01589 8.45516 9.46361 8.00745 10.0159 8.00745C10.5682 8.00745 11.0159 8.45516 11.0159 9.00745V18.958C11.016 18.9671 11.016 18.9762 11.0159 18.9854V19.0074Z"
                fill="currentColor"
              ></path>
            </svg>
          </span>
        </span>
        <div className="flex flex-col border border-box rounded-lg bg-inner">
          <div className="text-xs flex flex-col overflow-hidden text-grey-400">
            <div className="flex flex-row space-x-2 items-center py-2 border-b px-3 border-box">
              <span>To</span>
              <NetworkPicker
                network={transferState.to.network}
                onClick={() => setSelectingToken(SelectingTokenState.TO)}
              />
            </div>
          </div>
          <h1 className="text-xs text-grey-400 px-3 pt-3">Amount</h1>
          <div
            className="flex items-center px-1
        false"
          >
            <input
              className="flex-grow w-full p-2 text-2xl text-primary font-mono font-extralight border-none rounded-lg outline-none placeholder-primary bg-transparent"
              autoCorrect="off"
              inputMode="decimal"
              maxLength={79}
              minLength={1}
              pattern="[0-9,.]*"
              placeholder="0.00"
              spellCheck="false"
              type="text"
              value={amount || ""}
              disabled
            />
          </div>
          <TokenBalanceRow
            symbol={transferState.to.symbol}
            state={balanceToState}
          />
        </div>
      </div>
      {bridgeCostState.cost !== 0n && (
        <div className="inline-flex items-center text-xs">
          Bridge Fee:{" "}
          {bridgeCostState.isLoading ? (
            <Spinner />
          ) : (
            `${formatUnits(
              bridgeCostState.cost as bigint,
              nativeCurrency.decimals
            )} ${nativeCurrency.symbol}`
          )}
        </div>
      )}
      <div className="flex flex-col pt-6">
        {address && !isDisconnected ? (
          <ActionBox
            amount={amount}
            address={address}
            chainId={transferState.from.chainId}
            token={transferState.from.contract}
            route={route}
            setSuccessfulReceipt={setSuccessfulReceipt}
            bridgeCost={bridgeCostState.cost}
          />
        ) : (
          <ConnectWalletButton className="center py-3 px-4 text-lg font-bold whitespace-nowrap rounded-lg disabled:cursor-not-allowed bg-blue-700 hover:bg-blue-800 text-white disabled:bg-grey-100 disabled:text-grey-200 dark:bg-blue-700 dark:hover:bg-blue-800 disabled:dark:bg-grey-900 disabled:dark:text-grey-600" />
        )}
      </div>
    </>
  );
}
