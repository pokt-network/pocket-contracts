pragma solidity ^0.8.0;

import {MultisigProposal} from "@proposals/MultisigProposal.sol";
import {Proposal} from "@proposals/Proposal.sol";
import {WormholeChainIds} from "@generated/WormholeChainIds.sol";
import {WormholeBridgeAdapter} from "@protocol/xPOKT/WormholeBridgeAdapter.sol";
import {WormholeTrustedSender} from "@protocol/governance/WormholeTrustedSender.sol";

// MULTISIG_01 proposal deploys a Vault contract and an ERC20 token contract
// Then the proposal transfers ownership of both Vault and ERC20 to the multisig address
// Finally the proposal whitelist the ERC20 token in the Vault contract
contract WhitelistArbitrumAndOptimism is MultisigProposal, WormholeChainIds {
    string private constant ADDRESSES_PATH = "./addresses/Addresses.json";

    struct TrustedSender {
        uint16 chainId;
        address addr;
    }

    constructor() Proposal(ADDRESSES_PATH, "GOV_MULTISIG") {
        string memory urlOrAlias = vm.envOr("ETH_RPC_URL", string("sepolia"));
        primaryForkId = vm.createFork(urlOrAlias);
    }

    /// @notice Returns the name of the proposal.
    function name() public pure override returns (string memory) {
        return "WhitelistArbitrumAndOptimism_000";
    }

    /// @notice Provides a brief description of the proposal.
    function description() public pure override returns (string memory) {
        return "Update trusted senders for the Wormhole Bridge Adapter";
    }

    /// @notice Sets up actions for the proposal
    function _build() internal override {
        /// STATICCALL -- not recorded for the run stage
        address wormholeBridge = addresses.getAddress(
            "WORMHOLE_BRIDGE_ADAPTER_PROXY"
        );

        WormholeTrustedSender.TrustedSender[]
            memory trustedSenders = new WormholeTrustedSender.TrustedSender[](
                2
            );
        trustedSenders[0] = WormholeTrustedSender.TrustedSender({
            chainId: arbitrumSepoliaWormholeChainId,
            addr: wormholeBridge
        });
        trustedSenders[1] = WormholeTrustedSender.TrustedSender({
            chainId: optimismSepoliaWormholeChainId,
            addr: wormholeBridge
        });

        WormholeBridgeAdapter(wormholeBridge).setTargetAddresses(
            trustedSenders
        );
        WormholeBridgeAdapter(wormholeBridge).addTrustedSenders(trustedSenders);
    }

    /// @notice Executes the proposal actions.
    function _run() internal override {
        /// Call parent _run function to check if there are actions to execute
        super._run();

        address multisig = addresses.getAddress("GOV_MULTISIG");

        /// CALLS -- mutative and recorded
        _simulateActions(multisig);
    }

    /// @notice Validates the post-execution state.
    function _validate() internal view override {
        /// STATICCALL -- not recorded for the run stage
        address wormholeBridge = addresses.getAddress(
            "WORMHOLE_BRIDGE_ADAPTER_PROXY"
        );

        WormholeTrustedSender.TrustedSender[]
            memory trustedSenders = new WormholeTrustedSender.TrustedSender[](
                2
            );
        trustedSenders[0] = WormholeTrustedSender.TrustedSender({
            chainId: arbitrumSepoliaWormholeChainId,
            addr: wormholeBridge
        });
        trustedSenders[1] = WormholeTrustedSender.TrustedSender({
            chainId: optimismSepoliaWormholeChainId,
            addr: wormholeBridge
        });

        for (uint256 i = 0; i < trustedSenders.length; i++) {
            require(
                WormholeBridgeAdapter(wormholeBridge).isTrustedSender(
                    trustedSenders[i].chainId,
                    trustedSenders[i].addr
                ),
                "Trusted sender not added"
            );
        }
    }
}
