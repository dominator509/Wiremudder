//! Secrets scanner (SPEC-022-R02).
//!
//! Secrets are stored through the Secrets Vault, never logged, never
//! committed, never placed in AI context. This scanner deterministically
//! detects secret-shaped material in text so the repository gate can reject
//! it before commit. It fails closed: any hit is a finding.

/// One secret-shaped finding.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SecretFinding {
    pub pattern: String,
    pub sample: String,
    pub line: u64,
}

/// Deterministic scanner for secret-shaped material in text.
pub struct SecretsScanner;

impl SecretsScanner {
    /// Scan a single line; returns findings for any secret-shaped material.
    pub fn scan_line(line: &str, line_no: u64) -> Vec<SecretFinding> {
        let mut out = Vec::new();
        // Private key blocks.
        if line.contains("BEGIN RSA PRIVATE KEY")
            || line.contains("BEGIN OPENSSH PRIVATE KEY")
            || line.contains("BEGIN EC PRIVATE KEY")
            || line.contains("BEGIN PRIVATE KEY")
        {
            out.push(SecretFinding {
                pattern: "private-key-block".to_string(),
                sample: line.trim().chars().take(40).collect(),
                line: line_no,
            });
        }
        // AWS access key id shape.
        if let Some(pos) = find_pattern(line, "AKIA") {
            out.push(SecretFinding {
                pattern: "aws-access-key-id".to_string(),
                sample: line[pos.min(line.len())..]
                    .trim()
                    .chars()
                    .take(40)
                    .collect(),
                line: line_no,
            });
        }
        // OpenAI-style sk- keys (long enough to be real).
        if let Some(pos) = find_pattern(line, "sk-") {
            let rest: String = line[pos..].chars().take(64).collect();
            let alnum: usize = rest.chars().filter(|c| c.is_alphanumeric()).count();
            if alnum >= 24 {
                out.push(SecretFinding {
                    pattern: "openai-style-secret".to_string(),
                    sample: rest.trim().chars().take(40).collect(),
                    line: line_no,
                });
            }
        }
        out
    }

    /// Scan a whole payload; returns all findings.
    pub fn scan_payload(payload: &str) -> Vec<SecretFinding> {
        let mut out = Vec::new();
        for (i, line) in payload.lines().enumerate() {
            out.extend(Self::scan_line(line, (i + 1) as u64));
        }
        out
    }

    /// Redact secret-shaped material for safe display/logging.
    pub fn redact(payload: &str) -> String {
        let mut out = String::new();
        for line in payload.lines() {
            if Self::scan_line(line, 0).is_empty() {
                out.push_str(line);
            } else {
                out.push_str("<redacted>");
            }
            out.push('\n');
        }
        out
    }
}

fn find_pattern(line: &str, needle: &str) -> Option<usize> {
    line.find(needle)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_private_key_block() {
        let hits = SecretsScanner::scan_payload(
            "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA\n-----END RSA PRIVATE KEY-----",
        );
        assert!(!hits.is_empty());
        assert_eq!(hits[0].pattern, "private-key-block");
    }

    #[test]
    fn finds_aws_key() {
        let hits = SecretsScanner::scan_line("aws key AKIAIOSFODNN7EXAMPLE here", 1);
        assert!(hits.iter().any(|f| f.pattern == "aws-access-key-id"));
    }

    #[test]
    fn finds_openai_style_key() {
        let hits =
            SecretsScanner::scan_line("token=sk-proj-abcdefghijklmnopqrstuvwxyz0123456789", 1);
        assert!(hits.iter().any(|f| f.pattern == "openai-style-secret"));
    }

    #[test]
    fn clean_line_has_no_hits() {
        let hits = SecretsScanner::scan_line("the gate opens at dawn", 1);
        assert!(hits.is_empty());
    }

    #[test]
    fn redact_masks_only_findings() {
        let redacted = SecretsScanner::redact("ok line\nBEGIN PRIVATE KEY stuff\n");
        assert!(redacted.contains("ok line"));
        assert!(redacted.contains("<redacted>"));
    }
}
