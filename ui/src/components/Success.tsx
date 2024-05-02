// import {
//   EthereumCircleColorful,
//   OptimismCircleColorful,
//   ArbitrumCircleColorful,
//   BaseCircleColorful,
//   PoktCircleColorful,
// } from "@ant-design/web3-icons";

import { UseTransactionReceiptReturnType } from "wagmi";

import { TransferState } from "./Bridge";
import { renderNetworkName } from "../utils";
import { WPOKT_CONTRACT, getTxDetailUrl } from "../config";

type SuccessProps = {
  amount: string;
  transferState: TransferState;
  receipt: UseTransactionReceiptReturnType["data"];
};

export const Success = ({ amount, transferState, receipt }: SuccessProps) => {
  // lockbox transfer happens on the same chain
  // so the bridging is immediate
  const isLockboxTransfer =
    transferState.from.network === transferState.to.network;

  return (
    <>
      <div>
        <div className="mx-auto flex items-center justify-center">
          <span className="text-8xl">🎉</span>
        </div>
        <div className="mt-3 text-center sm:mt-5">
          <h3 className="text-base font-semibold leading-6 text-primary">
            Transfer was successful
          </h3>
        </div>
        <div className="mt-2">
          {isLockboxTransfer ? (
            <p>
              You have turned {" "}
              <b>{amount}</b>{" "}
              <b title={transferState.from.contract === WPOKT_CONTRACT ? 'Wrapped POKT' : 'xERC20'} className="cursor-help border-b border-dotted">
                {transferState.from.symbol}
              </b>{" "}
              into {" "}
              <b title={transferState.from.contract !== WPOKT_CONTRACT ? 'Wrapped POKT' : 'xERC20'} className="cursor-help border-b border-dotted">
                {transferState.to.symbol}
              </b>
              .
            </p>
          ) : (
            <p className="text-sm text-secondary">
              You have transferred <b>{amount} POKT</b> from{" "}
              <b>{renderNetworkName(transferState.from.network)}</b> to{" "}
              <b>{renderNetworkName(transferState.to.network)}</b>.
            </p>
          )}

          <p className="text-sm mt-5">
            Tx Hash (on {renderNetworkName(transferState.from.network)}):
          </p>
          <a target="_blank" href={getTxDetailUrl(receipt!.chainId, receipt!.transactionHash)} className="text-sm break-all underline">{receipt!.transactionHash}</a>
        </div>

        {!isLockboxTransfer && (
          <div className="rounded-md bg-yellow-200/10 p-4 mt-5">
            <div className="flex">
              <div className="text-sm text-yellow-300">
                <p>
                  It may take up to 30 minutes for the token to appear in your
                  wallet on {renderNetworkName(transferState.to.network)}.
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* <div className="pt-2">
        <button
          type="button"
          className="inline-flex w-full justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          onClick={() => window.location.reload()}
        >
          Make a new transfer
        </button>
      </div> */}
    </>
  );
};
