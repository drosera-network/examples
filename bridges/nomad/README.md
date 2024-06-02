# Analyzing the Nomad Bridge Attack: Detecting TVL Depletion Using a Drosera Trap

## Introduction

In this post, we will demonstrate how a Drosera Trap can be used to detect an incident and mitigate damage with respect to the Nomad Bridge attack.

## The Attack

The Nomad bridge was exploited for aprox. $190 million by what has to be declared as Web3`s first "crowd-looting" event.

Details: https://de.fi/rekt-database/Nomad

## Drosera Trap

To mitigate damage from such attacks, we propose that a Trap could detect sudden TVL drains across pools and perform an emergency pause function to prevent further damage.

This Trap looks at the BTC pool and detects if a 30% TVL drain occurrs in a single block. If so, the Trap will pause the protocol and prevent further damage.

## Results

The Drosera Trap was able to detect the TVL drain and pause the protocol, preventing further damage.

In this test, Drosera saved $42,465,099.89 in WBTC from being siphoned off by the attacker. It would have saved additional funds from being siphoned aswell.

Nomad Exploit Mechanism: Attackers can copy the original user's transaction calldata and replacing the receive address with a personal one.

---------- Start from Block 15259100 ----------

Bridge WBTC Balance: 1028.25072399
DROSERA Collected Data From Block 15259100

---------- Warp to Block 15259101 ----------

Attackers perform multiple exploits
Bridge WBTC Balance: 628.25072399
DROSERA Collected Data From Block 15259101
DROSERA performs trap logic on 15259100 and 15259101
DROSERA identified that state is invalid and emergency response is required
DROSERA submits claim that state is invalid

---------- Mine Next Block 15259102 ----------

An attacker attempts to perform exploit again
Attacker transaction reverts with NomadReplica: contract is paused
Bridge WBTC Balance: 628.25072399
Attack mitigated successfully
Drosera saved $42,465,099.89 in WBTC from being siphoned

## Conclusion

The Nomad attack highlights the importance of having mechanisms in place to detect and respond to such incidents. By using a Drosera Trap, protocols can proactively monitor for abnormal behavior and take action to prevent further damage. This incident demonstrates the effectiveness of the Drosera Trap in protecting against TVL depletion attacks and safeguarding user funds.
