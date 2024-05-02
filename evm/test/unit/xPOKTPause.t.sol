pragma solidity 0.8.19;

import "@forge-std/Test.sol";

import "@test/helper/BaseTest.t.sol";

contract xPOKTPauseUnitTest is BaseTest {
    function setUp() public override {
        super.setUp();

        vm.warp(block.timestamp + 1000000);
    }

    /// @notice ACL tests that ensure pause/unpause can only be called by the pause guardian
    function testPauseNonGuardianFails() public {
        vm.expectRevert("ConfigurablePauseGuardian: only pause guardian");
        xpoktProxy.pause();
    }

    function testUnpauseNonGuardianFails() public {
        testGuardianCanPause();

        vm.expectRevert("ConfigurablePauseGuardian: only pause guardian");
        xpoktProxy.unpause();
    }

    function testKickFailsWithZeroStartTime() public {
        vm.expectRevert(
            "ConfigurablePauseGuardian: did not pause, so cannot kick"
        );
        xpoktProxy.kickGuardian();
    }

    function testGuardianCanPause() public {
        assertFalse(xpoktProxy.paused(), "should start unpaused");

        vm.prank(pauseGuardian);
        xpoktProxy.pause();

        assertTrue(xpoktProxy.pauseUsed(), "pause should be used");
        assertTrue(xpoktProxy.paused(), "should be paused");
        assertEq(
            xpoktProxy.pauseStartTime(),
            block.timestamp,
            "pauseStartTime incorrect"
        );
    }

    function testGuardianCanUnpause() public {
        testGuardianCanPause();

        vm.prank(pauseGuardian);
        xpoktProxy.unpause();

        assertFalse(xpoktProxy.paused(), "should be unpaused");
        assertEq(xpoktProxy.pauseStartTime(), 0, "pauseStartTime incorrect");
        assertFalse(xpoktProxy.pauseUsed(), "pause should be used");
        assertEq(
            xpoktProxy.pauseGuardian(),
            address(0),
            "pause guardian incorrect"
        );
    }

    function testShouldUnpauseAutomaticallyAfterPauseDuration() public {
        testGuardianCanPause();

        vm.warp(pauseDuration + block.timestamp);
        assertTrue(xpoktProxy.paused(), "should still be paused");

        vm.warp(block.timestamp + 1);
        assertFalse(xpoktProxy.paused(), "should be unpaused");
    }

    function testPauseFailsPauseAlreadyUsed() public {
        testShouldUnpauseAutomaticallyAfterPauseDuration();

        vm.prank(pauseGuardian);
        vm.expectRevert("ConfigurablePauseGuardian: pause already used");
        xpoktProxy.pause();
    }

    function testCanKickGuardianAfterPauseUsed() public {
        testShouldUnpauseAutomaticallyAfterPauseDuration();

        xpoktProxy.kickGuardian();

        assertEq(
            xpoktProxy.pauseGuardian(),
            address(0),
            "incorrect pause guardian"
        );
        assertEq(xpoktProxy.pauseStartTime(), 0, "pauseStartTime incorrect");
        assertFalse(xpoktProxy.pauseUsed(), "incorrect pause used");
    }

    function testKickGuardianSucceedsAfterUnpause() public {
        testGuardianCanPause();

        vm.warp(pauseDuration + block.timestamp);
        assertTrue(xpoktProxy.paused(), "should still be paused");

        vm.prank(pauseGuardian);
        xpoktProxy.unpause();
        assertFalse(xpoktProxy.paused(), "should be unpaused");
        assertEq(xpoktProxy.pauseStartTime(), 0, "pauseStartTime incorrect");

        /// in this scenario, kickGuardian fails because the pause
        /// guardian is address(0), and the pauseStartTime is 0,
        /// this means the contract is unpaused, so
        vm.expectRevert(
            "ConfigurablePauseGuardian: did not pause, so cannot kick"
        );
        xpoktProxy.kickGuardian();
    }
}
