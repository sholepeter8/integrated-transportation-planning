# Integrated Transportation Planning

A blockchain-based smart contract system for coordinating multi-modal transportation networks and enabling regional collaboration through decentralized governance.

## Overview

This project implements two core smart contracts that work together to create a comprehensive transportation planning ecosystem:

- **Transportation Coordination Contract**: Manages multi-modal transportation systems, route optimization, and resource allocation
- **Regional Governance Contract**: Facilitates regional collaboration through decentralized voting and policy management

## Architecture

### Transportation Coordination Contract
- **Route Management**: Create, update, and optimize transportation routes across different modes (bus, train, bike-share, walking)
- **Vehicle Assignment**: Dynamically assign vehicles to routes based on demand and availability
- **Resource Allocation**: Optimize resource distribution across the transportation network
- **Performance Metrics**: Track and calculate optimization scores for routes and overall system efficiency

### Regional Governance Contract
- **Decentralized Voting**: Regional stakeholders can propose and vote on transportation policies
- **Policy Management**: Activate, update, and track transportation policies across regions
- **Stakeholder Management**: Register and manage regional transportation authorities and planning organizations
- **Democratic Decision Making**: Ensure transparent and democratic decision-making processes

## Key Features

### Multi-Modal Coordination
- Support for buses, trains, bike-sharing, and pedestrian networks
- Intelligent route optimization algorithms
- Real-time resource allocation
- Performance tracking and analytics

### Regional Collaboration
- Cross-regional policy coordination
- Stakeholder voting mechanisms
- Policy lifecycle management
- Transparent governance processes

### Optimization Capabilities
- Route efficiency scoring
- Resource utilization optimization
- Demand-based planning
- Performance analytics

## Smart Contract Components

### Data Structures
- Route information and metadata
- Vehicle assignments and availability
- Policy proposals and voting records
- Regional stakeholder registrations

### Public Functions
- Route creation and management
- Vehicle assignment operations
- Policy proposal and voting
- Resource allocation optimization

### Read-Only Functions
- Route status queries
- Performance metric retrieval
- Policy status checking
- Voting result analysis

## Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity smart contract development tool
- [Node.js](https://nodejs.org/) (v16+)
- Git

### Installation
```bash
# Clone the repository
git clone https://github.com/sholepeter8/integrated-transportation-planning.git
cd integrated-transportation-planning

# Install dependencies
npm install

# Check contracts
clarinet check
```

### Running Tests
```bash
# Run contract tests
clarinet test

# Run specific test file
clarinet test tests/transportation-coordination_test.ts
```

### Contract Validation
```bash
# Check all contracts for syntax and semantic errors
clarinet check

# Generate contract documentation
clarinet docs
```

## Usage Examples

### Creating a Transportation Route
Routes can be created with multiple transportation modes, capacity specifications, and optimization parameters.

### Regional Policy Management
Regional authorities can propose policies, facilitate voting, and implement approved transportation initiatives.

### Resource Optimization
The system automatically calculates optimization scores and suggests resource allocation improvements.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Contract Specifications

### Transportation Coordination Contract
- Manages multi-modal route planning
- Implements resource allocation algorithms
- Provides optimization scoring mechanisms
- Tracks performance metrics

### Regional Governance Contract  
- Facilitates stakeholder registration
- Implements voting mechanisms
- Manages policy lifecycle
- Ensures transparent governance

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions and support, please open an issue in the GitHub repository.

## Roadmap

- [ ] Advanced route optimization algorithms
- [ ] Integration with real-time transportation data
- [ ] Mobile application interface
- [ ] Cross-chain interoperability
- [ ] Enhanced analytics dashboard
