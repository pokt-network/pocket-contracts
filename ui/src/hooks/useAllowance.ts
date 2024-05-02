import { erc20Abi, Address } from 'viem';
import { useReadContract } from 'wagmi';

type UseAllowanceProps = {
    token: Address;
    owner: Address;
    spender: Address;
    chainId: number;
};

export const useAllowance = ({
    token,
    owner,
    spender,
    chainId,
}: UseAllowanceProps) => {
    return useReadContract({
        address: token,
        abi: erc20Abi,
        functionName: "allowance",
        args: [owner, spender],
        chainId
    });
}