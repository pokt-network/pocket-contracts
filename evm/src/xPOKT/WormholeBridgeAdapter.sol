pragma solidity 0.8.19;

import {xERC20BridgeAdapter} from "@protocol/xPOKT/xERC20BridgeAdapter.sol";
import {SafeCast} from "@openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import {IWormholeRelayer} from "@protocol/wormhole/IWormholeRelayer.sol";
import {IWormholeReceiver} from "@protocol/wormhole/IWormholeReceiver.sol";
import {WormholeTrustedSender} from "@protocol/governance/WormholeTrustedSender.sol";

/// @notice Wormhole xERC20 Token Bridge adapter
contract WormholeBridgeAdapter is
    IWormholeReceiver,
    xERC20BridgeAdapter,
    WormholeTrustedSender
{
    using SafeCast for uint256;

    /// ---------------------------------------------------------
    /// ---------------------------------------------------------
    /// ------------------ SINGLE STORAGE SLOT ------------------
    /// ---------------------------------------------------------
    /// ---------------------------------------------------------

    /// @dev packing these variables into a single slot saves a
    /// COLD SLOAD on bridge out operations.

    /// @notice gas limit for wormhole relayer, changeable incase gas prices change on external network
    uint96 public gasLimit = 300_000;

    /// @notice address of the wormhole relayer cannot be changed by owner
    /// because the relayer contract is a proxy and should never change its address
    IWormholeRelayer public wormholeRelayer;

    /// ---------------------------------------------------------
    /// ---------------------------------------------------------
    /// ----------------------- MAPPINGS ------------------------
    /// ---------------------------------------------------------
    /// ---------------------------------------------------------

    /// @notice nonces that have already been processed
    mapping(bytes32 => bool) public processedNonces;

    /// @notice chain id of the target chain to address for bridging
    /// starts off mapped to itself, but can be changed by governance
    mapping(uint16 => address) public targetAddress;

    /// @notice chain-specific gas limit for wormhole relayer, changeable incase gas prices change on external network
    mapping(uint16 => uint96) public customGasLimits;

    /// ---------------------------------------------------------
    /// ---------------------------------------------------------
    /// ------------------------ EVENTS -------------------------
    /// ---------------------------------------------------------
    /// ---------------------------------------------------------

    /// @notice chain id of the target chain to address for bridging
    /// @param targetChainId source chain id tokens were bridged from
    /// @param tokenReceiver address to receive tokens on destination chain
    /// @param amount of tokens bridged in
    event TokensSent(
        uint16 indexed targetChainId,
        address indexed tokenReceiver,
        uint256 amount
    );

    /// @notice chain id of the target chain to address for bridging
    /// @param targetChainId destination chain id to send tokens to
    /// @param target address to send tokens to
    event TargetAddressUpdated(
        uint16 indexed targetChainId,
        address indexed target
    );

    /// @notice emitted when the gas limit changes on external chains
    /// @param oldGasLimit old gas limit
    /// @param newGasLimit new gas limit
    event GasLimitUpdated(uint96 oldGasLimit, uint96 newGasLimit);

    /// ---------------------------------------------------------
    /// ---------------------------------------------------------
    /// ---------------------- INITIALIZE -----------------------
    /// ---------------------------------------------------------
    /// ---------------------------------------------------------

    /// @notice Initialize the Wormhole bridge
    /// @param newxerc20 xERC20 token address
    /// @param newOwner contract owner address
    /// @param wormholeRelayerAddress address of the wormhole relayer
    /// @param targetChains chain id of the target chain to address for bridging
    function initialize(
        address newxerc20,
        address newOwner,
        address wormholeRelayerAddress,
        uint16[] memory targetChains
    ) public initializer {
        __Ownable_init();
        _transferOwnership(newOwner);
        _setxERC20(newxerc20);

        wormholeRelayer = IWormholeRelayer(wormholeRelayerAddress);

        /// initialize contract to trust this exact same address on an external chain
        /// @dev the external chain contracts MUST HAVE THE SAME ADDRESS on the external chain
        for (uint256 i = 0; i < targetChains.length; i++) {
            targetAddress[targetChains[i]] = address(this);
            _addTrustedSender(address(this), targetChains[i]);
        }

        /// @dev default starting gas limit for relayer
        gasLimit = 300_000;
    }

    /// --------------------------------------------------------
    /// --------------------------------------------------------
    /// ---------------- Admin Only Functions ------------------
    /// --------------------------------------------------------
    /// --------------------------------------------------------

    /// @notice set a gas limit for the relayer on the external chain
    /// should only be called if there is a change in gas prices on the external chain
    /// @param newGasLimit new gas limit to set
    function setGasLimit(uint96 newGasLimit) external onlyOwner {
        uint96 oldGasLimit = gasLimit;
        gasLimit = newGasLimit;

        emit GasLimitUpdated(oldGasLimit, newGasLimit);
    }

    /// @notice set a custom gas limit for the relayer on the external chain
    /// should only be called if there is a change in gas prices on the specific external chain
    /// @param chainId target chain id
    /// @param newGasLimit new gas limit to set
    function setCustomGasLimit(uint16 chainId, uint96 newGasLimit) external onlyOwner {
        customGasLimits[chainId] = newGasLimit;
    }

    /// @notice remove trusted senders from external chains
    /// @param _trustedSenders array of trusted senders to remove
    function removeTrustedSenders(
        WormholeTrustedSender.TrustedSender[] memory _trustedSenders
    ) external onlyOwner {
        _removeTrustedSenders(_trustedSenders);
    }

    /// @notice add trusted senders from external chains
    /// @param _trustedSenders array of trusted senders to add
    function addTrustedSenders(
        WormholeTrustedSender.TrustedSender[] memory _trustedSenders
    ) external onlyOwner {
        _addTrustedSenders(_trustedSenders);
    }

    /// @notice add map of target addresses for external chains
    /// @dev there is no check here to ensure there isn't an existing configuration
    /// ensure the proper add or remove is being called when using this function
    /// @param _chainConfig array of chainids to addresses to add
    function setTargetAddresses(
        WormholeTrustedSender.TrustedSender[] memory _chainConfig
    ) external onlyOwner {
        for (uint256 i = 0; i < _chainConfig.length; i++) {
            targetAddress[_chainConfig[i].chainId] = _chainConfig[i].addr;

            emit TargetAddressUpdated(
                _chainConfig[i].chainId,
                _chainConfig[i].addr
            );
        }
    }

    /// --------------------------------------------------------
    /// --------------------------------------------------------
    /// ---------------- View Only Functions -------------------
    /// --------------------------------------------------------
    /// --------------------------------------------------------

    /// @notice Estimate bridge cost to bridge out to a destination chain
    /// @param targetChainId Destination chain id
    function bridgeCost(
        uint16 targetChainId
    ) public view returns (uint256 gasCost) {
        uint96 _gasLimit = chainGasLimit(targetChainId);

        (gasCost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChainId,
            0,
            _gasLimit
        );
    }

    /// @notice Returns gas limit for the relayer on the external chain
    /// @param targetChainId Destination chain id
    function chainGasLimit(
        uint16 targetChainId
    ) public view returns (uint96) {
        if (customGasLimits[targetChainId] != 0) {
            return customGasLimits[targetChainId];
        }

        return gasLimit;
    }

    /// --------------------------------------------------------
    /// --------------------------------------------------------
    /// -------------------- Bridge In/Out ---------------------
    /// --------------------------------------------------------
    /// --------------------------------------------------------

    /// @notice Bridge Out Funds to an external chain.
    /// Callable by the users to bridge out their funds to an external chain.
    /// If a user sends tokens to the token contract on the external chain,
    /// that call will revert, and the tokens will be lost permanently.
    /// @param user to send funds from, should be msg.sender in all cases
    /// @param targetChain Destination chain id
    /// @param amount Amount of xERC20 to bridge out
    /// @param to Address to receive funds on destination chain
    function _bridgeOut(
        address user,
        uint256 targetChain,
        uint256 amount,
        address to
    ) internal override {
        uint16 targetChainId = targetChain.toUint16();
        uint96 _gasLimit = chainGasLimit(targetChainId);
        uint256 cost = bridgeCost(targetChainId);
        require(msg.value == cost, "WormholeBridge: cost not equal to quote");
        require(
            targetAddress[targetChainId] != address(0),
            "WormholeBridge: invalid target chain"
        );

        /// user must burn xERC20 tokens first
        _burnTokens(user, amount);

        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChainId,
            targetAddress[targetChainId],
            // payload
            abi.encode(to, amount),
            /// no receiver value allowed, only message passing
            0,
            _gasLimit,
            targetChainId,
            to
        );

        emit TokensSent(targetChainId, to, amount);
    }

    /// @notice callable only by the wormhole relayer
    /// @param payload the payload of the message, contains the to and amount
    /// additional vaas, unused parameter
    /// @param senderAddress the address of the sender on the source chain, bytes32 encoded
    /// @param sourceChain the chain id of the source chain
    /// @param nonce the unique message ID
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32 senderAddress,
        uint16 sourceChain,
        bytes32 nonce
    ) external payable override {
        require(msg.value == 0, "WormholeBridge: no value allowed");
        require(
            msg.sender == address(wormholeRelayer),
            "WormholeBridge: only relayer allowed"
        );
        require(
            isTrustedSender(sourceChain, senderAddress),
            "WormholeBridge: sender not trusted"
        );
        require(
            !processedNonces[nonce],
            "WormholeBridge: message already processed"
        );

        processedNonces[nonce] = true;

        // Parse the payload and do the corresponding actions!
        (address to, uint256 amount) = abi.decode(payload, (address, uint256));

        /// mint tokens and emit events
        _bridgeIn(sourceChain, to, amount);
    }
}
