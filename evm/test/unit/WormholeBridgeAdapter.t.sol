pragma solidity 0.8.19;

import "@forge-std/Test.sol";

import "@test/helper/BaseTest.t.sol";
import {MockWormholeReceiver} from "@test/mock/MockWormholeReceiver.sol";
import {WormholeBridgeAdapter} from "@protocol/xPOKT/WormholeBridgeAdapter.sol";

import {Address} from "@utils/Address.sol";

contract WormholeBridgeAdapterUnitTest is BaseTest {
    using Address for address;

    /// xerc20 bridge adapter events

    /// @notice emitted when tokens are bridged out
    /// @param dstChainId destination chain id to send tokens to
    /// @param bridgeUser user who bridged out tokens
    /// @param tokenReceiver address to receive tokens on destination chain
    /// @param amount of tokens bridged out
    event BridgedOut(
        uint256 indexed dstChainId,
        address indexed bridgeUser,
        address indexed tokenReceiver,
        uint256 amount
    );

    /// @notice emitted when tokens are bridged in
    /// @param srcChainId source chain id tokens were bridged from
    /// @param tokenReceiver address to receive tokens on destination chain
    /// @param amount of tokens bridged in
    event BridgedIn(
        uint256 indexed srcChainId,
        address indexed tokenReceiver,
        uint256 amount
    );

    /// wormhole events

    /// @notice chain id of the target chain to address for bridging
    /// @param dstChainId source chain id tokens were bridged from
    /// @param tokenReceiver address to receive tokens on destination chain
    /// @param amount of tokens bridged in
    event TokensSent(
        uint16 indexed dstChainId,
        address indexed tokenReceiver,
        uint256 amount
    );

    /// @notice chain id of the target chain to address for bridging
    /// @param dstChainId destination chain id to send tokens to
    /// @param target address to send tokens to
    event TargetAddressUpdated(
        uint16 indexed dstChainId,
        address indexed target
    );

    /// @notice emitted when the gas limit changes on external chains
    /// @param oldGasLimit old gas limit
    /// @param newGasLimit new gas limit
    event GasLimitUpdated(uint96 oldGasLimit, uint96 newGasLimit);

    /// state variables

    /// @notice address to send tokens to
    address to;

    /// @notice amount of tokens to mint
    uint256 amount;

    /// relayer gas cost
    uint256 public constant gasCost = 0.00001 * 1 ether;

    /// mock wormhole receiver
    MockWormholeReceiver receiver;

    function setUp() public override {
        super.setUp();
        to = address(999999999999999);
        amount = 100 * 1e6;
        receiver = new MockWormholeReceiver();
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(sload(receiver.slot))
        }

        bytes memory runtimeBytecode = new bytes(codeSize);

        assembly {
            extcodecopy(
                sload(receiver.slot),
                add(runtimeBytecode, 0x20),
                0,
                codeSize
            )
        }

        /// set the wormhole relayer address to have the
        /// runtime bytecode of the mock wormhole relayer
        vm.etch(wormholeRelayer, runtimeBytecode);
    }

    function testSetup() public view {
        assertEq(wormholeBridgeAdapterProxy.owner(), owner, "invalid owner");
        assertEq(
            address(wormholeBridgeAdapterProxy.wormholeRelayer()),
            wormholeRelayer,
            "invalid wormhole relayer"
        );
        assertTrue(
            wormholeBridgeAdapterProxy.isTrustedSender(
                chainId,
                address(wormholeBridgeAdapterProxy)
            ),
            "trusted sender not set"
        );
        assertEq(
            wormholeBridgeAdapterProxy.targetAddress(chainId),
            address(wormholeBridgeAdapterProxy),
            "target address not set"
        );
        assertEq(
            address(xpoktProxy),
            address(wormholeBridgeAdapterProxy.xERC20()),
            "incorrect xerc20 in bridge adapter"
        );
        assertEq(
            xpoktProxy.buffer(address(wormholeBridgeAdapterProxy)),
            externalChainBufferCap / 2,
            "incorrect buffer for wormhole bridge adapter"
        );
        assertEq(
            xpoktProxy.bufferCap(address(wormholeBridgeAdapterProxy)),
            externalChainBufferCap,
            "incorrect buffer cap for wormhole bridge adapter"
        );
        assertEq(
            MockWormholeReceiver(wormholeRelayer).price(),
            0,
            "price not zero"
        );
        assertEq(
            MockWormholeReceiver(wormholeRelayer).nonce(),
            0,
            "nonce not zero"
        );
    }

    function testInitializingFails() public {
        vm.expectRevert("Initializable: contract is already initialized");

        uint16[] memory testTargets = new uint16[](1);
        testTargets[0] = chainId;

        wormholeBridgeAdapterProxy.initialize(
            address(xpoktProxy),
            owner,
            address(wormholeBridgeAdapterProxy),
            testTargets
        );
    }

    /// ACL failure tests

    function testSetGasLimitNonOwnerFails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        wormholeBridgeAdapterProxy.setGasLimit(1);
    }

    function testSetCustomGasLimitNonOwnerFails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        wormholeBridgeAdapterProxy.setCustomGasLimit(1, 1);
    }

    function testSetTargetAddressesNonOwnerFails() public {
        vm.expectRevert("Ownable: caller is not the owner");
        wormholeBridgeAdapterProxy.setTargetAddresses(
            new WormholeBridgeAdapter.TrustedSender[](0)
        );
    }

    /// ACL success tests

    function testSetGasLimitOwnerSucceeds(uint96 newGasLimit) public {
        uint96 oldGasLimit = wormholeBridgeAdapterProxy.gasLimit();
        vm.prank(owner);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(wormholeBridgeAdapterProxy)
        );

        emit GasLimitUpdated(oldGasLimit, newGasLimit);
        wormholeBridgeAdapterProxy.setGasLimit(newGasLimit);

        assertEq(
            wormholeBridgeAdapterProxy.gasLimit(),
            newGasLimit,
            "incorrect new gas limit"
        );
    }

    function testSetCustomGasLimitOwnerSucceeds(uint16 chainId, uint96 newGasLimit) public {
        uint96 defaultGasLimit = wormholeBridgeAdapterProxy.gasLimit();
        uint96 oldGasLimit = wormholeBridgeAdapterProxy.chainGasLimit(chainId);

        assertEq(
            defaultGasLimit,
            oldGasLimit,
            "gas limits should be equal before custom gas limit set"
        );

        vm.prank(owner);

        wormholeBridgeAdapterProxy.setCustomGasLimit(chainId, newGasLimit);

        assertEq(
            wormholeBridgeAdapterProxy.chainGasLimit(chainId),
            newGasLimit,
            "incorrect new gas limit"
        );
    }

    function testSetTargetAddressesOwnerSucceeds(
        address addr,
        uint16 newChainId
    ) public {
        WormholeBridgeAdapter.TrustedSender[]
            memory sender = new WormholeBridgeAdapter.TrustedSender[](1);

        sender[0].addr = addr;
        sender[0].chainId = newChainId;

        vm.prank(owner);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(wormholeBridgeAdapterProxy)
        );
        emit TargetAddressUpdated(newChainId, addr);
        wormholeBridgeAdapterProxy.setTargetAddresses(sender);

        assertEq(
            wormholeBridgeAdapterProxy.targetAddress(newChainId),
            addr,
            "target address not set correctly"
        );
    }

    /// receiveWormholeMessages failure tests
    /// value
    function testReceiveWormholeMessageFailsWithValue() public {
        vm.deal(address(this), 100);
        vm.expectRevert("WormholeBridge: no value allowed");
        wormholeBridgeAdapterProxy.receiveWormholeMessages{value: 100}(
            "",
            new bytes[](0),
            address(this).toBytes(),
            chainId,
            bytes32(type(uint256).max)
        );
    }

    /// not relayer address
    function testReceiveWormholeMessageFailsNotRelayer() public {
        vm.expectRevert("WormholeBridge: only relayer allowed");
        wormholeBridgeAdapterProxy.receiveWormholeMessages{value: 0}(
            "",
            new bytes[](0),
            address(this).toBytes(),
            chainId,
            bytes32(type(uint256).max)
        );
    }

    /// already processed

    function testAlreadyProcessedMessageReplayFails(bytes32 nonce) public {
        testReceiveWormholeMessageSucceeds(nonce);

        vm.prank(wormholeRelayer);
        vm.expectRevert("WormholeBridge: message already processed");
        wormholeBridgeAdapterProxy.receiveWormholeMessages{value: 0}(
            abi.encode(to, amount),
            new bytes[](0),
            address(wormholeBridgeAdapterProxy).toBytes(),
            chainId,
            nonce
        );
    }

    /// not trusted sender from external chain
    function testReceiveWormholeMessageFailsNotTrustedExternalChain() public {
        vm.expectRevert("WormholeBridge: sender not trusted");
        vm.prank(wormholeRelayer);
        wormholeBridgeAdapterProxy.receiveWormholeMessages{value: 0}(
            "",
            new bytes[](0),
            address(this).toBytes(),
            chainId,
            bytes32(type(uint256).max)
        );
    }

    function testReceiveWormholeMessageSucceeds(bytes32 nonce) public {
        uint256 startingBalance = xpoktProxy.balanceOf(to);
        uint256 startingTotalSupply = xpoktProxy.totalSupply();

        vm.prank(wormholeRelayer);
        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(wormholeBridgeAdapterProxy)
        );
        emit BridgedIn(chainId, to, amount);
        wormholeBridgeAdapterProxy.receiveWormholeMessages{value: 0}(
            abi.encode(to, amount),
            new bytes[](0),
            address(wormholeBridgeAdapterProxy).toBytes(),
            chainId,
            nonce
        );

        assertEq(
            xpoktProxy.balanceOf(to) - startingBalance,
            amount,
            "incorrect amount received"
        );
        assertEq(
            xpoktProxy.totalSupply() - startingTotalSupply,
            amount,
            "incorrect total supply increase"
        );
        assertTrue(
            wormholeBridgeAdapterProxy.processedNonces(nonce),
            "nonce not used"
        );
    }

    /// bridge in, test not enough rate limit
    function testBridgeInFailsRateLimitExhausted(bytes32 nonce) public {
        amount = xpoktProxy.buffer(address(wormholeBridgeAdapterProxy));
        unchecked {
            testReceiveWormholeMessageSucceeds(bytes32(uint256(nonce) + 1));
        }
        amount = 1;

        vm.prank(wormholeRelayer);
        vm.expectRevert("RateLimited: rate limit hit");
        wormholeBridgeAdapterProxy.receiveWormholeMessages{value: 0}(
            abi.encode(to, amount),
            new bytes[](0),
            address(wormholeBridgeAdapterProxy).toBytes(),
            chainId,
            nonce
        );
    }

    /// bridge out tests:

    /// incorrect cost
    function testBridgeOutFailsIncorrectCost() public {
        vm.deal(address(this), 1);
        vm.expectRevert("WormholeBridge: cost not equal to quote");
        wormholeBridgeAdapterProxy.bridge{value: 1}(chainId, amount, to);
    }

    /// incorrect target chain
    function testBridgeOutFailsIncorrectTargetChain() public {
        vm.expectRevert("WormholeBridge: invalid target chain");
        wormholeBridgeAdapterProxy.bridge{value: 0}(
            chainId + 1,
            /// invalid chain id
            amount,
            to
        );
    }

    /// not enough approvals
    function testBridgeOutFailsNoApproval() public {
        vm.expectRevert("ERC20: insufficient allowance");
        wormholeBridgeAdapterProxy.bridge{value: 0}(chainId, amount, to);
    }

    /// not enough balance
    function testBridgeOutFailsNotEnoughBalance() public {
        deal(address(xpoktProxy), address(this), amount - 1);
        xpoktProxy.approve(address(wormholeBridgeAdapterProxy), amount);

        vm.expectRevert("ERC20: burn amount exceeds balance");
        wormholeBridgeAdapterProxy.bridge{value: 0}(chainId, amount, to);
    }

    /// not enough rate limit
    function testBridgeOutFailsNotEnoughBuffer() public {
        amount = externalChainBufferCap / 2;
        to = address(this);

        testReceiveWormholeMessageSucceeds(bytes32(uint256(1)));

        amount = externalChainBufferCap;
        xpoktProxy.approve(address(wormholeBridgeAdapterProxy), amount);

        vm.expectRevert("RateLimited: buffer cap overflow");
        wormholeBridgeAdapterProxy.bridge{value: 0}(chainId, amount + 1, to);
    }

    function testBridgeOutSucceeds() public {
        amount = externalChainBufferCap / 2;
        to = address(this);

        testReceiveWormholeMessageSucceeds(bytes32(uint256(1)));

        amount = externalChainBufferCap;

        _lockboxCanMintTo(address(this), uint112(amount));
        xpoktProxy.approve(address(wormholeBridgeAdapterProxy), amount);

        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(wormholeBridgeAdapterProxy)
        );
        emit TokensSent(chainId, to, amount);
        wormholeBridgeAdapterProxy.bridge{value: 0}(chainId, amount, to);
    }
}
