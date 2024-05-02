import { Address } from "viem";
import { Token } from "../config";
import { renderNetworkName } from "../utils";
import { NetworkLogo } from "./NetworkLogo";
import { TokenBalance } from "./TokenBalance";

type SelectTokenProps = {
    tokenList: Token[];
    onTokenSelect: (token: Token) => void;
    address: Address;
};

export const SelectToken = ({
    tokenList,
    onTokenSelect,
    address,
  }: SelectTokenProps) => {

    const onClickFactory = (token: Token) => () => {
        onTokenSelect(token);
    };
  
    const list = tokenList
      .map((token) => (
        <div
          onClick={onClickFactory(token)}
          className="flex flex-row items-center cursor-pointer justify-between hover:bg-inverted/10 dark:hover:bg-grey-900 px-2 py-2 rounded-lg"
        >
          <span className="flex items-center">
            <NetworkLogo
              network={token.network}
              className="text-3xl mr-3"
            />
            <div className="flex flex-col">
              <span className="flex items-center space-x-1">
                <span className="text-primary leading-tight">{token.symbol}</span>
                {/* <div className="text-grey-300" aria-expanded="false">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="20"
                    height="20"
                    viewBox="0 0 18 18"
                    fill="none"
                  >
                    <path
                      d="M9.00004 11.0339H8.33337V8.36719H7.66671M8.33337 5.70052H8.34004M14.3334 8.36719C14.3334 11.6809 11.6471 14.3672 8.33337 14.3672C5.01967 14.3672 2.33337 11.6809 2.33337 8.36719C2.33337 5.05348 5.01967 2.36719 8.33337 2.36719C11.6471 2.36719 14.3334 5.05348 14.3334 8.36719Z"
                      stroke="currentColor"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    ></path>
                  </svg>
                </div> */}
              </span>
              <span className="text-xs mt-1 text-secondary leading-tight">
                on {renderNetworkName(token.network)}
              </span>
            </div>
          </span>
          <div className="flex flex-col items-end">
            <div className="flex flex-wrap  space-x-2 justify-end font-mono text-primary text-sm">
              <span><TokenBalance chainId={token.chainId} token={token.contract} address={address} /></span>
              <span>{token.symbol}</span>
            </div>
          </div>
        </div>
      ));
  
    return (
      <>
        <div className="py-2 space-y-3 overflow-y-auto scrollbar-thin max-h-[400px]">
          {list}
        </div>
      </>
    );
  }
  