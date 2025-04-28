import { BigInt } from "@graphprotocol/graph-ts";
import { TopicCreated, VoteCast } from "../generated/EtherPoll/EtherPoll";
import { Topic, Vote } from "../generated/schema";

export function handleTopicCreated(event: TopicCreated): void {
  let id = event.params.topicId.toString();
  let topic = new Topic(id);
  topic.creator      = event.params.creator;
  topic.metadataCid  = event.params.metadataCid;
  topic.endTimestamp = event.params.endTimestamp;
  topic.yesCount     = BigInt.zero();
  topic.noCount      = BigInt.zero();
  topic.save();
}

export function handleVoteCast(event: VoteCast): void {
  // load the existing topic
  let tid = event.params.topicId.toString();
  let topic = Topic.load(tid);
  if (!topic) return;

  // update tallies
  if (event.params.support) {
    topic.yesCount = topic.yesCount.plus(BigInt.fromI32(1));
  } else {
    topic.noCount = topic.noCount.plus(BigInt.fromI32(1));
  }
  topic.save();

  // record the individual vote
  let voteId = event.transaction.hash.toHex() + "-" + event.logIndex.toString();
  let vote = new Vote(voteId);
  vote.topic   = topic.id;
  vote.voter   = event.params.voter;
  vote.support = event.params.support;
  vote.save();
}
