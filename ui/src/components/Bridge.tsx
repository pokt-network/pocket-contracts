import { useState } from "react";

import {
  useAccount,
  useConfig,
  UseTransactionReceiptReturnType,
} from "wagmi";
import { readContract, getBalance, GetBalanceReturnType } from "wagmi/actions";

import { tokens, Token } from "../config";
import { SelectToken } from "./SelectToken";
import { bridgeRoute } from "../bridgeRoute";
import { useEffect } from "react";
import { Transfer } from "./Transfer";
import { useMemo } from "react";
import { Success } from "./Success";

export type TransferState = {
  from: Token;
  to: Token;
};

export enum SelectingTokenState {
  FROM = "FROM",
  TO = "TO",
}

export type BridgeCostState = {
  isLoading: boolean;
  error: string | null;
  cost: bigint | null;
};

export type BalanceState = {
  isLoading: boolean;
  error: string | null;
  balance: GetBalanceReturnType | null;
};

export type SetSuccessfulReceiptAction = React.Dispatch<
  React.SetStateAction<UseTransactionReceiptReturnType["data"] | null>
>;

const filterTokensByState = (
  selectingToken: SelectingTokenState,
  transferState: TransferState
) =>
  tokens.filter((token) => {
    if (selectingToken === SelectingTokenState.TO) {
      if (
        transferState.from.network !== "sepolia" &&
        token.symbol === "WPOKT"
      ) {
        // we need to exclude WPOKT from DESTs when source is not sepolia network
        return false;
      }

      // we also need to exclude tokens from the same network
      if (
        transferState.from.contract === token.contract &&
        transferState.from.network === token.network
      ) {
        return false;
      }
    } else if (selectingToken === SelectingTokenState.FROM) {
      // we also need to exclude tokens from the same network
      if (
        transferState.to.contract === token.contract &&
        transferState.to.network === token.network
      ) {
        return false;
      }
    }

    return true;
  });

const canSwapTransferState = (transferState: TransferState) => {
  if (
    transferState.to.network !== "sepolia" &&
    transferState.from.symbol === "WPOKT"
  ) {
    console.log("There is no route for this transfer yet.");
    return false;
  }

  return true;
};

export function Bridge() {
  const config = useConfig();

  const { address } = useAccount();

  const [selectingTokenState, setSelectingTokenState] =
    useState<SelectingTokenState | null>(null);

  const [successfulReceipt, setSuccessfulReceipt] = useState<
    UseTransactionReceiptReturnType["data"] | null
  >(null);

  const [transferState, setTransferState] = useState<TransferState>({
    from: tokens[0], // WPOKT
    to: tokens[1], // to XPOKT
  });

  const [amount, setAmount] = useState<string>("");

  // find route based on the selected tokens
  const route = useMemo(
    () => bridgeRoute(transferState.from, transferState.to),
    [transferState.from, transferState.to]
  );

  // Balance From State
  const [balanceFromState, setBalanceFromState] = useState<BalanceState>({
    isLoading: false,
    error: null,
    balance: null,
  });

  useEffect(() => {
    if (!address) {
      return;
    }

    console.log("re-rendered setBalanceFromState");

    setBalanceFromState({
      isLoading: true,
      error: null,
      balance: null,
    });

    getBalance(config, {
      chainId: transferState.from.chainId,
      address,
      token: transferState.from.contract,
    })
      .then((result) => {
        setBalanceFromState({
          isLoading: false,
          error: null,
          balance: result,
        });
      })
      .catch((e) => {
        setBalanceFromState({
          isLoading: false,
          error: e.message,
          balance: null,
        });
      });
  }, [transferState.from, address]);

  // Balance To State
  const [balanceToState, setBalanceToState] = useState<BalanceState>({
    isLoading: false,
    error: null,
    balance: null,
  });

  useEffect(() => {
    if (!address) {
      return;
    }

    setBalanceToState({
      isLoading: true,
      error: null,
      balance: null,
    });

    getBalance(config, {
      chainId: transferState.to.chainId,
      address,
      token: transferState.to.contract,
    })
      .then((result) => {
        setBalanceToState({
          isLoading: false,
          error: null,
          balance: result,
        });
      })
      .catch((e) => {
        setBalanceToState({
          isLoading: false,
          error: e.message,
          balance: null,
        });
      });
  }, [transferState.to, address]);

  // Bridge Cost State
  const [bridgeCostState, setBridgeCostState] = useState<BridgeCostState>({
    isLoading: false,
    error: null,
    cost: 0n,
  });

  useEffect(() => {
    if (route.feeRequired) {
      console.log("re-rendered setBridgeCostState");

      setBridgeCostState({
        isLoading: true,
        error: null,
        cost: null,
      });

      readContract(config, {
        address: route.contract,
        abi: route.contractAbi,
        functionName: "bridgeCost",
        args: [route.destChainWormholeId],
        chainId: route.network.chainId,
      })
        .then((result) => {
          setBridgeCostState({
            isLoading: false,
            error: null,
            cost: result as bigint,
          });
        })
        .catch((e) => {
          setBridgeCostState({
            isLoading: false,
            error: e.message,
            cost: null,
          });
        });
    } else {
      setBridgeCostState({
        isLoading: false,
        error: null,
        cost: 0n,
      });
    }
  }, [route]);

  const onTokenSelect = (token: Token) => {
    if (selectingTokenState === SelectingTokenState.FROM) {
      setTransferState((state) => ({ ...state, from: token }));
      setSelectingTokenState(null);
    } else if (selectingTokenState === SelectingTokenState.TO) {
      setTransferState((state) => ({ ...state, to: token }));
      setSelectingTokenState(null);
    }
  };

  const canSwapSides = canSwapTransferState(transferState);

  const swapTransferState = () => {
    if (canSwapSides) {
      setTransferState({
        from: transferState.to,
        to: transferState.from,
      });
    }
  };

  if (successfulReceipt) {
    return (
      <Success
        receipt={successfulReceipt}
        transferState={transferState}
        amount={amount}
      />
    );
  }

  if (selectingTokenState) {
    return (
      <SelectToken
        tokenList={filterTokensByState(selectingTokenState, transferState)}
        onTokenSelect={onTokenSelect}
        address={address!}
      />
    );
  }

  return (
    <Transfer
      canSwapSides={canSwapSides}
      transferState={transferState}
      bridgeCostState={bridgeCostState}
      balanceFromState={balanceFromState}
      balanceToState={balanceToState}
      swapTransferState={swapTransferState}
      setSelectingToken={setSelectingTokenState}
      amount={amount}
      setAmount={setAmount}
      route={route}
      setSuccessfulReceipt={setSuccessfulReceipt}
    />
  );
}
