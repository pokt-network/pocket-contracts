import { formatUnits } from "viem";
import { BalanceState } from "./Bridge";
import { Spinner } from "./Spinner";

type TokenBalanceRowProps = {
  symbol: string;
  state: BalanceState;
};

export const TokenBalanceRow = ({ symbol, state }: TokenBalanceRowProps) => (
  <div className="text-xs text-grey-400 mt-1 justify-between flex flex-col mb-3 mx-3">
    <div className="flex flex-row items-center space-x-1">
      <span>Balance:</span>
      {state.isLoading ? (
        <Spinner />
      ) : (
        <span className="font-mono inline-flex items-center">
          {state.balance
            ? formatUnits(state.balance.value, state.balance.decimals)
            : "0"}{" "}
          {state.balance?.symbol || symbol}
        </span>
      )}
    </div>
  </div>
);
