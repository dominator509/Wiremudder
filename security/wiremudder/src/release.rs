//! Release blocker (SPEC-028-R03).
//!
//! Known critical defects, security findings, P0/P1 regressions, data-loss
//! risks, secret leakage, signature failures, or emergency-stop failures
//! block release.

use serde::{Deserialize, Serialize};

/// A release-blocking finding.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BlockingFinding {
    pub category: String,
    pub detail: String,
}

/// The result of evaluating release-blocking conditions.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReleaseVerdict {
    pub blocked: bool,
    pub findings: Vec<BlockingFinding>,
}

/// Evaluates release-blocking conditions fail-closed.
pub struct ReleaseBlocker;

impl ReleaseBlocker {
    pub fn evaluate(findings: Vec<BlockingFinding>) -> ReleaseVerdict {
        ReleaseVerdict {
            blocked: !findings.is_empty(),
            findings,
        }
    }

    /// Convenience: any finding blocks.
    pub fn blocked(findings: &[BlockingFinding]) -> bool {
        !findings.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn no_findings_does_not_block() {
        let v = ReleaseBlocker::evaluate(vec![]);
        assert!(!v.blocked);
    }

    #[test]
    fn critical_security_finding_blocks() {
        let v = ReleaseBlocker::evaluate(vec![BlockingFinding {
            category: "security".to_string(),
            detail: "secret leaked in diagnostics".to_string(),
        }]);
        assert!(v.blocked);
    }

    #[test]
    fn signature_failure_blocks() {
        let f = BlockingFinding {
            category: "signature".to_string(),
            detail: "manifest signature invalid".to_string(),
        };
        assert!(ReleaseBlocker::blocked(&[f]));
    }
}
