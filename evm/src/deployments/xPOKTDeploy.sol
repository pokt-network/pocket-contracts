pragma solidity 0.8.19;

import {TransparentUpgradeableProxy} from "@openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {xPOKT} from "@protocol/xPOKT/xPOKT.sol";
import {MintLimits} from "@protocol/xPOKT/MintLimits.sol";
import {XERC20Lockbox} from "@protocol/xPOKT/XERC20Lockbox.sol";
import {WormholeBridgeAdapter} from "@protocol/xPOKT/WormholeBridgeAdapter.sol";

contract xPOKTDeploy {
    /// @notice deploy a system on EVM
    /// this includes the xPOKT token, the proxy, the proxy admin, and the wormhole adapter
    /// but does not include the xPOKT lockbox as there is no native POKT token on base
    /// @param proxyAdmin The proxy admin to use, if any
    function deployEvmSystem(
        address proxyAdmin
    )
        public
        returns (
            address xpoktLogic,
            address xpoktProxy,
            address wormholeAdapterLogic,
            address wormholeAdapter
        )
    {
        /// deploy the ERC20 wrapper for xPOKT
        xpoktLogic = address(new xPOKT());

        wormholeAdapterLogic = address(new WormholeBridgeAdapter());

        /// do not initialize the proxy, that is the final step
        xpoktProxy = address(
            new TransparentUpgradeableProxy(xpoktLogic, proxyAdmin, "")
        );

        wormholeAdapter = address(
            new TransparentUpgradeableProxy(
                wormholeAdapterLogic,
                proxyAdmin,
                ""
            )
        );
    }

    /// @notice WPOKT token address
    function deployEthereumSystem(
        address wpoktAddress,
        address existingProxyAdmin
    )
        public
        returns (
            address xpoktLogic,
            address xpoktProxy,
            address wormholeAdapterLogic,
            address wormholeAdapter,
            address lockbox
        )
    {
        (
            xpoktLogic,
            xpoktProxy,
            wormholeAdapterLogic,
            wormholeAdapter
        ) = deployEvmSystem(existingProxyAdmin);

        /// lockbox is deployed at the end so that xPOKT and wormhole adapter can have the same addresses on all chains.
        lockbox = deployLockBox(
            xpoktProxy,
            /// proxy is actually the xPOKT token contract
            wpoktAddress
        );
    }

    function initializeXPokt(
        address xpoktProxy,
        string memory tokenName,
        string memory tokenSymbol,
        address tokenOwner,
        MintLimits.RateLimitMidPointInfo[] memory newRateLimits,
        uint128 newPauseDuration,
        address newPauseGuardian
    ) public {
        xPOKT(xpoktProxy).initialize(
            tokenName,
            tokenSymbol,
            tokenOwner,
            newRateLimits,
            newPauseDuration,
            newPauseGuardian
        );
    }

    function initializeWormholeAdapter(
        address wormholeAdapter,
        address xpoktProxy,
        address tokenOwner,
        address wormholeRelayerAddress,
        uint16[] memory chainIds
    ) public {
        WormholeBridgeAdapter(wormholeAdapter).initialize(
            xpoktProxy,
            tokenOwner,
            wormholeRelayerAddress,
            chainIds
        );
    }

    /// @notice deploy lock box, for use on base only
    /// @param xpokt The xPOKT token address
    /// @param wpokt The wPOKT token address
    function deployLockBox(
        address xpokt,
        address wpokt
    ) public returns (address) {
        return address(new XERC20Lockbox(xpokt, wpokt));
    }
}
