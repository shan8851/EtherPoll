// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {EtherPoll, EmptyCID, DurationOutOfRange, TopicNotFound, VotingClosed, AlreadyVoted} from "../src/EtherPoll.sol";

contract EtherPollTest is Test {
  EtherPoll poll;
  address alice = address(0xABCD);
  address bob = address(0xBEEF);

  event TopicCreated(
    uint256 indexed topicId,
    address indexed creator,
    string metadataCid,
    uint256 endTimestamp
  );
  event VoteCast(uint256 indexed topicId, address indexed voter, bool support);

  function setUp() public {
    poll = new EtherPoll();
  }

  function test_CreateTopicEmitsEventAndReturnsId() public {
    // Expect the TopicCreated event with correct args
    vm.expectEmit(true, true, false, true);
    emit TopicCreated(0, address(this), "cid123", block.timestamp + 1 days);

    uint256 id = poll.createTopic("cid123", 1 days);
    assertEq(id, 0);
  }

  function testFuzz_CreateTopicDuration(uint256 d) public {
    vm.assume(d > 0 && d <= 90 days);
    uint256 id = poll.createTopic("cidABC", d);
    assertEq(id, 0);
    (, , uint256 endTs) = poll.getTopicInfo(id);
    assertEq(endTs, block.timestamp + d);
  }

  function testRevert_CreateTopicEmptyCID() public {
    vm.expectRevert(EmptyCID.selector);
    poll.createTopic("", 1 days);
  }

  function testRevert_CreateTopicDurationTooLong() public {
    vm.expectRevert(DurationOutOfRange.selector);
    poll.createTopic("cid", 91 days);
  }

  function test_VoteYesAndNoCounts() public {
    uint256 id = poll.createTopic("cidXYZ", 1 days);

    vm.prank(alice);
    poll.voteOnTopic(id, true);
    (uint256 yes, uint256 no, ) = poll.getTopicInfo(id);
    assertEq(yes, 1);
    assertEq(no, 0);

    vm.prank(bob);
    poll.voteOnTopic(id, false);
    (yes, no, ) = poll.getTopicInfo(id);
    assertEq(yes, 1);
    assertEq(no, 1);
  }

  function testRevert_VoteTwice() public {
    uint256 id = poll.createTopic("cidFoo", 1 days);

    vm.prank(alice);
    poll.voteOnTopic(id, true);

    vm.prank(alice);
    vm.expectRevert(AlreadyVoted.selector);
    poll.voteOnTopic(id, false);
  }

  function testRevert_VoteOnNonexistentTopic() public {
    vm.expectRevert(TopicNotFound.selector);
    poll.voteOnTopic(999, true);
  }

  function testRevert_VoteAfterExpiry() public {
    uint256 id = poll.createTopic("cidTime", 1 days);

    vm.warp(block.timestamp + 1 days + 1);
    vm.prank(bob);
    vm.expectRevert(VotingClosed.selector);
    poll.voteOnTopic(id, true);
  }
}
