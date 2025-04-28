// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

error EmptyCID();
error DurationOutOfRange();
error TopicNotFound();
error VotingClosed();
error AlreadyVoted();

/// @title     EtherPoll
/// @notice    A simple on-chain polling contract storing metadata CIDs via IPFS.
contract EtherPoll {
  /// @notice Emitted when a new poll is created
  /// @param topicId     ID of the topic
  /// @param creator     Creator of the topic
  /// @param metadataCid CID of the metadata file on IPFS
  /// @param endTimestamp end date of the voting period
  event TopicCreated(
    uint256 indexed topicId,
    address indexed creator,
    string metadataCid,
    uint256 endTimestamp
  );

  /// @notice Emitted when a vote is cast
  /// @param topicId ID of the topic being voted on
  /// @param voter   Address that cast the vote
  /// @param support `true` for yes, `false` for no
  event VoteCast(uint256 indexed topicId, address indexed voter, bool support);

  /// @dev   Struct storing on-chain state for a topic
  struct Topic {
    address creator;
    string metadataCid;
    uint256 endTimestamp;
    uint256 yesVotes;
    uint256 noVotes;
  }

  /// @notice Mapping from topic ID → `Topic` data
  mapping(uint256 => Topic) public topics;

  /// @notice Mapping from topic ID → voter address → boolean indicating if the voter has voted
  mapping(uint256 => mapping(address => bool)) public hasVoted;

  /// @notice ID of the next topic to be created
  uint256 public nextTopicId;

  /// @notice  Create a new topic with metadata stored off-chain on IPFS
  /// @param   cid      The IPFS CID of a JSON file containing `title`, `description`, `links`, etc.
  /// @param   duration How long (in seconds) this topic should remain open (max. 90 days)
  /// @return  topicId  ID of the created topic
  function createTopic(string memory cid, uint256 duration) external returns (uint256 topicId) {
    if (bytes(cid).length == 0) revert EmptyCID();
    if (duration <= 0 || duration > 90 days) revert DurationOutOfRange();

    topicId = nextTopicId++;
    uint256 endDate = block.timestamp + duration;

    topics[topicId] = Topic({
      creator: msg.sender,
      metadataCid: cid,
      endTimestamp: endDate,
      yesVotes: 0,
      noVotes: 0
    });

    emit TopicCreated(topicId, msg.sender, cid, endDate);
  }

  /// @notice Cast a yes/no vote on an existing topic
  /// @param topicId ID of the topic
  /// @param support `true` for yes, `false` for no
  function voteOnTopic(uint256 topicId, bool support) external {
    Topic storage topic = topics[topicId];
    if (topic.creator == address(0)) revert TopicNotFound();
    if (topic.endTimestamp < block.timestamp) revert VotingClosed();
    if (hasVoted[topicId][msg.sender]) revert AlreadyVoted();

    hasVoted[topicId][msg.sender] = true;
    if (support) topic.yesVotes++;
    else topic.noVotes++;

    emit VoteCast(topicId, msg.sender, support);
  }

  /// @notice Returns yes/no tallies and the closing timestamp
  function getTopicInfo(
    uint256 topicId
  ) external view returns (uint256 yesVotes, uint256 noVotes, uint256 endTimestamp) {
    Topic storage t = topics[topicId];
    return (t.yesVotes, t.noVotes, t.endTimestamp);
  }

  /// @notice Whether a given address has voted on a topic
  function hasUserVoted(uint256 topicId, address user) external view returns (bool) {
    return hasVoted[topicId][user];
  }
}
