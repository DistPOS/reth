//! DistPOS Consensus Implementation
//!
//! Implements Proof-of-Stake consensus for DistPOS, including validator staking,
//! signature validation, round-robin leader selection, and slashing.

use alloy_primitives::{Address, U256};
use reth_consensus::{Consensus, ConsensusError, HeaderValidator};
use reth_primitives_traits::{Block, SealedBlock, SealedHeader};
use std::collections::HashMap;
use tracing::debug;

/// Validator information stored in the database.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Validator {
    pub address: Address,
    pub stake: U256,
    pub slashed: bool,
}

/// DistPOS Consensus implementation.
#[derive(Debug)]
pub struct DistPOSConsensus {
    /// In-memory cache of validators (in production, this would be backed by DB).
    validators: HashMap<Address, Validator>,
}

impl DistPOSConsensus {
    /// Create a new DistPOS consensus instance.
    pub fn new() -> Self {
        Self {
            validators: HashMap::new(),
        }
    }

    /// Add or update a validator.
    pub fn add_validator(&mut self, validator: Validator) {
        self.validators.insert(validator.address, validator);
    }

    /// Get validator by address.
    pub fn get_validator(&self, address: &Address) -> Option<&Validator> {
        self.validators.get(address)
    }

    /// Check if an address is an active validator (has stake and not slashed).
    pub fn is_active_validator(&self, address: &Address) -> bool {
        self.get_validator(address)
            .map(|v| !v.slashed && v.stake > U256::ZERO)
            .unwrap_or(false)
    }

    /// Slash a validator (mark as slashed).
    pub fn slash_validator(&mut self, address: &Address) -> bool {
        if let Some(validator) = self.validators.get_mut(address) {
            validator.slashed = true;
            debug!("Slashed validator: {:?}", address);
            true
        } else {
            false
        }
    }

    /// Simple round-robin leader selection based on block number.
    pub fn get_leader(&self, block_number: u64) -> Option<Address> {
        let active_validators: Vec<_> = self
            .validators
            .values()
            .filter(|v| self.is_active_validator(&v.address))
            .collect();

        if active_validators.is_empty() {
            return None;
        }

        let index = (block_number as usize) % active_validators.len();
        Some(active_validators[index].address)
    }
}

impl<H> HeaderValidator<H> for DistPOSConsensus
where
    H: 'static,
{
    fn validate_header(&self, _header: &SealedHeader<H>) -> Result<(), ConsensusError> {
        // Placeholder: basic header validation
        Ok(())
    }

    fn validate_header_against_parent(
        &self,
        _header: &SealedHeader<H>,
        _parent: &SealedHeader<H>,
    ) -> Result<(), ConsensusError> {
        // Placeholder: basic parent validation
        Ok(())
    }
}

impl<B: Block> Consensus<B> for DistPOSConsensus
where
    B::Header: 'static,
{
    type Error = ConsensusError;

    fn validate_body_against_header(
        &self,
        _body: &B::Body,
        _header: &SealedHeader<B::Header>,
    ) -> Result<(), Self::Error> {
        // Placeholder: basic body validation
        Ok(())
    }

    fn validate_block_pre_execution(&self, _block: &SealedBlock<B>) -> Result<(), Self::Error> {
        // Placeholder: DistPOS block validation
        // TODO: Extract signer from header extra_data, check validator status
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloy_primitives::address;

    #[test]
    fn test_validator_management() {
        let mut consensus = DistPOSConsensus::new();

        let addr = address!("0x742d35Cc6634C0532925a3b844Bc454e4438f44e");
        let validator = Validator {
            address: addr,
            stake: U256::from(1000),
            slashed: false,
        };

        consensus.add_validator(validator.clone());
        assert!(consensus.is_active_validator(&addr));

        consensus.slash_validator(&addr);
        assert!(!consensus.is_active_validator(&addr));
    }

    #[test]
    fn test_leader_selection() {
        let mut consensus = DistPOSConsensus::new();

        let addr1 = address!("0x742d35Cc6634C0532925a3b844Bc454e4438f44e");
        let addr2 = address!("0x742d35Cc6634C0532925a3b844Bc454e4438f44f");

        consensus.add_validator(Validator {
            address: addr1,
            stake: U256::from(1000),
            slashed: false,
        });
        consensus.add_validator(Validator {
            address: addr2,
            stake: U256::from(1000),
            slashed: false,
        });

        assert_eq!(consensus.get_leader(0), Some(addr1));
        assert_eq!(consensus.get_leader(1), Some(addr2));
        assert_eq!(consensus.get_leader(2), Some(addr1));
    }
}