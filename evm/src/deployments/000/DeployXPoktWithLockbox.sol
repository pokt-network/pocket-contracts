pragma solidity 0.8.19;

import {Deployment} from "@deployments/Deployment.sol";

import {MintLimits} from "@protocol/xPOKT/MintLimits.sol";
import {WormholeChainIds} from "@generated/WormholeChainIds.sol";
import {xPOKTDeploy} from "@deployments/xPOKTDeploy.sol";
import {MintLimits} from "@protocol/xPOKT/MintLimits.sol";

contract DeployXPoktWithLockbox is Deployment, WormholeChainIds, xPOKTDeploy {
    /// @notice the buffer cap for the xPOKT token bridge
    uint112 public constant bufferCap = 100_000_000 * 1e6;

    /// @notice the rate limit per second for the xPOKT token
    /// heals at ~19m per day if buffer is fully replenished or depleted
    /// this limit is used for the wormhole bridge adapters
    uint128 public constant rateLimitPerSecond = 1158 * 1e6;

    /// @notice the buffer cap for the xPOKT token
    /// Set to 2b so that all WPOKT can be locked up and turned into xPOKT tokens.
    uint112 public constant lockBoxBufferCap = 2_000_000_000 * 1e6;

    /// @notice the rate limit per second for the xPOKT token on the lockbox
    uint128 public constant lockBoxRateLimitPerSecond = 0;

    /// @notice the duration of the pause for the xPOKT token
    /// once the contract has been paused, in this period of time, it will automatically
    /// unpause if no action is taken.
    uint128 public constant pauseDuration = 10 days;

    /// @notice we use strict deployer for this deployment, this needs to be first tx for the deployer
    function _deployer() internal view override returns (address) {
        return addresses.getAddress("DEPLOYER_EOA_STRICT");
    }

    function _run() internal override {
        address proxyAdmin = addresses.getAddress("PROXY_ADMIN");

        /// @notice the wPOKT token address
        address wpokt = addresses.getAddress("WPOKT");

        /// @notice this is the address of pause guardian
        address pauseGuardian = addresses.getAddress("PAUSE_GUARDIAN");

        /// @notice this is the address that will own the xPOKT contract
        address tokenOwner = addresses.getAddress("GOV_MULTISIG");

        /// @notice this is the address of wormhole relayer
        address wormholeRelayerAddress = addresses.getAddress(
            "WORMHOLE_BRIDGE_RELAYER"
        );

        address xpoktLogic;
        address xpoktProxy;
        address wormholeAdapterLogic;
        address wormholeAdapter;
        MintLimits.RateLimitMidPointInfo[]
            memory limits = new MintLimits.RateLimitMidPointInfo[](2);

        {
            address lockbox;
            (
                xpoktLogic,
                xpoktProxy,
                wormholeAdapterLogic,
                wormholeAdapter,
                lockbox
            ) = deployEthereumSystem(wpokt, proxyAdmin);

            limits[0].bridge = wormholeAdapter;
            limits[0].rateLimitPerSecond = rateLimitPerSecond;
            limits[0].bufferCap = bufferCap;

            limits[1].bridge = lockbox;
            limits[1].rateLimitPerSecond = lockBoxRateLimitPerSecond;
            limits[1].bufferCap = lockBoxBufferCap;

            addresses.addAddress("xPOKT_LOCKBOX", lockbox, true);
        }

        initializeXPokt(
            xpoktProxy,
            "Pocket Network",
            "POKT",
            tokenOwner,
            limits,
            pauseDuration,
            pauseGuardian
        );

        initializeWormholeAdapter(
            wormholeAdapter,
            xpoktProxy,
            tokenOwner,
            wormholeRelayerAddress,
            chainIdToWormHoleIds[block.chainid]
        );

        addresses.addAddress(
            "WORMHOLE_BRIDGE_ADAPTER_PROXY",
            wormholeAdapter,
            true
        );
        addresses.addAddress(
            "WORMHOLE_BRIDGE_ADAPTER_LOGIC",
            wormholeAdapterLogic,
            true
        );
        addresses.addAddress("xPOKT_LOGIC", xpoktLogic, true);
        addresses.addAddress("xPOKT_PROXY", xpoktProxy, true);
    }
}
