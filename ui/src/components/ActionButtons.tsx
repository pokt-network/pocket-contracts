import {  Address } from "viem";
import { useAllowance } from "../hooks/useAllowance";
import { ApproveButton } from "./ApproveButton";
import { TransferButton } from "./TransferButton";
import { BridgeRoute } from "../bridgeRoute";
import { SetSuccessfulReceiptAction } from "./Bridge";

type ActionButtonsProps = {
  address: Address;
  token: Address;
  chainId: number;
  amount: string;
  route: BridgeRoute;
  setSuccessfulReceipt: SetSuccessfulReceiptAction;
  bridgeCost: bigint | null;
};

export const ActionButtons = ({
  amount,
  token,
  address,
  chainId,
  route,
  setSuccessfulReceipt,
  bridgeCost,
}: ActionButtonsProps) => {
  // Wormhole Bridge Proxy: 0x48B02a246861Abb10166D383787689793b1A51a6
  // Lockbox Proxy: 0xA4e8d8A848b51F3464B3E55d3eD329E4C19631b9
  // WPOKT Router: 0x0339F6e6dec5a13d8D60eb18a46a8AF4e5Ad12AD

  const { data: allowance, refetch: refetchAllowance } = useAllowance({
    token,
    owner: address,
    spender: route.contract,
    chainId,
  });

  if (allowance === 0n) {
    return (
      <ApproveButton
        refetchAllowance={refetchAllowance}
        spender={route.contract}
        token={token}
        address={address}
        chainId={chainId}
      />
    );
  }

  return (
    <TransferButton
      route={route}
      amount={amount}
      token={token}
      address={address}
      chainId={chainId}
      setSuccessfulReceipt={setSuccessfulReceipt}
      bridgeCost={bridgeCost}
    />
  );
};
