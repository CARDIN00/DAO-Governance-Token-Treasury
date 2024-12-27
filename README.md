# DAO-Governance-Token-Treasury
This project implements a decentralized autonomous organization (DAO) with a token-based governance system, allowing token holders to propose and vote on various actions. The system includes a Governance Token for voting and a Treasury Contract for managing funds, executing transfers, and handling proposals that require treasury allocations.

Key Features:
Governance Token Contract:

Token holders can propose, vote, and execute decisions regarding the DAO.
Voting requires a minimum quorum (e.g., 30% of token supply must vote).
Proposals can modify the DAO's behavior or allocate funds.
Proposals are executed only if they pass the vote and meet the quorum.
Treasury Contract:

Manages the DAO’s funds.
Allows funds to be deposited, withdrawn, or allocated based on governance decisions.
The DAO can execute actions on other contracts using the treasury’s funds through a governance mechanism.
Smart Contract Components:
1. Governance Token (ERC20):
Voting Mechanism: Token holders can vote on proposals.
Proposal Creation: Any token holder can create a proposal to perform actions such as fund allocations or contract calls.
Execution Delay: Proposals are executed after a predefined delay to ensure transparency.
Quorum Requirement: A percentage of the total supply must vote for the proposal to be valid.
2. Treasury Contract:
Fund Management: Allows the DAO to store and manage its funds.
Deposits: Allows anyone to deposit Ether into the treasury.
Withdrawals & Fund Allocation: Only authorized governance (DAO) can withdraw or allocate funds.
Action Execution: The DAO can execute specific contract calls to interact with other smart contracts or decentralized applications (dApps).
