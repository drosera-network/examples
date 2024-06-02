# Analyzing the Olympus Dao Attack: Detecting TVL Depletion Using a Drosera Trap

## Introduction

In this post, we discuss the olympus DAO attack where the BondFixedExpiryTeller contract was exploited to mint OHM tokens without locking up the required collateral. We will demonstrate how a Drosera Trap could have been used to detect the attack and prevent the loss of funds.

## The Attack

OlympusDAO exploited by WhiteHat for 315,328 $USD via logic issue of the Bond Protocol contracts

Details: https://de.fi/rekt-database/OlympusDAO

## Drosera Trap

This scenario can leverage a Trap that detects sudden TVL changes across pools and performs an emergency pause function to prevent further damage.

## Results

---------- Start from Block 15794363 ----------
DROSERA Collected Data From Block 15794363
Bond Contract OHM Balance: 30437.077948152
Attacker OHM Balance: 0.000000000
---------- Warp to Block 15794373 ----------
Attacker performs exploit
Bond Contract OHM Balance after first hack: 15218.538974076
Attacker OHM Balance after first hack: 15218.538974076
DROSERA Collected Data From Block 15794373
DROSERA performs trap logic on 15794363 and 15794373
DROSERA identified that state is invalid and emergency response is required
---------- Mine Next Block 15794374 ----------
Attacker attempts to perform exploit again
Attacker transaction reverts with BondFixedExpiryTeller: contract is paused
Bond Contract OHM Balance after second hack attempt: 15218.538974076
Attacker OHM Balance after second hack attempt: 15218.538974076
Attack mitigated successfully

## Conclusion

The Olympus DAO attack underscores the importance of having mechanisms in place to detect and respond to such incidents. The Trap itself is about 50 lines of code to just show this as an example, a much more extensive trap could be written with more complex mechanisms to catch other cases.
