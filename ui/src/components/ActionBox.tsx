import { useBalance } from "wagmi";
import { formatUnits, Address } from "viem";
import { DisabledButton } from "./DisabledButton";
import { ActionButtons } from "./ActionButtons";
import { BridgeRoute } from "../bridgeRoute";
import { SetSuccessfulReceiptAction } from "./Bridge";

type ActionBoxProps = {
  address: Address;
  token: Address;
  chainId: number;
  amount: string;
  route: BridgeRoute;
  setSuccessfulReceipt: SetSuccessfulReceiptAction;
  bridgeCost: bigint | null;
};

export const ActionBox = ({
  amount,
  token,
  address,
  chainId,
  route,
  setSuccessfulReceipt,
  bridgeCost,
}: ActionBoxProps) => {
  const result = useBalance({
    chainId,
    address,
    token,
  });

  if (!amount || parseFloat(amount) <= 0) {
    return <DisabledButton text="Transfer" />;
  }

  if (result.data) {
    const maxPossibleAmount = formatUnits(
      result.data.value,
      result.data.decimals
    );

    if (parseFloat(amount) > parseFloat(maxPossibleAmount)) {
      return <DisabledButton text="Insufficient balance" />;
    }
  }

  return (
    <ActionButtons
      bridgeCost={bridgeCost}
      setSuccessfulReceipt={setSuccessfulReceipt}
      route={route}
      amount={amount}
      token={token}
      address={address}
      chainId={chainId}
    />
  );
};
