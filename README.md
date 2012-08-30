satelite:  
  2 node cluster: 1 disc, 1 RAM

central:
  2 node cluster: 1 disc, 1 RAM

Exchanges on each cluster:
  `hub`: local topic exchange
  `fed-hub`: bi-directionally federated topic exchange


A bi-directionally federated exchange named fed-hub, meaning that if a
message is published to the fed-hub exchange on either cluster, it
will transit the network and be subscribable on the other.

Federated exchanges are configured with uni-directional links, so it
is possible to have a federated hub that only sends data in one
direction.

