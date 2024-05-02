import { useBalance } from "wagmi";
import { formatUnits, Address } from "viem";

type MaxButtonProps = {
  address: Address;
  token: Address;
  chainId: number;
  setAmount: (amount: string) => void;
};

export const MaxButton = ({
  address,
  token,
  chainId,
  setAmount,
}: MaxButtonProps) => {
  const result = useBalance({
    chainId,
    address,
    token,
  });

  const onClick = () => {
    if (result.data) {
      setAmount(formatUnits(result.data.value, result.data.decimals));
    }
  };

  if (result.isLoading) {
    return null;
  }

  if (result.error) {
    return null;
  }

  return (
    <button
      onClick={onClick}
      className="center py-1 px-3 text-primary text-sm font-bold whitespace-nowrap rounded-lg disabled:cursor-not-allowed inline-flex px-3 py-1 mx-2 my-2 border rounded-[15px]  font-extralight"
    >
      MAX
    </button>
  );
};
