pragma solidity 0.8.19;

import "@forge-std/Test.sol";
import "@test/helper/BaseTest.t.sol";

contract xPOKTUnitTest is BaseTest {
    uint112 public MOCK_MAX_SUPPLY = 5 * 1e9;

    function setUp() public override {
        super.setUp();
        vm.prank(owner);
        xpoktProxy.transferOwnership(address(this));
        xpoktProxy.acceptOwnership();
    }

    function testSetup() public view {
        assertTrue(
            xpoktProxy.DOMAIN_SEPARATOR() != bytes32(0),
            "domain separator not set"
        );
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,

        ) = xpoktProxy.eip712Domain();
        assertEq(fields, hex"0f", "incorrect fields");
        assertEq(version, "1", "incorrect version");
        assertEq(chainId, block.chainid, "incorrect chain id");
        assertEq(salt, bytes32(0), "incorrect salt");
        assertEq(
            verifyingContract,
            address(xpoktProxy),
            "incorrect verifying contract"
        );
        assertEq(name, xpoktName, "incorrect name from eip712Domain()");
        assertEq(xpoktProxy.name(), xpoktName, "incorrect name");
        assertEq(xpoktProxy.symbol(), xpoktSymbol, "incorrect symbol");
        assertEq(xpoktProxy.totalSupply(), 0, "incorrect total supply");
        assertEq(xpoktProxy.owner(), address(this), "incorrect owner");
        assertEq(
            xpoktProxy.pendingOwner(),
            address(0),
            "incorrect pending owner"
        );

        assertEq(
            xpoktProxy.bufferCap(address(xerc20Lockbox)),
            type(uint112).max,
            "incorrect lockbox buffer cap"
        );
        assertEq(
            xpoktProxy.bufferCap(address(xerc20Lockbox)),
            xpoktProxy.mintingMaxLimitOf(address(xerc20Lockbox)),
            "incorrect lockbox mintingMaxLimitOf"
        );
        assertEq(
            xpoktProxy.bufferCap(address(xerc20Lockbox)),
            xpoktProxy.burningMaxLimitOf(address(xerc20Lockbox)),
            "incorrect lockbox burningMaxLimitOf"
        );
        assertEq(
            xpoktProxy.buffer(address(xerc20Lockbox)),
            type(uint112).max / 2,
            "incorrect lockbox buffer"
        );
        assertEq(
            xpoktProxy.buffer(address(xerc20Lockbox)),
            xpoktProxy.mintingCurrentLimitOf(address(xerc20Lockbox)),
            "incorrect lockbox mintingCurrentLimitOf"
        );
        assertEq(
            xpoktProxy.bufferCap(address(xerc20Lockbox)) -
                xpoktProxy.buffer(address(xerc20Lockbox)),
            xpoktProxy.burningCurrentLimitOf(address(xerc20Lockbox)),
            "incorrect lockbox burningCurrentLimitOf"
        );
        assertEq(
            xpoktProxy.rateLimitPerSecond(address(xerc20Lockbox)),
            0,
            "incorrect lockbox rate limit per second"
        );
        assertEq(
            xpoktProxy.maxPauseDuration(),
            xpoktProxy.MAX_PAUSE_DURATION(),
            "incorrect max pause duration"
        );

        /// PROXY OWNERSHIP

        /// proxy admin starts off as this address
        assertEq(
            proxyAdmin.getProxyAdmin(
                ITransparentUpgradeableProxy(address(xpoktProxy))
            ),
            address(proxyAdmin),
            "incorrect proxy admin"
        );

        /// PAUSING
        assertEq(
            xpoktProxy.pauseGuardian(),
            pauseGuardian,
            "incorrect pause guardian"
        );
        assertEq(xpoktProxy.pauseStartTime(), 0, "incorrect pause start time");
        assertEq(
            xpoktProxy.pauseDuration(),
            pauseDuration,
            "incorrect pause duration"
        );
        assertFalse(xpoktProxy.paused(), "incorrectly paused");
        assertFalse(xpoktProxy.pauseUsed(), "pause should not be used");
    }

    function testInitializationFailsPauseDurationGtMax() public {
        uint256 maxPauseDuration = xpoktProxy.MAX_PAUSE_DURATION();

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address,(uint112,uint128,address)[],uint128,address)",
            xpoktName,
            xpoktSymbol,
            owner,
            new MintLimits.RateLimitMidPointInfo[](0),
            /// empty array as it will fail anyway
            uint128(maxPauseDuration + 1),
            pauseGuardian
        );

        vm.expectRevert("xPOKT: pause duration too long");
        new TransparentUpgradeableProxy(
            address(xpoktLogic),
            address(proxyAdmin),
            initData
        );
    }

    function testPendingOwnerAccepts() public {
        xpoktProxy.transferOwnership(owner);

        vm.prank(owner);
        xpoktProxy.acceptOwnership();

        assertEq(xpoktProxy.owner(), owner, "incorrect owner");
        assertEq(
            xpoktProxy.pendingOwner(),
            address(0),
            "incorrect pending owner"
        );
    }

    function testInitializeLogicContractFails() public {
        vm.expectRevert("Initializable: contract is already initialized");
        xpoktLogic.initialize(
            xpoktName,
            xpoktSymbol,
            owner,
            new MintLimits.RateLimitMidPointInfo[](0),
            /// empty array as it will fail anyway
            pauseDuration,
            pauseGuardian
        );
    }

    function testTransferToTokenContractFails() public {
        testLockboxCanMint(1);

        vm.expectRevert("xERC20: cannot transfer to token contract");
        xpoktProxy.transfer(address(xpoktProxy), 1);
    }

    function testLockboxCanMint(uint112 mintAmount) public {
        mintAmount = uint112(_bound(mintAmount, 1, MOCK_MAX_SUPPLY));

        _lockboxCanMint(mintAmount);
    }

    function testLockboxCanMintTo(address to, uint112 mintAmount) public {
        /// cannot transfer to the proxy contract
        to = to == address(xpoktProxy)
            ? address(this)
            : address(103131212121482329);

        mintAmount = uint112(_bound(mintAmount, 1, MOCK_MAX_SUPPLY));

        _lockboxCanMintTo(to, mintAmount);
    }

    function testLockboxCanMintBurnTo(uint112 mintAmount) public {
        address to = address(this);

        mintAmount = uint112(_bound(mintAmount, 1, MOCK_MAX_SUPPLY));

        _lockboxCanMintTo(to, mintAmount);
        _lockboxCanBurnTo(to, mintAmount);
    }

    function testLockBoxCanBurn(uint112 burnAmount) public {
        burnAmount = uint112(_bound(burnAmount, 1, MOCK_MAX_SUPPLY));

        testLockboxCanMint(burnAmount);
        _lockboxCanBurn(burnAmount);
    }

    function testLockBoxCanMintBurn(uint112 mintAmount) public {
        mintAmount = uint112(_bound(mintAmount, 1, MOCK_MAX_SUPPLY));

        _lockboxCanMint(mintAmount);
        _lockboxCanBurn(mintAmount);

        assertEq(xpoktProxy.totalSupply(), 0, "incorrect total supply");
    }

    /// ACL

    function testGrantGuardianNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.grantPauseGuardian(address(0));
    }

    function testSetPauseDurationNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.setPauseDuration(0);
    }

    function testSetBufferCapNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.setBufferCap(address(0), 0);
    }

    function testSetRateLimitPerSecondNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.setRateLimitPerSecond(address(0), 0);
    }

    function testAddBridgeNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.addBridge(
            MintLimits.RateLimitMidPointInfo({
                bridge: address(0),
                rateLimitPerSecond: 0,
                bufferCap: 0
            })
        );
    }

    function testAddBridgesNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.addBridges(new MintLimits.RateLimitMidPointInfo[](0));
    }

    function testRemoveBridgeNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.removeBridge(address(0));
    }

    function testRemoveBridgesNonOwnerReverts() public {
        testPendingOwnerAccepts();
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.removeBridges(new address[](0));
    }

    function testGrantGuardianOwnerSucceeds(address newPauseGuardian) public {
        xpoktProxy.grantPauseGuardian(newPauseGuardian);
        assertEq(
            xpoktProxy.pauseGuardian(),
            newPauseGuardian,
            "incorrect pause guardian"
        );
    }

    function testGrantPauseGuardianWhilePausedFails() public {
        vm.prank(pauseGuardian);
        xpoktProxy.pause();
        assertTrue(xpoktProxy.paused(), "contract not paused");
        address newPauseGuardian = address(0xffffffff);

        vm.expectRevert("Pausable: paused");
        xpoktProxy.grantPauseGuardian(newPauseGuardian);
        assertTrue(xpoktProxy.paused(), "contract not paused");
    }

    function testUpdatePauseDurationSucceeds() public {
        uint128 newDuration = 8 days;
        xpoktProxy.setPauseDuration(newDuration);
        assertEq(
            xpoktProxy.pauseDuration(),
            newDuration,
            "incorrect pause duration"
        );
    }

    function testUpdatePauseDurationGtMaxPauseDurationFails() public {
        uint128 newDuration = uint128(xpoktProxy.MAX_PAUSE_DURATION() + 1);
        vm.expectRevert("xPOKT: pause duration too long");

        xpoktProxy.setPauseDuration(newDuration);
    }

    function testSetBufferCapOwnerSucceeds(uint112 bufferCap) public {
        bufferCap = uint112(
            _bound(
                bufferCap,
                xpoktProxy.MIN_BUFFER_CAP() + 1,
                type(uint112).max
            )
        );

        xpoktProxy.setBufferCap(address(xerc20Lockbox), bufferCap);
        assertEq(
            xpoktProxy.bufferCap(address(xerc20Lockbox)),
            bufferCap,
            "incorrect buffer cap"
        );
    }

    function testSetBufferCapZeroFails() public {
        uint112 bufferCap = 0;

        vm.expectRevert("MintLimits: bufferCap cannot be 0");
        xpoktProxy.setBufferCap(address(xerc20Lockbox), bufferCap);
    }

    function testSetRateLimitPerSecondOwnerSucceeds(
        uint128 newRateLimitPerSecond
    ) public {
        newRateLimitPerSecond = uint128(
            _bound(
                newRateLimitPerSecond,
                1,
                xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
            )
        );
        xpoktProxy.setRateLimitPerSecond(
            address(xerc20Lockbox),
            newRateLimitPerSecond
        );

        assertEq(
            xpoktProxy.rateLimitPerSecond(address(xerc20Lockbox)),
            newRateLimitPerSecond,
            "incorrect rate limit per second"
        );
    }

    /// add a new bridge and rate limit
    function testAddNewBridgeOwnerSucceeds(
        address bridge,
        uint128 newRateLimitPerSecond,
        uint112 newBufferCap
    ) public {
        xpoktProxy.removeBridge(address(xerc20Lockbox));

        if (xpoktProxy.buffer(bridge) != 0) {
            xpoktProxy.removeBridge(bridge);
        }

        /// bound input so bridge is not zero address
        bridge = address(
            uint160(_bound(uint256(uint160(bridge)), 1, type(uint160).max))
        );

        newRateLimitPerSecond = uint128(
            _bound(
                newRateLimitPerSecond,
                1,
                xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
            )
        );
        newBufferCap = uint112(
            _bound(
                newBufferCap,
                xpoktProxy.MIN_BUFFER_CAP() + 1,
                type(uint112).max
            )
        );

        MintLimits.RateLimitMidPointInfo memory newBridge = MintLimits
            .RateLimitMidPointInfo({
                bridge: bridge,
                bufferCap: newBufferCap,
                rateLimitPerSecond: newRateLimitPerSecond
            });

        xpoktProxy.addBridge(newBridge);

        assertEq(
            xpoktProxy.rateLimitPerSecond(bridge),
            newRateLimitPerSecond,
            "incorrect rate limit per second"
        );

        assertEq(
            xpoktProxy.bufferCap(bridge),
            newBufferCap,
            "incorrect buffer cap"
        );
    }

    /// add a new bridge and rate limit
    function testAddNewBridgesOwnerSucceeds(
        address bridge,
        uint128 newRateLimitPerSecond,
        uint112 newBufferCap
    ) public {
        xpoktProxy.removeBridge(address(xerc20Lockbox));
        xpoktProxy.removeBridge(address(wormholeBridgeAdapterProxy));

        bridge = address(
            uint160(_bound(uint256(uint160(bridge)), 1, type(uint160).max))
        );
        newRateLimitPerSecond = uint128(
            _bound(
                newRateLimitPerSecond,
                1,
                xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
            )
        );
        newBufferCap = uint112(
            _bound(
                newBufferCap,
                xpoktProxy.MIN_BUFFER_CAP() + 1,
                type(uint112).max
            )
        );

        MintLimits.RateLimitMidPointInfo[]
            memory newBridge = new MintLimits.RateLimitMidPointInfo[](1);

        newBridge[0].bridge = bridge;
        newBridge[0].bufferCap = newBufferCap;
        newBridge[0].rateLimitPerSecond = newRateLimitPerSecond;

        xpoktProxy.addBridges(newBridge);

        assertEq(
            xpoktProxy.rateLimitPerSecond(bridge),
            newRateLimitPerSecond,
            "incorrect rate limit per second"
        );

        assertEq(
            xpoktProxy.bufferCap(bridge),
            newBufferCap,
            "incorrect buffer cap"
        );
    }

    function testAddNewBridgeWithExistingLimitFails() public {
        address newBridge = address(0x1111777777);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = 20_000_000 * 1e6;

        testAddNewBridgeOwnerSucceeds(newBridge, rateLimitPerSecond, bufferCap);

        MintLimits.RateLimitMidPointInfo memory bridge = MintLimits
            .RateLimitMidPointInfo({
                bridge: newBridge,
                bufferCap: bufferCap,
                rateLimitPerSecond: rateLimitPerSecond
            });

        vm.expectRevert("MintLimits: rate limit already exists");
        xpoktProxy.addBridge(bridge);
    }

    function testAddNewBridgeWithBufferBelowMinFails() public {
        address newBridge = address(0x1111777777);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = xpoktProxy.MIN_BUFFER_CAP();

        MintLimits.RateLimitMidPointInfo memory bridge = MintLimits
            .RateLimitMidPointInfo({
                bridge: newBridge,
                bufferCap: bufferCap,
                rateLimitPerSecond: rateLimitPerSecond
            });

        vm.expectRevert("MintLimits: buffer cap below min");
        xpoktProxy.addBridge(bridge);
    }

    function testSetBridgeBufferBelowMinFails() public {
        address newBridge = address(0x1111777777);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = xpoktProxy.MIN_BUFFER_CAP();
        testAddNewBridgeOwnerSucceeds(
            newBridge,
            rateLimitPerSecond,
            bufferCap + 1
        );

        vm.expectRevert("MintLimits: buffer cap below min");
        xpoktProxy.setBufferCap(newBridge, bufferCap);
    }

    function testAddNewBridgeOverMaxRateLimitPerSecondFails() public {
        address newBridge = address(0x1111777777);
        uint112 bufferCap = 20_000_000 * 1e6;

        MintLimits.RateLimitMidPointInfo memory bridge = MintLimits
            .RateLimitMidPointInfo({
                bridge: newBridge,
                bufferCap: bufferCap,
                rateLimitPerSecond: uint128(
                    xpoktProxy.MAX_RATE_LIMIT_PER_SECOND() + 1
                )
            });

        vm.expectRevert("MintLimits: rateLimitPerSecond too high");
        xpoktProxy.addBridge(bridge);
    }

    function testSetExistingBridgeOverMaxRateLimitPerSecondFails() public {
        uint128 maxRateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );

        vm.expectRevert("MintLimits: rateLimitPerSecond too high");
        xpoktProxy.setRateLimitPerSecond(
            address(xerc20Lockbox),
            maxRateLimitPerSecond + 1
        );
    }

    function testAddNewBridgeInvalidAddressFails() public {
        address newBridge = address(0);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = 20_000_000 * 1e6;

        MintLimits.RateLimitMidPointInfo memory bridge = MintLimits
            .RateLimitMidPointInfo({
                bridge: newBridge,
                bufferCap: bufferCap,
                rateLimitPerSecond: rateLimitPerSecond
            });

        vm.expectRevert("MintLimits: invalid bridge address");
        xpoktProxy.addBridge(bridge);
    }

    function testAddNewBridgeBufferCapZeroFails() public {
        uint112 bufferCap = 0;
        address newBridge = address(100);
        uint128 rateLimitPerSecond = 1_000 * 1e6;

        MintLimits.RateLimitMidPointInfo memory bridge = MintLimits
            .RateLimitMidPointInfo({
                bridge: newBridge,
                bufferCap: bufferCap,
                rateLimitPerSecond: rateLimitPerSecond
            });

        vm.expectRevert("MintLimits: buffer cap below min");
        xpoktProxy.addBridge(bridge);
    }

    function testSetRateLimitOnNonExistentBridgeFails(
        uint128 newRateLimitPerSecond
    ) public {
        newRateLimitPerSecond = uint128(
            _bound(
                newRateLimitPerSecond,
                1,
                xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
            )
        );

        vm.expectRevert("MintLimits: non-existent rate limit");
        xpoktProxy.setRateLimitPerSecond(address(0), newRateLimitPerSecond);
    }

    function testSetBufferCapOnNonExistentBridgeFails(
        uint112 newBufferCap
    ) public {
        newBufferCap = uint112(_bound(newBufferCap, 1, type(uint112).max));
        vm.expectRevert("MintLimits: non-existent rate limit");
        xpoktProxy.setBufferCap(address(0), newBufferCap);
    }

    function testRemoveBridgeOwnerSucceeds() public {
        xpoktProxy.removeBridge(address(xerc20Lockbox));

        assertEq(
            xpoktProxy.bufferCap(address(xerc20Lockbox)),
            0,
            "incorrect buffer cap"
        );
        assertEq(
            xpoktProxy.rateLimitPerSecond(address(xerc20Lockbox)),
            0,
            "incorrect rate limit per second"
        );
        assertEq(
            xpoktProxy.buffer(address(xerc20Lockbox)),
            0,
            "incorrect buffer"
        );
    }

    function testCannotRemoveNonExistentBridge() public {
        vm.expectRevert("MintLimits: cannot remove non-existent rate limit");
        xpoktProxy.removeBridge(address(0));
    }

    function testCannotRemoveNonExistentBridges() public {
        vm.expectRevert("MintLimits: cannot remove non-existent rate limit");
        xpoktProxy.removeBridges(new address[](2));
    }

    function testRemoveBridgesOwnerSucceeds() public {
        /// todo add more bridges here
        address[] memory bridges = new address[](1);
        bridges[0] = address(10000);

        testAddNewBridgeOwnerSucceeds(
            bridges[0],
            10_000e18,
            xpoktProxy.minBufferCap() + 1
        );

        xpoktProxy.removeBridges(bridges);

        for (uint256 i = 0; i < bridges.length; i++) {
            assertEq(
                xpoktProxy.bufferCap(bridges[i]),
                0,
                "incorrect buffer cap"
            );
            assertEq(
                xpoktProxy.rateLimitPerSecond(bridges[i]),
                0,
                "incorrect rate limit per second"
            );
            assertEq(xpoktProxy.buffer(bridges[i]), 0, "incorrect buffer");
        }
    }

    function testDepleteBufferBridgeSucceeds() public {
        address bridge = address(0xeeeee);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = 20_000_000 * 1e6;

        testAddNewBridgeOwnerSucceeds(bridge, rateLimitPerSecond, bufferCap);

        uint256 amount = 100_000 * 1e6;

        vm.prank(bridge);
        xpoktProxy.mint(address(this), amount);

        xpoktProxy.approve(bridge, amount);

        uint256 buffer = xpoktProxy.buffer(bridge);
        uint256 userStartingBalance = xpoktProxy.balanceOf(address(this));
        uint256 startingTotalSupply = xpoktProxy.totalSupply();

        vm.prank(bridge);
        xpoktProxy.burn(address(this), amount);

        assertEq(
            xpoktProxy.buffer(bridge),
            buffer + amount,
            "incorrect buffer amount"
        );
        assertEq(
            xpoktProxy.balanceOf(address(this)),
            userStartingBalance - amount,
            "incorrect user balance"
        );
        assertEq(
            xpoktProxy.allowance(address(this), bridge),
            0,
            "incorrect allowance"
        );
        assertEq(
            startingTotalSupply - xpoktProxy.totalSupply(),
            amount,
            "incorrect total supply"
        );
    }

    function testReplenishBufferBridgeSucceeds() public {
        address bridge = address(0xeeeee);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = 20_000_000 * 1e6;

        testAddNewBridgeOwnerSucceeds(bridge, rateLimitPerSecond, bufferCap);

        uint256 amount = 100_000 * 1e6;

        uint256 buffer = xpoktProxy.buffer(bridge);
        uint256 userStartingBalance = xpoktProxy.balanceOf(address(this));
        uint256 startingTotalSupply = xpoktProxy.totalSupply();

        vm.prank(bridge);
        xpoktProxy.mint(address(this), amount);

        assertEq(
            xpoktProxy.buffer(bridge),
            buffer - amount,
            "incorrect buffer amount"
        );
        assertEq(
            xpoktProxy.totalSupply() - startingTotalSupply,
            amount,
            "incorrect total supply"
        );
        assertEq(
            xpoktProxy.balanceOf(address(this)) - userStartingBalance,
            amount,
            "incorrect user balance"
        );
    }

    function testReplenishBufferBridgeByZeroFails() public {
        address bridge = address(0xeeeee);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = 20_000_000 * 1e6;

        testAddNewBridgeOwnerSucceeds(bridge, rateLimitPerSecond, bufferCap);

        vm.prank(bridge);
        vm.expectRevert("MintLimits: deplete amount cannot be 0");
        xpoktProxy.mint(address(this), 0);
    }

    function testDepleteBufferBridgeByZeroFails() public {
        address bridge = address(0xeeeee);
        uint128 rateLimitPerSecond = uint128(
            xpoktProxy.MAX_RATE_LIMIT_PER_SECOND()
        );
        uint112 bufferCap = 20_000_000 * 1e6;

        testAddNewBridgeOwnerSucceeds(bridge, rateLimitPerSecond, bufferCap);

        vm.prank(bridge);
        vm.expectRevert("MintLimits: replenish amount cannot be 0");
        xpoktProxy.burn(address(this), 0);
    }

    function testDepleteBufferNonBridgeByOneFails() public {
        address bridge = address(0xeeeee);

        vm.prank(bridge);
        vm.expectRevert("RateLimited: buffer cap overflow");
        xpoktProxy.burn(address(this), 1);
    }

    function testReplenishBufferNonBridgeByOneFails() public {
        address bridge = address(0xeeeee);

        vm.prank(bridge);
        vm.expectRevert("RateLimited: rate limit hit");
        xpoktProxy.mint(address(this), 1);
    }

    function testMintFailsWhenPaused() public {
        vm.prank(pauseGuardian);
        xpoktProxy.pause();
        assertTrue(xpoktProxy.paused());

        vm.prank(address(xerc20Lockbox));
        vm.expectRevert("Pausable: paused");
        xpoktProxy.mint(address(xerc20Lockbox), 1);
    }

    function testOwnerCanUnpause() public {
        vm.prank(pauseGuardian);
        xpoktProxy.pause();
        assertTrue(xpoktProxy.paused());

        xpoktProxy.ownerUnpause();
        assertFalse(xpoktProxy.paused(), "contract is unpaused");
    }

    function testOwnerUnpauseFailsNotPaused() public {
        vm.expectRevert("Pausable: not paused");
        xpoktProxy.ownerUnpause();
    }

    function testNonOwnerUnpauseFails() public {
        vm.prank(address(10000000000));
        vm.expectRevert("Ownable: caller is not the owner");
        xpoktProxy.ownerUnpause();
    }

    function testMintSucceedsAfterPauseDuration() public {
        testMintFailsWhenPaused();

        vm.warp(xpoktProxy.pauseDuration() + block.timestamp + 1);

        assertFalse(xpoktProxy.paused());
        testLockboxCanMint(0);
        /// let function choose amount to mint at random
    }

    function testBurnFailsWhenPaused() public {
        vm.prank(pauseGuardian);
        xpoktProxy.pause();
        assertTrue(xpoktProxy.paused());

        vm.prank(address(xerc20Lockbox));
        vm.expectRevert("Pausable: paused");
        xpoktProxy.burn(address(xerc20Lockbox), 1);
    }

    function tesBurnSucceedsAfterPauseDuration() public {
        testBurnFailsWhenPaused();

        vm.warp(xpoktProxy.pauseDuration() + block.timestamp + 1);

        assertFalse(xpoktProxy.paused());

        /// mint, then burn after pause is up
        testLockBoxCanBurn(0);
        /// let function choose amount to burn at random
    }

    function testIncreaseAllowance(uint256 amount) public {
        uint256 startingAllowance = xpoktProxy.allowance(
            address(this),
            address(xerc20Lockbox)
        );

        xpoktProxy.increaseAllowance(address(xerc20Lockbox), amount);

        assertEq(
            xpoktProxy.allowance(address(this), address(xerc20Lockbox)),
            startingAllowance + amount,
            "incorrect allowance"
        );
    }

    function testDecreaseAllowance(uint256 amount) public {
        testIncreaseAllowance(amount);

        amount /= 2;

        uint256 startingAllowance = xpoktProxy.allowance(
            address(this),
            address(xerc20Lockbox)
        );

        xpoktProxy.decreaseAllowance(address(xerc20Lockbox), amount);

        assertEq(
            xpoktProxy.allowance(address(this), address(xerc20Lockbox)),
            startingAllowance - amount,
            "incorrect allowance"
        );
    }

    function testPermit(uint256 amount) public {
        address spender = address(xerc20Lockbox);
        uint256 deadline = 5000000000; // timestamp far in the future
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);

        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: amount,
            nonce: 0,
            deadline: deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        xpoktProxy.permit(owner, spender, amount, deadline, v, r, s);

        assertEq(
            xpoktProxy.allowance(owner, spender),
            amount,
            "incorrect allowance"
        );
        assertEq(xpoktProxy.nonces(owner), 1, "incorrect nonce");
    }
}
