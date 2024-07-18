# Decentralized Crowdfunding Platform

## Overview

Welcome to the Decentralized Crowdfunding Platform project! This platform aims to revolutionize crowdfunding by leveraging blockchain technology to provide transparency, security, and global accessibility to fundraising campaigns.

## Project Structure

The project is structured into three main components:

1. **Decentralized Backend**: Implemented using Solidity smart contracts on Sepolia Testnet.
2. **Centralized Backend**: Handles metadata storage and event logging.
3. **Frontend**: Provides a user-friendly interface for campaign creation, donation processing, and campaign management.

## Decentralized Backend

### Smart Contracts

The decentralized backend is powered by Ethereum smart contracts, facilitating secure and transparent management of crowdfunding campaigns. Key contracts include:

- **Campaign.sol**: Manages individual crowdfunding campaigns, including donation handling, campaign states, and withdrawal functionalities.
- **CampaignFactory.sol**: Facilitates the creation and tracking of multiple crowdfunding campaigns. It manages the deployment of new Campaign instances and stores metadata about each campaign.

### Contract Interactions

- **CampaignFactory**: Responsible for deploying new Campaign contracts upon user request and maintaining a list of active campaigns.
- **Campaign**: Handles individual campaign logic, including donation processing, state management, and owner-specific functionalities.

### Testing

- Comprehensive unit tests ensure the correctness and functionality of each smart contract.
- Tests cover contract deployments, donation handling, state transitions, and edge cases.
