import { useAccount } from "wagmi";
import { useWeb3Modal } from "@web3modal/wagmi/react";
import { Spinner } from "./Spinner";

export const Account = () => {
  const { isConnecting, isDisconnected } = useAccount();

  const { open } = useWeb3Modal();

  if (isConnecting || isDisconnected)
    return (
      <div>
        <button
          type="button"
          onClick={() => open()}
          className="inline-flex items-center px-4 py-2 rounded bg-white/10 px-2 py-1 text-sm font-semibold text-white shadow-sm hover:bg-white/20"
        >
          {isConnecting && (
            <Spinner />
          )}
          
          {isConnecting ? "Connecting..." : "Connect Wallet"}
        </button>
      </div>
    );
  return (
    <div>
      <w3m-account-button balance="hide" />
    </div>
  );
};
