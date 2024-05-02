//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

/// DO NOT EDIT THIS FILE MANUALLY!
/// use scripts node scripts/generate.wormholeChainIds.js to generate this file
contract WormholeChainIds {
    /// ------------ Base Sepolia ------------
    uint256 public constant baseSepoliaChainId = 84532;
    uint16 public constant baseSepoliaWormholeChainId = 10004;

    /// ------------ Sepolia ------------
    uint256 public constant sepoliaChainId = 11155111;
    uint16 public constant sepoliaWormholeChainId = 10002;

    /// ------------ Arbitrum Sepolia ------------
    uint256 public constant arbitrumSepoliaChainId = 421614;
    uint16 public constant arbitrumSepoliaWormholeChainId = 10003;

    /// ------------ Optimism Sepolia ------------
    uint256 public constant optimismSepoliaChainId = 11155420;
    uint16 public constant optimismSepoliaWormholeChainId = 10005;

    /// @notice map a sending chain id to a wormhole chain ids
    mapping(uint256 => uint16[]) public chainIdToWormHoleIds;

    constructor() {
        /// ------------ TESTNETS ------------
        uint16[] memory baseSepoliaTargets = new uint16[](3);
        baseSepoliaTargets[0] = sepoliaWormholeChainId;
        baseSepoliaTargets[1] = arbitrumSepoliaWormholeChainId;
        baseSepoliaTargets[2] = optimismSepoliaWormholeChainId;
        chainIdToWormHoleIds[baseSepoliaChainId] = baseSepoliaTargets;

        uint16[] memory sepoliaTargets = new uint16[](3);
        sepoliaTargets[0] = baseSepoliaWormholeChainId;
        sepoliaTargets[1] = arbitrumSepoliaWormholeChainId;
        sepoliaTargets[2] = optimismSepoliaWormholeChainId;
        chainIdToWormHoleIds[sepoliaChainId] = sepoliaTargets;

        uint16[] memory arbitrumSepoliaTargets = new uint16[](3);
        arbitrumSepoliaTargets[0] = baseSepoliaWormholeChainId;
        arbitrumSepoliaTargets[1] = sepoliaWormholeChainId;
        arbitrumSepoliaTargets[2] = optimismSepoliaWormholeChainId;
        chainIdToWormHoleIds[arbitrumSepoliaChainId] = arbitrumSepoliaTargets;

        uint16[] memory optimismSepoliaTargets = new uint16[](3);
        optimismSepoliaTargets[0] = baseSepoliaWormholeChainId;
        optimismSepoliaTargets[1] = sepoliaWormholeChainId;
        optimismSepoliaTargets[2] = arbitrumSepoliaWormholeChainId;
        chainIdToWormHoleIds[optimismSepoliaChainId] = optimismSepoliaTargets;

        /// ------------ MAINNETS ------------
    }
}
