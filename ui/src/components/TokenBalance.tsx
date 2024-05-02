import { useBalance } from 'wagmi'
import { formatUnits, Address } from 'viem' 
import { Spinner } from './Spinner';

type TokenBalanceProps = {
    address: Address;
    token: Address;
    chainId: number;
};

export const TokenBalance = ({ address, token, chainId }: TokenBalanceProps) => {

    const result = useBalance({
        chainId,
        address,
        token,
    });
    
    console.log(token, result);

    if (result.isLoading) {
        return <><Spinner /></>;
    }

    if (result.error) {
        return <>ERR_FETCHING_BALANCE</>;
    }

    if (result.data) {
        return <>{formatUnits(result.data.value, result.data.decimals)}</>
    }

    return <>0</>;
}