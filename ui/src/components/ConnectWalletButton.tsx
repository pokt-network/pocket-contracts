import { useAccount } from "wagmi";
import { useWeb3Modal } from "@web3modal/wagmi/react";
import { Spinner } from "./Spinner";

export const ConnectWalletButton = ({ ...props }: React.HTMLAttributes<HTMLButtonElement>) => {
  const { isConnecting } = useAccount();
  const { open } = useWeb3Modal();

  return (
      <button
        type="button"
        {...props}
        onClick={() => open()}
      >
        {isConnecting && <Spinner />}

        {isConnecting ? "Connecting..." : "Connect Wallet"}
      </button>
  );
};
