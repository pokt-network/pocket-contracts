import { useAccount } from "wagmi";
import { ConnectWalletButton } from "./ConnectWalletButton";

export const Navbar = () => {
    const { address, isDisconnected } = useAccount();

  return (
    <div className="flex flex-row items-end justify-end w-screen p-4">
      {address && !isDisconnected ? <w3m-account-button balance="hide" /> : <ConnectWalletButton className="inline-flex items-center px-4 py-2 rounded bg-white/10 px-2 py-1 text-sm font-semibold text-white shadow-sm hover:bg-white/20" />}
    </div>
  );
};
